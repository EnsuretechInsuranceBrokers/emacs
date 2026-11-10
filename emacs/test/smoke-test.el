;;; smoke-test.el --- Does the config still work? -*- lexical-binding: t; -*-

;;; Commentary:
;; Run with ./test/run.sh (or `make test').  Loaded after init.el, so every
;; test sees the real config.  Tests that need installed packages skip
;; themselves when the packages aren't there (e.g. offline).

;;; Code:

(require 'ert)

;; Features load on the first key press / first file (init-perf.el).
;; Tests never press a key, so trigger both now.
(my/first-file)
(my/first-input)

(defmacro my-test--with-file (name content &rest body)
  "Visit a fresh file NAME with CONTENT in a temp dir, run BODY there."
  (declare (indent 2))
  `(let* ((dir (make-temp-file "emacs-test-" t))
          (file (expand-file-name ,name dir)))
     (unwind-protect
         (progn
           (with-temp-file file (insert ,content))
           (with-current-buffer (find-file-noselect file)
             (unwind-protect (progn ,@body)
               (set-buffer-modified-p nil)
               (kill-buffer))))
       (delete-directory dir t))))

;;;; Startup
(ert-deftest my-test-modules-loaded ()
  (dolist (f '(init-package init-perf init-defaults init-ui init-completion
               init-navigation init-editing init-dev init-compile init-langs
               init-workflow init-git init-tools init-keys init-maint my-autocommit))
    (should (featurep f)))
  (dolist (f (when my/use-evil '(init-evil)))
    (should (featurep f))))

(ert-deftest my-test-gc-restored ()
  (run-hooks 'emacs-startup-hook)
  (should (= gc-cons-threshold my/gc-threshold)))

;;;; C / C++ mode choice
(ert-deftest my-test-c-small-file-uses-c-mode ()
  (my-test--with-file "a.c" "int main(void) { return 0; }\n"
    (should (memq major-mode '(c-mode c-ts-mode)))
    (should (eq (my/c-like-kind) 'c))))

(ert-deftest my-test-cpp-small-file-uses-c++-mode ()
  (my-test--with-file "a.cpp" "int main() {}\n"
    (should (memq major-mode '(c++-mode c++-ts-mode)))
    (should (eq (my/c-like-kind) 'c++))))

(ert-deftest my-test-c-big-file-uses-fast-c ()
  (my-test--with-file "big.h" (make-string (1+ my/c-big-file-size) ?x)
    (should (eq major-mode 'fast-c-mode))
    (should (eq (my/c-like-kind) 'c))))

(ert-deftest my-test-fast-c-always ()
  (let ((my/c-mode 'fast))
    (my-test--with-file "a.cpp" "int main() {}\n"
      (should (eq major-mode 'fast-c-mode))
      (should (eq (my/c-like-kind) 'c++)))))

(defun my-test--fast-c-indent (expected)
  "Strip indentation from EXPECTED, re-indent it in `fast-c-mode', compare."
  (with-temp-buffer
    (insert (replace-regexp-in-string "^[ \t]+" "" expected))
    (fast-c-mode)
    (indent-region (point-min) (point-max))
    (should (equal (buffer-string) expected))))

(ert-deftest my-test-fast-c-indent-blocks ()
  (my-test--fast-c-indent
   "int main(void) {\n    if (x) {\n        x++;\n    } else {\n        x--;\n    }\n    return x;\n}\n")
  (my-test--fast-c-indent "int main(void)\n{\n    if (x)\n    {\n        y();\n    }\n}\n")
  (my-test--fast-c-indent "void f() {\n    do {\n        a();\n    } while (x);\n    b();\n}\n"))

(ert-deftest my-test-fast-c-indent-braceless ()
  (my-test--fast-c-indent
   "void f() {\n    if (a)\n        b();\n    else if (c)\n        d();\n    else\n        e();\n    for (;;)\n        if (x)\n            y();\n    z();\n}\n")
  (my-test--fast-c-indent "void f() {\n    if (a &&\n        b)\n        c();\n    d();\n}\n"))

(ert-deftest my-test-fast-c-indent-parens-and-labels ()
  (my-test--fast-c-indent
   "void f() {\n    foo(a,\n        b);\n    bar(\n        x\n    );\n}\n")
  (my-test--fast-c-indent
   "void f() {\n    switch (x) {\n    case 1:\n        a();\n        break;\n    default:\n        c();\n    }\n}\n")
  (my-test--fast-c-indent "class A {\npublic:\n    int x;\nprivate:\n    void f();\n};\n"))

(ert-deftest my-test-fast-c-indent-comments-preprocessor ()
  (my-test--fast-c-indent
   "/* a\n * b\n */\nvoid f() {\n    // note {\n#ifdef X\n    a();\n#endif\n    puts(\"{\");\n    b();\n}\n"))

(ert-deftest my-test-fast-c-highlight-and-imenu ()
  (require 'imenu)
  (with-temp-buffer
    (insert "#include <stdio.h>\n#define MAX 10\nstruct Foo { int a; };\nstatic int add(int a, int b)\n{\n    size_t n = MAX;\n    return a + b;\n}\n")
    (fast-c-mode)
    (font-lock-ensure)
    (cl-flet ((face-at (s) (goto-char (point-min)) (search-forward s)
                       (get-text-property (1- (point)) 'face)))
      (should (eq (face-at "stdio") 'font-lock-string-face))
      (should (eq (face-at "return") 'font-lock-keyword-face))
      (should (eq (face-at "size_t") 'font-lock-type-face))
      (should (eq (face-at "add") 'font-lock-function-name-face)))
    (let ((index (imenu--generic-function imenu-generic-expression)))
      (should (assoc "add" index))
      (should (assoc "Types" index))
      (should (assoc "Macros" index)))))

;;;; compile-command defaults
(ert-deftest my-test-compile-command-single-c ()
  (my-test--with-file "main.c" "int main(void){return 0;}\n"
    (should (equal compile-command "gcc -Wall -Wextra -g -o main main.c && ./main"))))

(ert-deftest my-test-compile-command-cpp ()
  (my-test--with-file "sol.cpp" "int main(){}\n"
    (should (string-prefix-p "g++ -std=c++20" compile-command))))

(ert-deftest my-test-compile-command-nob ()
  (let* ((dir (make-temp-file "emacs-test-" t)))
    (unwind-protect
        (progn
          (with-temp-file (expand-file-name "nob.c" dir) (insert ""))
          (with-temp-file (expand-file-name "x.c" dir) (insert "int x;\n"))
          (with-current-buffer (find-file-noselect (expand-file-name "x.c" dir))
            (should (string-match-p "nob" compile-command))
            (kill-buffer)))
      (delete-directory dir t))))

(ert-deftest my-test-compile-command-dir-locals-win ()
  (let* ((dir (make-temp-file "emacs-test-" t))
         (enable-local-variables :all))
    (unwind-protect
        (progn
          (with-temp-file (expand-file-name ".dir-locals.el" dir)
            (insert "((nil . ((compile-command . \"make -j && ./main\"))))"))
          (with-temp-file (expand-file-name "x.c" dir) (insert "int x;\n"))
          (with-current-buffer (find-file-noselect (expand-file-name "x.c" dir))
            (should (equal compile-command "make -j && ./main"))
            (kill-buffer)))
      (delete-directory dir t))))

;;;; Keys
(ert-deftest my-test-rexim-keys ()
  (should (eq (keymap-global-lookup "C-,") #'duplicate-dwim))
  (should (eq (keymap-global-lookup "C-x C-g") #'find-file-at-point))
  (should (eq (keymap-global-lookup "C-c i m") #'consult-imenu))
  (should (eq (keymap-global-lookup "C-c m s") #'magit-status))
  (should (eq (keymap-global-lookup "C-c M-q") #'my/unfill-paragraph))
  (should (eq (keymap-global-lookup "C-c r") #'recompile))
  (should (eq (keymap-global-lookup "C-c x") #'my/run-file))
  (should (keymapp (keymap-global-lookup "C-c SPC"))))

(ert-deftest my-test-package-keys ()
  (skip-unless (package-installed-p 'consult))
  (should (eq (keymap-global-lookup "C-x b") #'consult-buffer))
  (should (eq (keymap-global-lookup "M-p") #'move-text-up))
  (should (eq (keymap-global-lookup "C->") #'mc/mark-next-like-this)))

;;;; Packages (only when installed)
(ert-deftest my-test-completion-stack ()
  (skip-unless (package-installed-p 'vertico))
  (should vertico-mode)
  (should marginalia-mode)
  (should global-corfu-mode)
  (should (memq 'orderless completion-styles)))

(ert-deftest my-test-theme ()
  (skip-unless (package-installed-p 'gruber-darker-theme))
  (should (custom-theme-enabled-p 'gruber-darker)))

;;;; Evil (Vim keys)
(ert-deftest my-test-leader-everywhere ()
  (should (keymapp (keymap-global-lookup "C-c SPC")))
  (should (eq (keymap-lookup my/leader-map "?") #'my/vim-to-emacs))
  (should (eq (keymap-lookup my/leader-map "t e") #'my/toggle-evil))
  (should (eq (keymap-global-lookup "C-c v") #'my/toggle-evil)))

(ert-deftest my-test-evil-setup ()
  (skip-unless (and my/use-evil (package-installed-p 'evil)))
  (should evil-mode)
  (with-temp-buffer
    (fundamental-mode)
    (evil-local-mode 1)
    (evil-normal-state)
    (should (keymapp (key-binding (kbd "SPC"))))   ; leader
    (evil-insert-state)
    ;; Emacs keys while typing
    (should (eq (key-binding (kbd "C-a")) #'my/smart-beginning-of-line))
    (should (eq (key-binding (kbd "C-e")) #'move-end-of-line))))

(ert-deftest my-test-vim-cheat-sheet ()
  (save-window-excursion (my/vim-to-emacs))
  (with-current-buffer "*Vim -> Emacs*"
    (should (string-match-p "C-x C-s" (buffer-string)))))

;;;; Helpers
(ert-deftest my-test-copy-line ()
  (with-temp-buffer
    (insert "first\nsecond\n")
    (goto-char (point-min))
    (my/copy-region-or-line)
    (should (equal (current-kill 0) "first\n"))))

(ert-deftest my-test-unfill-paragraph ()
  (with-temp-buffer
    (insert "one\ntwo\nthree\n")
    (goto-char (point-min))
    (my/unfill-paragraph)
    (should (equal (buffer-string) "one two three\n"))))

(ert-deftest my-test-smart-bol ()
  (with-temp-buffer
    (insert "    foo")
    (my/smart-beginning-of-line)
    (should (= (current-column) 4))
    (my/smart-beginning-of-line)
    (should (= (current-column) 0))))

;;;; Autocommit
(ert-deftest my-test-autocommit-init-merges-dir-locals ()
  (skip-unless (executable-find "git"))
  (let ((dir (file-name-as-directory (make-temp-file "emacs-test-" t))))
    (unwind-protect
        (progn
          (let ((default-directory dir)) (call-process "git" nil nil nil "init" "-q"))
          (with-temp-file (expand-file-name ".dir-locals.el" dir)
            (insert "((org-mode . ((fill-column . 70))))"))
          (my/autocommit-init dir)
          (my/autocommit-init dir)        ; twice: must not duplicate
          (let ((alist (with-temp-buffer
                         (insert-file-contents (expand-file-name ".dir-locals.el" dir))
                         (read (current-buffer)))))
            (should (equal (alist-get 'org-mode alist) '((fill-column . 70))))
            (should (equal (alist-get nil alist) '((eval my/autocommit-mode 1))))))
      (delete-directory dir t))))

(ert-deftest my-test-autocommit-commits ()
  (skip-unless (executable-find "git"))
  (let* ((dir (file-name-as-directory (make-temp-file "emacs-test-" t)))
         (default-directory dir)
         (my/autocommit-delay 0.1)
         (my/autocommit-push nil))
    (unwind-protect
        (progn
          (call-process "git" nil nil nil "init" "-q")
          (call-process "git" nil nil nil "config" "user.email" "test@example.com")
          (call-process "git" nil nil nil "config" "user.name" "test")
          (with-current-buffer (find-file-noselect (expand-file-name "notes.org" dir))
            (my/autocommit-mode 1)
            (insert "* hello")
            (save-buffer)
            (let ((deadline (+ (float-time) 10)))
              (while (and (< (float-time) deadline)
                          (not (zerop (call-process "git" nil nil nil "rev-parse" "HEAD"))))
                (accept-process-output nil 0.1)))
            (kill-buffer))
          (should (zerop (call-process "git" nil nil nil "rev-parse" "HEAD"))))
      (delete-directory dir t))))

;;;; Platform file (macOS in git; Fedora by switching blocks)
(ert-deftest my-test-platform-block ()
  (should (memq my/platform '(macos fedora)))
  (should (featurep 'init-platform))
  (if (eq my/platform 'macos)
      (progn (should (eq mac-command-modifier 'meta))
             (should (eq (keymap-global-lookup "s-<mouse-1>") #'mc/add-cursor-on-click)))
    (should (eq (keymap-global-lookup "M-<mouse-1>") #'mc/add-cursor-on-click))))

(ert-deftest my-test-platform-file-switchable ()
  ;; Exactly one block active, each line of the other one commented.
  (let* ((file (expand-file-name "lisp/init-platform.el" user-emacs-directory))
         (text (with-temp-buffer (insert-file-contents file) (buffer-string))))
    (should (string-match-p "^;;;; >>> MACOS BEGIN" text))
    (should (string-match-p "^;;;; >>> FEDORA BEGIN" text))
    (should (= 1 (with-temp-buffer
                   (insert text) (goto-char (point-min))
                   (how-many "^(setq my/platform '"))))))

;;;; Rexim-style editing: line numbers + multiple cursors
(ert-deftest my-test-line-numbers-hybrid ()
  (should (eq display-line-numbers-type 'relative))
  (should display-line-numbers-current-absolute)   ; real number on the cursor line
  (should my/global-line-numbers-mode)
  (my-test--with-file "x.py" "a = 1\nb = 2\n"
    (should display-line-numbers-mode)
    (should (eq display-line-numbers 'relative)))
  (with-temp-buffer
    (eshell-mode)
    (my/line-numbers-maybe)
    (should-not display-line-numbers-mode))
  (should (equal (face-attribute 'line-number-current-line :foreground) "#ffdd33")))

(ert-deftest my-test-multiple-cursors-keys ()
  (should (commandp #'my/mouse-column-cursors))
  (skip-unless (package-installed-p 'multiple-cursors))
  (should (eq (keymap-global-lookup "C-S-c C-S-c") #'mc/edit-lines))
  (should (eq (keymap-global-lookup "C->") #'mc/mark-next-like-this))
  (should (eq (keymap-global-lookup "C-S-<mouse-1>") #'mc/add-cursor-on-click)))

(ert-deftest my-test-multiple-cursors-evil ()
  (skip-unless (and (package-installed-p 'multiple-cursors) (package-installed-p 'evil)))
  (require 'multiple-cursors)
  (with-temp-buffer
    (insert "one\ntwo\nthree\n")
    (evil-local-mode 1)
    (evil-normal-state)
    (goto-char (point-min))
    (mc/mark-next-lines 1)
    (should multiple-cursors-mode)
    (should (eq evil-state 'emacs))          ; cursors type in Emacs state
    (mc/keyboard-quit)
    (should-not multiple-cursors-mode)
    (should (eq evil-state 'normal))))       ; and Vim comes back

;;;; Speed and disk
(ert-deftest my-test-deferred-hooks-ran ()
  (should my/first-input-done)
  (should my/first-file-done)
  (should (null my/first-input-hook))
  ;; Late additions run right away instead of being lost.
  (let (ran) (my/on-first-input (lambda () (setq ran t))) (should ran)))

(ert-deftest my-test-startup-shortcuts ()
  (should (eq initial-major-mode 'fundamental-mode))
  (should load-prefer-newer)
  (should save-place-mode))

(ert-deftest my-test-lazy-mode-routing ()
  (should (eq (cdr (assoc "\\.go\\'" auto-mode-alist)) 'my/lazy-go-mode))
  (should (rassq 'my/lazy-yaml-mode auto-mode-alist))
  ;; No grammar, no network: falls back to prog-mode instead of erroring.
  (cl-letf (((symbol-function 'treesit-language-available-p) (lambda (&rest _) nil))
            ((symbol-function 'my/lazy-install) (lambda (_) nil)))
    (with-temp-buffer (my/lazy-go-mode) (should (eq major-mode 'prog-mode)))))

(ert-deftest my-test-lazy-command-stub ()
  (should (fboundp 'dape))
  (should (commandp 'docker)))

(ert-deftest my-test-hardlink-snapshot ()
  (skip-unless (memq system-type '(gnu/linux darwin berkeley-unix)))
  (let* ((src (make-temp-file "emacs-test-src" t))
         (dest (concat src "-copy")))
    (unwind-protect
        (progn
          (make-directory (expand-file-name "pkg-1.0" src))
          (with-temp-file (expand-file-name "pkg-1.0/a.el" src) (insert "x"))
          (my/copy-tree-cheap src dest)
          (let ((a (file-attributes (expand-file-name "pkg-1.0/a.el" src)))
                (b (file-attributes (expand-file-name "pkg-1.0/a.el" dest))))
            (should b)
            ;; Same inode = hard link = no extra disk.
            (when (eq system-type 'gnu/linux)
              (should (equal (file-attribute-inode-number a) (file-attribute-inode-number b))))))
      (delete-directory src t)
      (when (file-directory-p dest) (delete-directory dest t)))))

(ert-deftest my-test-disk-usage-report ()
  (should (string-match-p "total" (my/disk-usage))))

(ert-deftest my-test-huge-file-drops-extras ()
  (my-test--with-file "big.log" (make-string (1+ (* 4 my/c-big-file-size)) ?x)
    (should-not (bound-and-true-p display-line-numbers-mode))))

(ert-deftest my-test-treesit-langs-limited ()
  (skip-unless (package-installed-p 'treesit-auto))
  (should (< (length treesit-auto-langs) 25)))

;;;; Doctor
(ert-deftest my-test-doctor-runs ()
  (let ((noninteractive nil))
    (save-window-excursion (my/doctor)))
  (should (get-buffer "*doctor*"))
  (with-current-buffer "*doctor*"
    (should (string-match-p "Programs" (buffer-string)))))

(ert-deftest my-test-doctor-sees-packages ()
  (let ((pkgs (my/doctor--configured-packages)))
    (should (memq 'vertico pkgs))
    (should (memq 'magit pkgs))
    (should-not (memq 'eglot pkgs))      ; built in
    (should-not (memq 'vterm pkgs))))    ; :if, optional

(provide 'smoke-test)
;;; smoke-test.el ends here

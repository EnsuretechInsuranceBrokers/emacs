;;; init-compile.el --- The open, edit, build, run loop -*- lexical-binding: t; -*-

;;; Commentary:
;; Tsoding's workflow: M-x compile once, then just hit recompile.
;;   C-c c / SPC c c   compile (asks for the command, remembers it)
;;   C-c r / SPC r     recompile (rerun the last command, no questions)
;;   C-c x / SPC m r   run this file: C++ with input.txt, C, Go, Python...
;;   M-g n / M-g p     next/previous error, jumps to the source line
;;   C-x p c           compile from the project root
;;
;; Per-project command: put a .dir-locals.el in the project root:
;;   ((nil . ((compile-command . "make -j && ./main"))))

;;; Code:

(use-package compile
  :ensure nil
  :defer t
  :config
  (setq compilation-scroll-output t          ; follow the output
        compilation-ask-about-save nil       ; save all buffers, no prompt
        compilation-always-kill t            ; restart without asking
        compilation-skip-threshold 1         ; M-g n skips "info" lines
        compilation-max-output-line-length nil)
  ;; Colours from compilers/test runners instead of ^[[31m junk.
  (add-hook 'compilation-filter-hook #'ansi-color-compilation-filter)
  ;; Go test/panic locations: "    main_test.go:12: ..."
  (add-to-list 'compilation-error-regexp-alist-alist
               '(go-test "^\\s-+\\([^ \t\n]+\\.go\\):\\([0-9]+\\):" 1 2))
  (add-to-list 'compilation-error-regexp-alist 'go-test))

;; Build output opens at the bottom, a third of the frame, and reuses
;; the same window every time.
(add-to-list 'display-buffer-alist
             '("\\*compilation\\*\\|\\*cp-run\\*"
               (display-buffer-reuse-window display-buffer-at-bottom)
               (window-height . 0.3)
               (reusable-frames . visible)))

;; Only ask for the compile command when there is none yet.
(defun my/compile-dwim (arg)
  "Recompile if a build has run in this session, else `compile'.
With a prefix ARG, always ask for the command."
  (interactive "P")
  (if (or arg (not (get-buffer "*compilation*")))
      (call-interactively #'compile)
    (recompile)))

;;;; Which C-family language is this buffer?
(defun my/c-like-kind-from-name ()
  "`c++' or `c', judging by the file extension."
  (if (and buffer-file-name
           (string-match-p "\\.\\(?:cc\\|cpp\\|cxx\\|c\\+\\+\\|hh\\|hpp\\|hxx\\|inl\\)\\'"
                           buffer-file-name))
      'c++
    'c))

(defun my/c-like-kind ()
  "`c', `c++' or nil for this buffer (works for simpc-mode too)."
  (cond ((derived-mode-p 'c++-mode 'c++-ts-mode) 'c++)
        ((derived-mode-p 'c-mode 'c-ts-mode) 'c)
        ((derived-mode-p 'simpc-mode) (my/c-like-kind-from-name))))

;;;; Default compile-command for files without a build system
(defun my/default-compile-command ()
  "Pick a compile command for this buffer from what is in its directory."
  (when buffer-file-name
    (let* ((dir (file-name-directory buffer-file-name))
           (f (file-name-nondirectory buffer-file-name))
           (e (file-name-sans-extension f))
           (in (lambda (name) (file-exists-p (expand-file-name name dir)))))
      (cond
       ((funcall in "nob.c") "[ -x ./nob ] || cc -o nob nob.c; ./nob")  ; Tsoding's nob.h
       ((funcall in "build.sh") "./build.sh")
       ((funcall in "Makefile") "make -k ")
       ((funcall in "CMakeLists.txt") "cmake -S . -B build && cmake --build build -j")
       ((eq (my/c-like-kind) 'c)
        (format "gcc -Wall -Wextra -g -o %s %s && ./%s" e f e))
       ((eq (my/c-like-kind) 'c++)
        (format "g++ -std=c++20 -Wall -Wextra -g -o %s %s && ./%s" e f e))))))

(defun my/set-compile-command ()
  "Set `compile-command' unless a .dir-locals.el already did."
  (unless (local-variable-p 'compile-command)
    (when-let* ((cmd (my/default-compile-command)))
      (setq-local compile-command cmd))))

;; `hack-local-variables-hook' runs after .dir-locals.el is applied, so a
;; project's own command always wins.
(dolist (hook '(c-mode-hook c-ts-mode-hook c++-mode-hook c++-ts-mode-hook simpc-mode-hook))
  (add-hook hook
            (lambda ()
              (add-hook 'hack-local-variables-hook #'my/set-compile-command nil t))))

;; Go: the project command is usually one of these.
(dolist (hook '(go-mode-hook go-ts-mode-hook))
  (add-hook hook
            (lambda ()
              (add-hook 'hack-local-variables-hook
                        (lambda ()
                          (unless (local-variable-p 'compile-command)
                            (setq-local compile-command "go build ./... && go test ./...")))
                        nil t))))

;;;; Competitive programming
(defun my/cp-run ()
  "Build the current C++ file and run it, feeding input.txt if present."
  (interactive)
  (let* ((src (buffer-file-name))
         (exe (file-name-sans-extension src))
         (default-directory (file-name-directory src))
         (input (expand-file-name "input.txt" default-directory)))
    (save-buffer)
    (compile (format "g++ -std=c++20 -O2 -Wall -Wextra -DLOCAL -o %s %s && %s%s"
                     (shell-quote-argument exe)
                     (shell-quote-argument src)
                     (shell-quote-argument exe)
                     (if (file-exists-p input)
                         (concat " < " (shell-quote-argument input))
                       "")))))

(defun my/cp-open-input ()
  "Open input.txt next to this file in the other window."
  (interactive)
  (find-file-other-window
   (expand-file-name "input.txt" (file-name-directory (buffer-file-name)))))

(defun my/run-file ()
  "Build and run the current file with the obvious tool for its language."
  (interactive)
  (unless buffer-file-name (user-error "Buffer is not visiting a file"))
  (save-buffer)
  (let* ((f (shell-quote-argument buffer-file-name))
         (cmd (cond
               ((eq (my/c-like-kind) 'c++) nil)
               ((eq (my/c-like-kind) 'c)
                (let ((exe (shell-quote-argument (file-name-sans-extension buffer-file-name))))
                  (format "gcc -Wall -Wextra -g -o %s %s && %s" exe f exe)))
               ((derived-mode-p 'go-mode 'go-ts-mode) (format "go run %s" f))
               ((derived-mode-p 'python-mode 'python-ts-mode) (format "python3 %s" f))
               ((derived-mode-p 'php-mode 'php-ts-mode) (format "php %s" f))
               ((derived-mode-p 'js-mode 'js-ts-mode) (format "node %s" f))
               ((derived-mode-p 'sh-mode 'bash-ts-mode) (format "bash %s" f))
               (t (user-error "Don't know how to run %s" major-mode)))))
    (if cmd (compile cmd) (my/cp-run))))

;;;; PHP / Laravel
(defconst my/artisan-commands
  '("migrate" "migrate:fresh --seed" "migrate:rollback" "db:seed" "route:list"
    "make:model -mfc " "make:controller " "make:migration " "make:request "
    "make:test " "optimize:clear" "queue:work" "test" "serve" "tinker")
  "Common artisan commands offered for completion (anything else works too).")

(defun my/project-root ()
  "Root of the current project, or `default-directory'."
  (if-let* ((p (project-current))) (project-root p) default-directory))

(defun my/artisan (cmd)
  "Run `php artisan CMD' from the project root."
  (interactive (list (completing-read "artisan: " my/artisan-commands)))
  (let ((default-directory (my/project-root)))
    ;; tinker and serve are interactive/long-running: give them a comint buffer.
    (compile (concat "php artisan " cmd)
             (and (string-match-p "\\`\\(tinker\\|serve\\|queue\\)" cmd) t))))

(with-eval-after-load 'project
  (keymap-set project-prefix-map "a" #'my/artisan))

(provide 'init-compile)
;;; init-compile.el ends here

;;; config.el -*- lexical-binding: t; -*-

;;; ---------- Identity ----------
(setq user-full-name "Utkarsh")

;;; ---------- Look ----------
(setq doom-theme 'gruber-darker
      display-line-numbers-type 'relative
      scroll-margin 8)

;; Use Iosevka if installed, otherwise fall back to Doom's default.
(when (find-font (font-spec :name "Iosevka"))
  (setq doom-font (font-spec :family "Iosevka" :size 20)
        doom-variable-pitch-font (font-spec :family "Iosevka" :size 20)))

;;; ---------- Speed ----------
(setq which-key-idle-delay 0.3
      which-key-idle-secondary-delay 0.05
      read-process-output-max (* 4 1024 1024)
      redisplay-skip-fontification-on-input t
      fast-but-imprecise-scrolling t)

(after! lsp-mode
  (setq lsp-idle-delay 0.3
        lsp-lens-enable nil
        lsp-headerline-breadcrumb-enable nil
        lsp-signature-doc-lines 1
        lsp-enable-symbol-highlighting nil
        lsp-enable-on-type-formatting nil
        lsp-inlay-hint-enable nil
        lsp-log-io nil
        lsp-file-watch-threshold 5000))
(after! flycheck
  (setq flycheck-idle-change-delay 0.5))
(after! corfu
  (setq corfu-auto-delay 0.1
        corfu-auto-prefix 2))

;;; ---------- Fast buffer flying ----------
;; Doom already has: SPC , (buffers)  SPC . (files)  SPC SPC (project files)
;; SPC / (grep project)  SPC s s (search buffer)  SPC TAB (workspaces).
(map! :leader
      :desc "Last buffer"   "`"   #'evil-switch-to-windows-last-buffer
      :desc "Jump to char"  "j"   #'avy-goto-char-timer)
(map! :n "-" #'dired-jump)            ; vim-vinegar style
(after! avy (setq avy-timeout-seconds 0.25 avy-all-windows t))

;;; ---------- Compile loop (open, edit, build, run) ----------
(setq compilation-scroll-output t
      compilation-ask-about-save nil   ; auto-save, no prompt
      compilation-always-kill t)
(map! :leader :desc "recompile" "r" #'recompile)   ; SPC r = rerun last build

;; Per-project commands: drop a .dir-locals.el in the project root, e.g.
;; ((nil . ((compile-command . "make -j && ./main"))))

;; Default for a single C file with no Makefile/build.sh.  Runs after
;; .dir-locals.el, so a project's own command always wins.
(defun my/c-default-compile-command ()
  (when (and buffer-file-name
             (not (local-variable-p 'compile-command))
             (not (file-exists-p "Makefile"))
             (not (file-exists-p "build.sh")))
    (let* ((f (file-name-nondirectory buffer-file-name))
           (e (file-name-sans-extension f)))
      (setq-local compile-command
                  (if (file-exists-p "nob.c")
                      "[ -x ./nob ] || cc -o nob nob.c; ./nob"
                    (format "gcc -Wall -Wextra -g -o %s %s && ./%s" e f e))))))
(dolist (hook '(c-mode-hook c-ts-mode-hook))
  (add-hook hook (lambda ()
                   (add-hook 'hack-local-variables-hook
                             #'my/c-default-compile-command nil t))))

;;; ---------- Competitive programming ----------
(defun my/cp-run ()
  "Build the current C++ file and run it, feeding input.txt if present."
  (interactive)
  (let* ((src (buffer-file-name))
         (exe (file-name-sans-extension src))
         (default-directory (file-name-directory src))
         (input (expand-file-name "input.txt")))
    (save-buffer)
    (compile (format "g++ -std=c++20 -O2 -Wall -Wextra -DLOCAL -o %s %s && %s%s"
                     (shell-quote-argument exe)
                     (shell-quote-argument src)
                     (shell-quote-argument exe)
                     (if (file-exists-p input)
                         (concat " < " (shell-quote-argument input))
                       "")))))

(map! :after cc-mode
      :map (c-mode-map c++-mode-map)
      :localleader
      "r" #'my/cp-run)                 ; SPC m r
(map! :after c-ts-mode
      :map (c-ts-mode-map c++-ts-mode-map)
      :localleader
      "r" #'my/cp-run)

;;; ---------- PHP / Laravel ----------
;; Needs: npm i -g intelephense   (or install phpactor and switch client)
(defun my/artisan (cmd)
  "Run `php artisan CMD' from the project root."
  (interactive (list (completing-read "artisan: "
                                      '("migrate" "migrate:fresh --seed" "route:list"
                                        "make:model -mfc " "make:controller "
                                        "optimize:clear" "test" "tinker"))))
  (let ((default-directory (or (doom-project-root) default-directory)))
    (compile (concat "php artisan " cmd) (string-prefix-p "tinker" cmd))))
(map! :leader :desc "artisan" "p a" #'my/artisan)

;;; ---------- Go ----------
(after! lsp-mode
  (setq lsp-go-use-gofumpt t
        lsp-go-analyses '((nilness . t) (shadow . t) (unusedparams . t)
                          (unusedwrite . t) (useany . t))))
(defun my/go-organize-imports ()
  (when (bound-and-true-p lsp-mode)   ; don't error before the server is up
    (lsp-organize-imports)))
(dolist (hook '(go-mode-hook go-ts-mode-hook))
  (add-hook hook (lambda () (add-hook 'before-save-hook #'my/go-organize-imports nil t))))

;;; ---------- Magit ----------
(after! magit
  (setq magit-diff-refine-hunk 'all
        magit-save-repository-buffers 'dontask))

;;; ---------- Editing quality of life ----------
(setq evil-want-fine-undo t            ; finer undo granularity
      confirm-kill-emacs nil
      auto-save-default t
      make-backup-files nil
      undo-limit 80000000)
(setq-default tab-width 4
              indent-tabs-mode nil)

;; Strip trailing whitespace on save (except markdown, where it matters).
(add-hook 'before-save-hook
          (lambda () (unless (derived-mode-p 'markdown-mode)
                       (delete-trailing-whitespace))))

;;; ---------- Debugging ----------
(use-package! dape :defer t)

;;; ---------- Org ----------
(setq org-directory "~/org/")

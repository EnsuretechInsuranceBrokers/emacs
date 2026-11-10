;;; init-defaults.el --- Better built-in defaults -*- lexical-binding: t; -*-

;;; Code:

;;;; Identity
(setq user-full-name "Utkarsh")

;;;; Quiet, fast prompts
(setq ring-bell-function #'ignore
      use-short-answers t                 ; y/n instead of yes/no
      confirm-kill-emacs nil
      confirm-nonexistent-file-or-buffer nil
      kill-buffer-query-functions (delq 'process-kill-buffer-query-function
                                        kill-buffer-query-functions)
      initial-scratch-message nil
      echo-keystrokes 0.02                ; show prefix keys immediately
      help-window-select t                ; jump into *Help* so q closes it
      enable-recursive-minibuffers t
      read-extended-command-predicate #'command-completion-default-include-p)
(add-hook 'my/first-input-hook #'minibuffer-depth-indicate-mode)

;;;; Files: no backups/lockfiles, auto-saves out of the project tree
(setq make-backup-files nil
      create-lockfiles nil
      auto-save-default t
      auto-save-list-file-prefix (expand-file-name "auto-save/.saves-" my/var-dir)
      auto-save-file-name-transforms
      `((".*" ,(expand-file-name "auto-save/" my/var-dir) t))
      require-final-newline t
      delete-by-moving-to-trash t)
(make-directory (expand-file-name "auto-save/" my/var-dir) t)

;; Reload files changed on disk (git checkout, formatters...).
(setq auto-revert-verbose nil
      auto-revert-avoid-polling t
      global-auto-revert-non-file-buffers t)
(add-hook 'my/first-file-hook #'global-auto-revert-mode)

;;;; History that survives restarts
(setq savehist-file (expand-file-name "savehist" my/var-dir)
      history-length 1000
      history-delete-duplicates t
      savehist-additional-variables '(search-ring regexp-search-ring compile-command) ; not kill-ring: big, may hold secrets
      save-place-file (expand-file-name "places" my/var-dir)
      recentf-save-file (expand-file-name "recentf" my/var-dir)
      recentf-max-saved-items 300
      recentf-auto-cleanup 'never
      recentf-exclude `(,(regexp-quote (expand-file-name "elpa/" user-emacs-directory))
                        ,(regexp-quote my/var-dir)
                        "/tmp/" "COMMIT_EDITMSG\\'" "/\\.git/")
      bookmark-default-file (expand-file-name "bookmarks" my/var-dir)
      project-list-file (expand-file-name "projects" my/var-dir)
      transient-history-file (expand-file-name "transient/history.el" my/var-dir)
      transient-levels-file (expand-file-name "transient/levels.el" my/var-dir)
      transient-values-file (expand-file-name "transient/values.el" my/var-dir)
      eshell-directory-name (expand-file-name "eshell/" my/var-dir)
      url-configuration-directory (expand-file-name "url/" my/var-dir)
      tramp-persistency-file-name (expand-file-name "tramp" my/var-dir)
      multisession-directory (expand-file-name "multisession/" my/var-dir)
      mc/list-file (expand-file-name "mc-lists.el" my/var-dir))
(save-place-mode 1)                          ; must be on before the first file
(add-hook 'my/first-input-hook #'savehist-mode)
(add-hook 'my/first-input-hook #'recentf-mode)
(add-hook 'my/first-file-hook
          (lambda () (recentf-mode 1) (recentf-track-opened-file))) ; count this first file too

;;;; Editing
(setq-default tab-width 4
              indent-tabs-mode nil
              fill-column 80
              truncate-lines t)
(setq undo-limit 80000000
      undo-strong-limit 120000000
      undo-outer-limit 360000000
      kill-ring-max 500
      kill-do-not-save-duplicates t
      save-interprogram-paste-before-kill t
      mouse-yank-at-point t
      sentence-end-double-space nil
      show-paren-delay 0
      show-paren-context-when-offscreen 'overlay
      blink-matching-paren nil)
(add-hook 'my/first-input-hook #'delete-selection-mode) ; typing replaces the selection
(add-hook 'my/first-input-hook #'electric-pair-mode)    ; auto-close brackets/quotes

;; Strip trailing whitespace on save, except in markdown (two trailing
;; spaces there are a line break).
(defun my/delete-trailing-whitespace ()
  (unless (derived-mode-p 'markdown-mode)
    (delete-trailing-whitespace)))
(add-hook 'before-save-hook #'my/delete-trailing-whitespace)

;;;; Scrolling: keep 8 lines of context, never jump half a screen.
(setq scroll-margin 8
      scroll-conservatively 101
      scroll-preserve-screen-position t
      next-screen-context-lines 4
      hscroll-margin 4
      hscroll-step 1
      mouse-wheel-scroll-amount '(3 ((shift) . hscroll))
      mouse-wheel-progressive-speed nil)
(when (fboundp 'pixel-scroll-precision-mode)
  (add-hook 'my/first-input-hook #'pixel-scroll-precision-mode))

;;;; Buffers and windows
(setq uniquify-buffer-name-style 'forward
      switch-to-buffer-obey-display-actions t
      split-width-threshold 160
      split-height-threshold nil)       ; prefer side-by-side splits
(add-hook 'my/first-input-hook #'winner-mode) ; C-c <left> undoes a window change
(add-hook 'my/first-input-hook #'repeat-mode) ; C-x o o o, C-x { { {, ...

;;;; Search
(setq isearch-lazy-count t               ; "3/17" in the prompt
      lazy-count-prefix-format "%s/%s "
      search-whitespace-regexp ".*?"     ; "foo bar" matches "foo ... bar"
      isearch-allow-scroll t)

;;;; macOS / Fedora specifics live in init-platform.el (one file to switch).

;;;; macOS / daemon: get $PATH from your shell so gopls, clangd, node... are found.
(use-package exec-path-from-shell
  :if (and (or my/exec-path-from-shell (daemonp)) (my/package-p 'exec-path-from-shell)) ; init-platform.el
  :demand t
  :config
  (setq exec-path-from-shell-arguments '("-l"))
  (dolist (var '("GOPATH" "GOROOT" "NVM_DIR" "LANG" "LC_ALL"))
    (add-to-list 'exec-path-from-shell-variables var))
  (exec-path-from-shell-initialize))

(provide 'init-defaults)
;;; init-defaults.el ends here

;;; init-ui.el --- Look: gruber-darker, Iosevka, relative numbers -*- lexical-binding: t; -*-

;;; Code:

;;;; Theme
(use-package gruber-darker-theme :demand t)
(unless (ignore-errors (load-theme 'gruber-darker t) t)
  ;; Not installed yet (offline first run?): use a built-in dark theme.
  (load-theme 'modus-vivendi t))

;;;; Font
(defun my/setup-font (&optional frame)
  "Use the first installed font in `my/fonts' on FRAME."
  (with-selected-frame (or frame (selected-frame))
    (when (display-graphic-p)
      (when-let* ((font (seq-find (lambda (f) (find-font (font-spec :name f)))
                                 my/fonts)))
        (let ((spec (format "%s-%d" font my/font-size)))
          (set-face-attribute 'default nil :font spec)
          (set-face-attribute 'fixed-pitch nil :font spec)
          (set-face-attribute 'variable-pitch nil :font spec)
          (setf (alist-get 'font default-frame-alist) spec))))))
(my/setup-font)
;; With `emacs --daemon' there is no frame yet: set the font on the first one.
(add-hook 'server-after-make-frame-hook #'my/setup-font)

;; C-x C-= / C-x C-- zoom one buffer; these zoom everything.
(defun my/font-bigger () (interactive)
  (setq my/font-size (1+ my/font-size)) (my/setup-font))
(defun my/font-smaller () (interactive)
  (setq my/font-size (1- my/font-size)) (my/setup-font))

;;;; Line numbers: relative, so "7j"/"C-u 7 C-n" jumps are obvious.
(setq display-line-numbers-type 'relative
      display-line-numbers-width 3
      display-line-numbers-grow-only t)  ; no jitter when crossing 99 -> 100
(dolist (hook '(prog-mode-hook conf-mode-hook text-mode-hook))
  (add-hook hook #'display-line-numbers-mode))

;;;; Small things
(blink-cursor-mode -1)
(column-number-mode 1)
(setq-default show-trailing-whitespace nil)
(add-hook 'prog-mode-hook (lambda () (setq show-trailing-whitespace t)))
(setq frame-title-format '("%b — Emacs")
      x-underline-at-descent-line t
      window-divider-default-right-width 1
      window-divider-default-places 'right-only
      mode-line-compact 'long)
(window-divider-mode 1)

;; Highlight TODO / FIXME / HACK / NOTE.
(use-package hl-todo
  :hook ((prog-mode conf-mode) . hl-todo-mode))

;; Shows which key to press next after a prefix (C-x, C-c, SPC...).
;; Built into Emacs 30; installed from GNU ELPA on 29.
(use-package which-key
  :hook (my/first-input . which-key-mode)
  :config
  (setq which-key-idle-delay 0.4
        which-key-idle-secondary-delay 0.05
        which-key-sort-order #'which-key-key-order-alpha))

(provide 'init-ui)
;;; init-ui.el ends here

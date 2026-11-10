;;; init-evil.el --- Optional Vim layer (set `my/use-evil' to t) -*- lexical-binding: t; -*-

;;; Commentary:
;; Loaded only when `my/use-evil' is non-nil.  The SPC leader map lives in
;; init-keys.el and is shared with plain Emacs (C-c SPC), so both modes
;; have the same Doom-style commands.

;;; Code:

(use-package evil
  :demand t
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil          ; evil-collection handles other modes
        evil-want-C-u-scroll t
        evil-want-C-d-scroll t
        evil-want-Y-yank-to-eol t
        evil-want-fine-undo t             ; from your Doom config
        evil-undo-system 'undo-redo
        evil-split-window-below t
        evil-vsplit-window-right t
        evil-symbol-word-search t         ; * searches foo_bar, not foo
        evil-respect-visual-line-mode t
        evil-search-module 'evil-search
        evil-ex-search-vim-style-regexp t
        evil-kill-on-visual-paste nil)
  :config
  (evil-mode 1)
  ;; Keep Emacs keys in places where Vim keys get in the way.
  (dolist (mode '(vterm-mode eshell-mode))
    (evil-set-initial-state mode 'emacs)))

(use-package evil-collection
  :after evil
  :demand t
  :config
  (setq evil-collection-want-unimpaired-p t)
  (evil-collection-init))

(use-package evil-surround                  ; cs"' / ysiw) / ds(
  :after evil
  :demand t
  :config (global-evil-surround-mode 1))

(use-package evil-commentary                ; gcc comments a line, gc in visual
  :after evil
  :demand t
  :config (evil-commentary-mode 1))

(provide 'init-evil)
;;; init-evil.el ends here

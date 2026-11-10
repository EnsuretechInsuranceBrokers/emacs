;;; personal.el --- Machine-local settings -*- lexical-binding: t; -*-
;; Copy this file to personal.el (git-ignored) and edit.  It is loaded
;; before every module, so it can change the knobs in init.el.

;; Vim keys are ON by default (coming from Neovim).  When you've learned
;; the Emacs keys, switch them off.  C-c v toggles at any time to practise.
;; (setq my/use-evil nil)

;; Font: first installed one wins.
;; (setq my/fonts '("Iosevka" "JetBrains Mono")
;;       my/font-size 18)

;; C/C++ mode: 'auto (tree-sitter; fast-c-mode for huge files), 'fast
;; (always our fast-c-mode), or 'cc (never fast-c-mode).
;; (setq my/c-mode 'fast)

;; Draw every space as a dot, like Tsoding's streams.  'light (default) or nil.
;; (setq my/whitespace-style 'dots)

;; No paredit in Lisp buffers / no extra language modes.
;; (setq my/use-paredit nil
;;       my/extra-languages nil)

;; Autocommit: commit only (don't push) by default, wait longer.
;; (setq my/autocommit-push nil
;;       my/autocommit-delay 30)

;; Don't start an Emacs server.
;; (setq my/start-server nil)

;; Anything else, e.g.:
;; (setq user-full-name "Utkarsh"
;;       user-mail-address "you@example.com")

;;; personal.el --- Machine-local settings -*- lexical-binding: t; -*-
;; Copy this file to personal.el (git-ignored) and edit.  It is loaded
;; before every module, so it can change the knobs in init.el.

;; Vim keys + SPC leader (your Doom muscle memory).  nil = classic Emacs keys.
;; (setq my/use-evil t)

;; Font: first installed one wins.
;; (setq my/fonts '("Iosevka" "JetBrains Mono")
;;       my/font-size 18)

;; C/C++ mode: 'auto (tree-sitter, simpc for huge files), 'simpc (exactly
;; like rexim), or 'cc (never simpc).
;; (setq my/c-mode 'simpc)

;; Draw every space as a dot, like rexim's streams.  'light (default) or nil.
;; (setq my/whitespace-style 'rexim)

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

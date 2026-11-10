;;; init.el --- Fast, keyboard-first Emacs -*- lexical-binding: t; -*-

;;; Commentary:
;; A vanilla Emacs config in the rexim/Tsoding spirit: dark gruber theme,
;; Iosevka, instant buffer/file switching, compile-driven workflow.
;; Ported from a Doom setup, so Doom habits (SPC leader, evil) are one
;; switch away: set `my/use-evil' to t in personal.el.
;;
;; Layout:
;;   early-init.el       startup speed, frame setup
;;   init.el             this file: options + module loading
;;   lisp/init-*.el      one file per topic
;;   lisp/my-*.el        small self-contained features (autocommit)
;;   site-lisp/          bundled third-party code (simpc-mode, MIT)
;;   personal.el         your machine-local overrides (git-ignored)
;;   test/               smoke tests: ./test/run.sh
;;
;; Health check: M-x my/doctor.  Upgrade safely: M-x my/upgrade.
;;
;; Needs Emacs 29.1 or newer.

;;; Code:

(when (version< emacs-version "29.1")
  (error "This config needs Emacs 29.1+, you have %s" emacs-version))

;;;; Knobs (override any of these in personal.el)
(defgroup my nil "Personal configuration." :group 'convenience)

(defcustom my/use-evil nil
  "Non-nil: Vim keys via evil, with a Doom-style SPC leader.
Nil: classic Emacs keys, like rexim/Tsoding."
  :type 'boolean)

(defcustom my/fonts '("Iosevka" "Iosevka Term" "JetBrains Mono" "DejaVu Sans Mono")
  "Fonts to try in order.  The first installed one wins."
  :type '(repeat string))

(defcustom my/font-size 20
  "Font size in points."
  :type 'integer)

(defcustom my/start-server t
  "Start an Emacs server so `emacsclient' opens files in this Emacs."
  :type 'boolean)

;;;; Paths
(defconst my/lisp-dir (expand-file-name "lisp" user-emacs-directory))
(defconst my/var-dir (expand-file-name "var/" user-emacs-directory)
  "Where state files (history, backups, auto-saves) live.")
(make-directory my/var-dir t)
(add-to-list 'load-path my/lisp-dir)

;; Keep M-x customize out of init.el.
(setq custom-file (expand-file-name "custom.el" my/var-dir))

;; Machine-local overrides: fonts, `my/use-evil', secrets.
(let ((personal (expand-file-name "personal.el" user-emacs-directory)))
  (when (file-exists-p personal)
    (load personal nil t)))

;;;; Modules (order matters: package first, keys last)
(require 'init-package)     ; package.el + use-package bootstrap
(require 'init-perf)        ; GC, process output, redisplay tweaks
(require 'init-defaults)    ; sane built-in defaults
(require 'init-ui)          ; theme, font, line numbers, modeline
(require 'init-completion)  ; vertico, orderless, consult, corfu
(require 'init-navigation)  ; flying between buffers/windows/files
(require 'init-editing)     ; multiple cursors, move-text, snippets
(when my/use-evil
  (require 'init-evil))     ; optional Vim layer
(require 'init-dev)         ; eglot (LSP), tree-sitter, flymake, format
(require 'init-compile)     ; compile loop, C/C++ runners, artisan
(require 'init-langs)       ; per-language settings
(require 'init-rexim)       ; rexim's habits: simpc, whitespace, his keys
(require 'init-git)         ; magit, diff-hl
(require 'init-tools)       ; dired, vterm, docker, dape, org
(require 'init-keys)        ; global keymap + leader
(require 'init-maint)       ; M-x my/doctor, my/upgrade, my/rollback

(when (file-exists-p custom-file)
  (load custom-file nil t))

;;; init.el ends here

;;; init-package.el --- package.el + use-package -*- lexical-binding: t; -*-

;;; Commentary:
;; Packages install themselves on first launch (the first start is slow,
;; every start after that is fast).  To update: M-x package-upgrade-all.

;;; Code:

(require 'package)
(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa"  . "https://melpa.org/packages/"))
      ;; Prefer the curated GNU archives when a package is in several.
      package-archive-priorities '(("gnu" . 3) ("nongnu" . 2) ("melpa" . 1))
      package-install-upgrade-built-in nil
      package-native-compile t)

(unless (bound-and-true-p package--initialized)
  (package-initialize))

;; use-package refreshes the archive index once per *missing package*.
;; Offline, that is ~45 timeouts in a row.  During startup, refresh at
;; most once, and if the archives were unreachable, fail fast.
(defvar my/package-refresh-result nil "nil (not tried), `ok' or `failed'.")
(defun my/package-refresh-once (fn &rest args)
  (pcase my/package-refresh-result
    ('ok nil)
    ('failed (error "Package archives unreachable; will retry next start"))
    (_ (apply fn args)
       (setq my/package-refresh-result (if package-archive-contents 'ok 'failed)))))
(advice-add 'package-refresh-contents :around #'my/package-refresh-once)
(add-hook 'emacs-startup-hook
          (lambda () (advice-remove 'package-refresh-contents #'my/package-refresh-once)))

(require 'use-package)
(setq use-package-always-ensure t         ; install missing packages
      use-package-always-defer nil        ; each block says when it loads
      use-package-expand-minimally nil    ; keep error handling: one bad package won't kill init
      use-package-enable-imenu-support t  ; M-g i in this config lists packages
      use-package-compute-statistics nil) ; t + M-x use-package-report to profile

;; Safety net: if a package failed to install (offline, renamed on MELPA),
;; skip its whole block instead of leaving hooks that point at missing
;; code and break every buffer.  `:ensure' runs first, so on a normal
;; first start this check sees the freshly installed package.
(require 'use-package-ensure)
(add-to-list 'use-package-defaults
             '(:if
               (lambda (name _args) `(package-installed-p ',name))
               (lambda (_name args)
                 (and (not (plist-member args :if))
                      (car (plist-get args :ensure)))))
             t)

(provide 'init-package)
;;; init-package.el ends here

;;; init-package.el --- package.el + use-package -*- lexical-binding: t; -*-

;;; Commentary:
;; Packages install themselves on first launch (the first start is slow,
;; every start after that is fast).  To update: M-x package-upgrade-all.

;;; Code:

;; Speed: after the first start, nothing here loads package.el (55 ms) or
;; use-package (15 ms).  Packages are activated by the pre-generated
;; `package-quickstart' file, the config is byte-compiled, and "is this
;; installed?" is answered from `package-activated-list'.  package.el is
;; only loaded when something actually has to be installed.

(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa"  . "https://melpa.org/packages/"))
      ;; Prefer the curated GNU archives when a package is in several.
      package-archive-priorities '(("gnu" . 3) ("nongnu" . 2) ("melpa" . 1))
      package-install-upgrade-built-in nil
      package-native-compile t)            ; compile packages once, at install

;; With quickstart, Emacs already activated everything before init.el.
(unless (or (bound-and-true-p package--activated)
            (bound-and-true-p package--initialized))
  (package-initialize))

(defun my/package-p (name)
  "Non-nil if package NAME is available.  Fast: no package.el when installed."
  (or (memq name (bound-and-true-p package-activated-list))
      (and (locate-library (symbol-name name)) t)          ; built in (which-key on 30...)
      (progn (require 'package) (package-installed-p name))))

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

(defun my/use-package-ensure (name args state &optional no-refresh)
  "Install NAME if missing.  The common case (installed) costs one list lookup."
  (unless (and (equal args '(t)) (my/package-p name))
    (require 'use-package-ensure)
    (use-package-ensure-elpa name args state no-refresh)))

;; use-package itself is autoloaded: it only loads if a file in lisp/ isn't
;; compiled yet.  These settings apply whenever it does.
(setq use-package-always-ensure t          ; install missing packages
      use-package-ensure-function #'my/use-package-ensure
      use-package-always-defer nil         ; each block says when it loads
      use-package-expand-minimally nil     ; keep error handling: one bad package won't kill init
      use-package-enable-imenu-support t   ; M-g i in this config lists packages
      use-package-compute-statistics nil)  ; t + M-x use-package-report to profile

;; The `use-package' autoload only loads use-package-core; pull in the rest
;; (:ensure, :bind, ...) whenever that happens.
(with-eval-after-load 'use-package-core
  (require 'use-package))

(with-eval-after-load 'use-package-ensure
  ;; The config is byte-compiled (M-x my/compile-config).  Normally use-package
  ;; then installs missing packages at *compile* time only, so a package added
  ;; later would never be installed.  Keep the check at load time instead.
  (define-advice use-package-handler/:ensure (:around (fn &rest args) at-load-time)
    (let ((byte-compile-current-file nil))
      (apply fn args)))
  ;; Safety net: if a package failed to install (offline, renamed on MELPA),
  ;; skip its whole block instead of leaving hooks that point at missing
  ;; code and break every buffer.  `:ensure' runs first, so on a normal
  ;; first start this check sees the freshly installed package.
  (add-to-list 'use-package-defaults
               '(:if
                 (lambda (name _args) `(my/package-p ',name))
                 (lambda (_name args)
                   (and (not (plist-member args :if))
                        (car (plist-get args :ensure)))))
               t))

;;;; Install-on-first-use (saves disk: rarely used packages only arrive
;;;; the first time you actually need them)
(defun my/lazy-install (package)
  "Install PACKAGE now.  Returns non-nil on success."
  (require 'package)
  (or (package-installed-p package)
      (condition-case err
          (progn
            (message "Installing %s (first use)..." package)
            (unless package-archive-contents (package-refresh-contents))
            (package-install package)
            (message "Installed %s" package)
            t)
        (error (message "Couldn't install %s: %s" package (error-message-string err))
               nil))))

(defmacro my/lazy-mode (regexp package &optional mode ts-mode ts-lang)
  "Open files matching REGEXP in MODE (default PACKAGE).
PACKAGE is installed the first time such a file is opened.  If TS-MODE is
given and the tree-sitter grammar TS-LANG is installed, TS-MODE (built into
Emacs) is used instead and nothing is installed at all."
  (let* ((mode (or mode package))
         (fn (intern (format "my/lazy-%s" mode))))
    `(progn
       (defun ,fn ()
         ,(format "Open in `%s', installing `%s' on first use." mode package)
         (interactive)
         (cond
          ,@(when ts-mode
              `(((and (fboundp ',ts-mode)
                      (fboundp 'treesit-language-available-p)
                      (treesit-language-available-p ',ts-lang))
                 (,ts-mode))))
          ((my/lazy-install ',package) (,mode))
          (t (prog-mode))))
       (add-to-list 'auto-mode-alist '(,regexp . ,fn)))))

(defmacro my/lazy-command (command package)
  "Make COMMAND install PACKAGE the first time it's called."
  `(unless (fboundp ',command)
     (defun ,command (&rest _)
       ,(format "Install `%s' on first use, then run `%s'." package command)
       (interactive)
       (fmakunbound ',command)
       (unless (my/lazy-install ',package)
         (user-error "Couldn't install %s" ',package))
       ;; Autoloads don't replace a stub that was already there, so load it.
       (unless (fboundp ',command) (require ',package nil t))
       (call-interactively ',command))))

(provide 'init-package)
;;; init-package.el ends here

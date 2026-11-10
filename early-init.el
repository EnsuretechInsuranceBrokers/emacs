;;; early-init.el --- Runs before the package system and the first frame -*- lexical-binding: t; -*-

;;; Commentary:
;; Everything here exists to make startup fast and stop the "white flash"
;; of an unstyled frame.  Keep it small: no packages are available yet.

;;; Code:

;;;; Garbage collector: off during startup, restored in init-perf.el.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;;;; File handlers: every `load'/`require' checks this alist with regexps.
;; Keep only the gzip handler (needed to load .el.gz) while starting up.
(defvar my--file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist
      (let (keep)
        (dolist (h file-name-handler-alist (nreverse keep))
          (when (eq (cdr h) 'jka-compr-handler)
            (push h keep)))))
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq file-name-handler-alist
                  (delete-dups (append file-name-handler-alist
                                       my--file-name-handler-alist))))
          101)

;;;; Packages
(setq package-enable-at-startup t
      package-quickstart t          ; one pre-generated autoloads file = faster boot
      load-prefer-newer noninteractive)

;;;; Native compilation: compile quietly in the background.
(when (featurep 'native-compile)
  (setq native-comp-async-report-warnings-errors 'silent
        native-comp-jit-compilation t))

;;;; UI: switch off chrome *before* the frame is drawn (cheaper than the modes).
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(horizontal-scroll-bars) default-frame-alist)
;; gruber-darker colours, so the first frame is already dark.
(push '(background-color . "#181818") default-frame-alist)
(push '(foreground-color . "#e4e4ef") default-frame-alist)
(setq menu-bar-mode nil
      tool-bar-mode nil
      scroll-bar-mode nil)

(setq frame-inhibit-implied-resize t   ; don't resize the frame when the font changes
      frame-resize-pixelwise t
      inhibit-startup-screen t
      inhibit-startup-echo-area-message user-login-name
      inhibit-x-resources t
      use-dialog-box nil
      use-file-dialog nil)

;;; early-init.el ends here

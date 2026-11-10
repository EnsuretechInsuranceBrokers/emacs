;;; init-perf.el --- Make Emacs feel instant -*- lexical-binding: t; -*-

;;; Commentary:
;; The speed of "flying" between buffers is mostly about never blocking:
;; no GC pauses while typing, no redisplay of things you cannot see,
;; and big reads from language servers.

;;; Code:

;;;; Garbage collection
(defconst my/gc-threshold (* 64 1024 1024)
  "GC threshold after startup.  Big enough to rarely GC, small enough to be quick.")

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold my/gc-threshold
                  gc-cons-percentage 0.1)))

;; Never GC while the minibuffer is open: completion allocates a lot and
;; a pause there is what makes C-x b feel sluggish.
(defun my/gc-defer () (setq gc-cons-threshold most-positive-fixnum))
(defun my/gc-restore ()
  (run-at-time 1 nil (lambda () (setq gc-cons-threshold my/gc-threshold))))
(add-hook 'minibuffer-setup-hook #'my/gc-defer)
(add-hook 'minibuffer-exit-hook #'my/gc-restore)

;; Collect while you are idle or looking at another window instead.
(run-with-idle-timer 10 t #'garbage-collect)
(add-function :after after-focus-change-function
              (lambda () (unless (frame-focus-state) (garbage-collect))))

;;;; Subprocesses (LSP servers, ripgrep, compilers)
(setq read-process-output-max (* 4 1024 1024)
      process-adaptive-read-buffering nil)

;;;; Redisplay
(setq fast-but-imprecise-scrolling t
      redisplay-skip-fontification-on-input t
      inhibit-compacting-font-caches t
      auto-window-vscroll nil
      highlight-nonselected-windows nil
      bidi-inhibit-bpa t)
(setq-default bidi-display-reordering 'left-to-right
              bidi-paragraph-direction 'left-to-right
              cursor-in-non-selected-windows nil)

;; Huge one-line files (minified JS, logs) won't freeze Emacs.
(global-so-long-mode 1)

;;;; Files
(setq vc-handled-backends '(Git)   ; don't probe for SVN/Hg/... on every file open
      auto-mode-case-fold nil      ; one pass over auto-mode-alist, not two
      ffap-machine-p-known 'reject ; don't ping hostnames in file-at-point
      find-file-visit-truename nil)

;;;; Report how fast we started.
(add-hook 'emacs-startup-hook
          (lambda ()
            (message "Emacs ready in %s with %d garbage collections."
                     (emacs-init-time "%.2fs") gcs-done)))

(provide 'init-perf)
;;; init-perf.el ends here

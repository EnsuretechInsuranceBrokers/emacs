;;; init-perf.el --- Make Emacs feel instant -*- lexical-binding: t; -*-

;;; Commentary:
;; The speed of "flying" between buffers is mostly about never blocking:
;; no GC pauses while typing, no redisplay of things you cannot see,
;; and big reads from language servers.

;;; Code:

;;;; Deferred loading: start instantly, load the rest when it's first needed
;; Most features don't need to exist before you press a key.  Modules add
;; functions to these hooks instead of turning things on at startup:
;;   `my/first-input-hook'  before the first command (key press)
;;   `my/first-file-hook'   when the first file is opened
;; Both also run after `my/warmup-delay' idle seconds, so by the time
;; you type, everything is usually loaded already.
(defvar my/first-input-hook nil "Run once, before the first command.")
(defvar my/first-file-hook nil "Run once, when the first file is visited.")

(defcustom my/warmup-delay 1.5
  "Idle seconds after startup before deferred features load anyway."
  :type 'number :group 'my)

(defvar my/first-input-done nil "Non-nil once `my/first-input-hook' has run.")
(defvar my/first-file-done nil "Non-nil once `my/first-file-hook' has run.")

(defun my/run-once-hook (hook)
  "Run HOOK's functions once, each protected so one failure can't stop the rest."
  (let ((fns (symbol-value hook)))
    (set hook nil)                       ; never run twice
    (set (if (eq hook 'my/first-input-hook) 'my/first-input-done 'my/first-file-done) t)
    (dolist (fn fns)
      (unless (eq fn t)
        (condition-case err (funcall fn)
          (error (message "Deferred %s failed: %s" fn (error-message-string err))))))))

(defun my/first-input ()
  (remove-hook 'pre-command-hook #'my/first-input)
  (my/run-once-hook 'my/first-input-hook))
(defun my/first-file ()
  (remove-hook 'find-file-hook #'my/first-file)
  (my/run-once-hook 'my/first-file-hook))

(defun my/on-first-input (fn)
  "Call FN at the first command, or now if that already happened."
  (if my/first-input-done (funcall fn) (add-hook 'my/first-input-hook fn)))

(add-hook 'pre-command-hook #'my/first-input -100)
(add-hook 'find-file-hook #'my/first-file -100)
(add-hook 'emacs-startup-hook
          (lambda ()
            (run-with-idle-timer my/warmup-delay nil
                                 (lambda () (my/first-file) (my/first-input)))))

;;;; Startup shortcuts
(setq initial-major-mode 'fundamental-mode ; *scratch* without running elisp mode hooks
      inhibit-default-init t               ; skip the system's default.el
      site-run-file nil)                   ; ...and site-start.el (packages come from package.el)
(unless (eq system-type 'darwin)
  (setq command-line-ns-option-alist nil))
(unless (memq initial-window-system '(x pgtk))
  (setq command-line-x-option-alist nil))

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
(setq jit-lock-stealth-time nil          ; never fontify unseen text in the background
      jit-lock-defer-time 0              ; fontify on the next redisplay, not while typing
      display-line-numbers-width-start t) ; size the number column once, no reflow

;; Big files: skip the heavy machinery (LSP, whitespace-mode, formatting)
;; and open C/C++ in our fast-c-mode.
(defcustom my/c-big-file-size (* 256 1024)
  "Files bigger than this many bytes count as \"big\".
Big C/C++ files open in `fast-c-mode' (see `my/c-mode') and skip the
language server, whitespace-mode and format-on-save."
  :type 'integer :group 'my)

(defun my/big-buffer-p ()
  "Non-nil if this buffer is too big for the heavy machinery."
  (> (buffer-size) my/c-big-file-size))

;; Really big files (logs, dumps, generated code, 1 MB+): also drop the
;; per-line extras.  Editing stays instant.
(defun my/huge-file-setup ()
  (when (> (buffer-size) (* 4 my/c-big-file-size))
    (dolist (mode '(display-line-numbers-mode diff-hl-mode hl-todo-mode
                    whitespace-mode flymake-mode show-paren-local-mode
                    electric-pair-local-mode yas-minor-mode hs-minor-mode))
      (when (and (boundp mode) (symbol-value mode)) (funcall mode -1)))
    (setq-local show-trailing-whitespace nil
                bidi-display-reordering nil
                line-move-visual nil)
    (message "Big file: line numbers, git gutter and extras off for speed")))
(add-hook 'find-file-hook #'my/huge-file-setup 90)
(setq large-file-warning-threshold (* 100 1024 1024))

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

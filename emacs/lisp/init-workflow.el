;;; init-workflow.el --- C mode choice, whitespace, paredit, small helpers -*- lexical-binding: t; -*-

;;; Commentary:
;; Workflow habits in the style of rexim/Tsoding streams, all written for
;; this config (nothing copied):
;;   fast-c-mode for huge C/C++ files   (lisp/fast-c-mode.el, our own)
;;   whitespace-mode in code buffers    `my/whitespace-style'
;;   paredit in Lisp buffers            `my/use-paredit'
;;   C-x C-g find file at point, C-c i m imenu, C-c m s / C-c m l magit,
;;   C-c M-q unfill paragraph, C-c C-j eval-print in elisp, C-c T timestamp,
;;   C-c s search the selection, copy file/buffer name, transparency toggle.

;;; Code:

(defcustom my/c-mode 'auto
  "Which major mode opens C and C++ files.
`auto': tree-sitter (or cc-mode) normally; `fast-c-mode' for files bigger
        than `my/c-big-file-size' (huge headers like sqlite3.c).
`fast': always `fast-c-mode'.  Instant on any file, simpler than cc-mode.
`cc':   never `fast-c-mode'."
  :type '(choice (const auto) (const fast) (const cc)) :group 'my)

(defcustom my/whitespace-style 'light
  "How much whitespace to draw in code buffers.
`dots':  every space as a dot, tabs as arrows, trailing space (the
         look from Tsoding's streams).
`light': tabs, trailing space and blank lines at the ends of the file.
nil:     nothing (trailing spaces are still highlighted in code)."
  :type '(choice (const dots) (const light) (const nil)) :group 'my)

(defcustom my/use-paredit t
  "Use paredit (structural editing) in Lisp buffers."
  :type 'boolean :group 'my)

;;;; C/C++: pick the mode per file
(autoload 'fast-c-mode "fast-c-mode" "Small, fast major mode for C/C++." t)

(defun my/c-auto-mode ()
  "Open a C/C++ file in the mode `my/c-mode' asks for."
  (interactive)
  (if (or (memq my/c-mode '(fast simpc))   ; `simpc' = old name
          (and (eq my/c-mode 'auto) (my/big-buffer-p)))
      (fast-c-mode)
    (let ((base (if (eq (my/c-like-kind-from-name) 'c++) 'c++-mode 'c-mode)))
      ;; Respect tree-sitter remapping (c-mode -> c-ts-mode) when it's set up.
      (funcall (if (fboundp 'major-mode-remap)
                   (major-mode-remap base)
                 (or (alist-get base major-mode-remap-alist) base))))))

;; Added last, so it wins over the plain c-mode/c-ts-mode entries.
(add-to-list 'auto-mode-alist
             '("\\.\\(?:[ch]\\|cc\\|cpp\\|cxx\\|c\\+\\+\\|hh\\|hpp\\|hxx\\|inl\\)\\'"
               . my/c-auto-mode))


;;;; Whitespace: show tabs and trailing space in code
(defconst my/whitespace-styles
  '((dots . (face tabs spaces trailing space-before-tab newline indentation
              empty space-after-tab space-mark tab-mark))
    (light . (face tabs trailing space-before-tab empty tab-mark)))
  "Styles for `my/whitespace-style'.")

(defun my/setup-whitespace ()
  "Turn on `whitespace-mode' with `my/whitespace-style'."
  (when-let* ((style (alist-get (if (eq my/whitespace-style 'rexim) 'dots my/whitespace-style)
                                 my/whitespace-styles)))
    (unless (my/big-buffer-p)
      (setq-local whitespace-style style
                  show-trailing-whitespace nil)  ; whitespace-mode draws it
      (whitespace-mode 1))))

(dolist (hook '(prog-mode-hook yaml-mode-hook yaml-ts-mode-hook markdown-mode-hook))
  (add-hook hook #'my/setup-whitespace))

;;;; Paredit for Lisps
(use-package paredit
  :if (and my/use-paredit (my/package-p 'paredit))
  :hook ((emacs-lisp-mode lisp-mode lisp-data-mode scheme-mode clojure-mode racket-mode)
         . my/paredit-on)
  :preface
  (defun my/paredit-on ()
    (electric-pair-local-mode -1)        ; paredit balances parens itself
    (paredit-mode 1))
  :config
  ;; Give M-s (search prefix) and M-? (find references) back to the rest
  ;; of the config; splice moves to C-c M-s.
  (keymap-unset paredit-mode-map "M-s" t)
  (keymap-unset paredit-mode-map "M-?" t)
  (keymap-set paredit-mode-map "C-c M-s" #'paredit-splice-sexp))

(add-hook 'emacs-lisp-mode-hook
          (lambda () (local-set-key (kbd "C-c C-j") #'eval-print-last-sexp)))
(add-to-list 'auto-mode-alist '("Cask\\'" . emacs-lisp-mode))

;;;; Small helpers
(defun my/buffer-file-name ()
  "File name of this buffer, or the directory in dired."
  (if (derived-mode-p 'dired-mode) default-directory buffer-file-name))

(defun my/copy-buffer-name ()
  "Put the buffer name on the clipboard."
  (interactive)
  (kill-new (buffer-name))
  (message "%s" (buffer-name)))

(defun my/copy-org-link-here ()
  "Copy an org link to this file and line, relative to the project root."
  (interactive)
  (let* ((file (or (my/buffer-file-name) (user-error "No file here")))
         (root (when-let* ((p (project-current))) (project-root p)))
         (link (format "file:%s::%d"
                       (if root (file-relative-name file root) file)
                       (line-number-at-pos))))
    (kill-new link)
    (message "%s" link)))

(defun my/unfill-paragraph ()
  "Join the paragraph at point into one line (the opposite of M-q)."
  (interactive)
  (let ((fill-column most-positive-fixnum))
    (fill-paragraph nil (region-active-p))))

(defun my/insert-timestamp ()
  "Insert a UTC timestamp like (20261110-130512)."
  (interactive)
  (insert (format-time-string "(%Y%m%d-%H%M%S)" nil t)))

(defun my/search-selection ()
  "Search the project for the selected text (or the symbol at point)."
  (interactive)
  (let ((text (if (use-region-p)
                  (buffer-substring-no-properties (region-beginning) (region-end))
                (thing-at-point 'symbol t))))
    (deactivate-mark)
    (consult-ripgrep nil text)))

(defvar my/frame-transparency 85 "Opacity used by `my/toggle-transparency'.")
(defun my/toggle-transparency ()
  "Toggle frame transparency."
  (interactive)
  (let* ((param (if (>= emacs-major-version 29) 'alpha-background 'alpha))
         (cur (frame-parameter nil param)))
    (set-frame-parameter nil param
                         (if (and cur (/= (if (consp cur) (car cur) cur) 100))
                             100
                           my/frame-transparency))))

(defun my/kill-autoloads-buffers ()
  "Kill the *-autoloads.el buffers package installs leave open."
  (interactive)
  (dolist (b (buffer-list))
    (when (string-match-p "-autoloads\\.el" (buffer-name b))
      (kill-buffer b))))

;;;; Keys for the helpers
(keymap-global-set "C-x C-g" #'find-file-at-point)
(keymap-global-set "C-c i m" #'consult-imenu)
(keymap-global-set "C-c m s" #'magit-status)
(keymap-global-set "C-c m l" #'magit-log)
(keymap-global-set "C-c M-q" #'my/unfill-paragraph)
(keymap-global-set "C-c T"   #'my/insert-timestamp)
(keymap-global-set "C-c s"   #'my/search-selection)

(provide 'init-workflow)
;;; init-workflow.el ends here

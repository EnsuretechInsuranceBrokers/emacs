;;; init-tools.el --- dired, terminal, docker, org, server -*- lexical-binding: t; -*-

;;; Code:

;;;; dired: the file manager.  C-x C-j opens it on the current file.
(use-package dired
  :ensure nil
  :defer t
  :bind (:map dired-mode-map
              ("-"   . dired-up-directory)       ; like vim-vinegar / oil
              ("C-c C-e" . wdired-change-to-wdired-mode)) ; rename files by editing text
  :config
  (setq dired-dwim-target t                      ; copy/move to the other dired window
        dired-recursive-copies 'always
        dired-recursive-deletes 'top
        dired-kill-when-opening-new-dired-buffer t ; one dired buffer, not fifty
        dired-auto-revert-buffer #'dired-directory-changed-p
        dired-vc-rename-file t
        dired-create-destination-dirs 'ask
        dired-clean-confirm-killing-deleted-buffers nil
        wdired-allow-to-change-permissions t))
;; Which `ls' dired uses, and its switches (GNU ls sorts directories first):
;; see init-platform.el.

(use-package dired-x
  :ensure nil
  :hook (dired-mode . dired-omit-mode)          ; C-x M-o shows hidden files again
  :config
  (setq dired-omit-files "\\`[.]?#\\|\\`\\.DS_Store\\'\\|\\`\\.\\.?\\'"
        dired-omit-verbose nil))

;;;; dired extensions: a full file manager
;;   TAB / S-TAB   expand a folder inline (tree), cycle depth    dired-subtree
;;   P             preview the file under the cursor             dired-preview
;;   / (F in Vim)  filter the listing as you type                dired-narrow
;;   )             last git commit next to each file             dired-git-info
;;   E             open in the system app (open / xdg-open)      init-platform.el
;;   (             show / hide details (size, date, permissions)
;;   colours by file type (diredfl), icons (nerd-icons-dired),
;;   copy/move in the background (async), drag files out to other apps.
(setq dired-mouse-drag-files t                      ; drag files from dired into other apps
      mouse-drag-and-drop-region-cross-program t)
(add-hook 'dired-mode-hook #'dired-hide-details-mode) ; just names; ( shows the rest

(defcustom my/dired-icons t
  "File-type icons in dired (nerd-icons).  setup.sh installs the icon font."
  :type 'boolean :group 'my)

(defvar my/open-command "xdg-open"
  "Program that opens a file in its default app.  Set in init-platform.el.")
(defun my/dired-open-externally ()
  "Open the marked files (or the one under the cursor) in their default app."
  (interactive)
  (dolist (file (dired-get-marked-files))
    (call-process my/open-command nil 0 nil file)))

(use-package diredfl                                 ; colours: dirs, executables, dates...
  :hook (dired-mode . diredfl-mode))

(use-package dired-subtree                           ; folders open in place, as a tree
  :after dired
  :bind (:map dired-mode-map
              ("TAB"       . dired-subtree-toggle)
              ("<tab>"     . dired-subtree-toggle)
              ("<backtab>" . dired-subtree-cycle))
  :config (setq dired-subtree-use-backgrounds nil))  ; keep gruber-darker's background

(use-package dired-narrow                            ; type to filter, RET to keep, g to undo
  :after dired
  :bind (:map dired-mode-map ("/" . dired-narrow-fuzzy)))

(use-package dired-preview                           ; P: preview files as you move
  :after dired
  :bind (:map dired-mode-map ("P" . dired-preview-mode))
  :config
  ;; Videos, music, archives and PDFs are skipped (dired-preview's default list).
  (setq dired-preview-delay 0.25
        dired-preview-max-size (* 10 1024 1024)))    ; never preview anything over 10 MB

(use-package dired-git-info                          ; ): last commit message per file
  :after dired
  :bind (:map dired-mode-map (")" . dired-git-info-mode))
  :config (setq dgi-auto-hide-details-p nil))

(use-package async                                   ; big copies/moves don't freeze Emacs
  :after dired
  :config (dired-async-mode 1))

(use-package nerd-icons-dired
  :if (and my/dired-icons (my/package-p 'nerd-icons-dired))
  :hook (dired-mode . nerd-icons-dired-mode))

(with-eval-after-load 'dired
  (keymap-set dired-mode-map "E" #'my/dired-open-externally))

;; Vim keys: evil-collection sets up dired's normal-state keys, then this
;; adds the extensions (/ is Vim search there, so filtering is F).
(with-eval-after-load 'evil-collection
  (add-hook 'evil-collection-setup-hook
            (lambda (mode _keymaps)
              (when (eq mode 'dired)
                (evil-define-key 'normal dired-mode-map
                  (kbd "TAB")       #'dired-subtree-toggle
                  (kbd "<tab>")     #'dired-subtree-toggle
                  (kbd "<backtab>") #'dired-subtree-cycle
                  "F" #'dired-narrow-fuzzy
                  "P" #'dired-preview-mode
                  ")" #'dired-git-info-mode
                  "E" #'my/dired-open-externally)))))

;;;; Terminal
;; vterm is a real terminal (needs cmake + libtool to build the first time).
(use-package vterm
  :if (and module-file-suffix (not (eq system-type 'windows-nt)) (my/package-p 'vterm))
  :commands (vterm vterm-other-window)
  :config
  (setq vterm-max-scrollback 10000
        vterm-kill-buffer-on-exit t
        vterm-timer-delay 0.01))

(defun my/terminal ()
  "Open a terminal in the project root: vterm if available, else eshell."
  (interactive)
  (let ((default-directory (my/project-root)))
    (if (fboundp 'vterm)
        (vterm (format "*vterm %s*" (file-name-nondirectory
                                     (directory-file-name default-directory))))
      (eshell t))))

;;;; Docker UI: installed the first time you run M-x docker.
(my/lazy-command docker docker)

;;;; Org
(use-package org
  :ensure nil
  :defer t
  :bind (("C-c o a" . org-agenda)
         ("C-c o c" . org-capture)
         ("C-c o l" . org-store-link))
  :config
  (setq org-directory "~/org/"
        org-agenda-files (list org-directory)
        org-default-notes-file (expand-file-name "inbox.org" org-directory)
        org-startup-indented t
        org-return-follows-link t
        org-hide-emphasis-markers t
        org-src-fontify-natively t
        org-src-tab-acts-natively t
        org-src-preserve-indentation t
        org-edit-src-content-indentation 0
        org-log-done 'time
        org-capture-templates
        '(("t" "Todo" entry (file "") "* TODO %?\n  %U\n  %a")
          ("n" "Note" entry (file "") "* %?\n  %U"))))
(setq org-directory "~/org/")

;;;; Autocommit: git-backed notes (rexim's autocommit idea).  See my-autocommit.el.
;; M-x my/autocommit-init RET ~/org/ RET once; every save is then committed and pushed.
(require 'my-autocommit)

;;;; Server: `emacsclient file.c' opens in this Emacs instantly.
;; For zero startup time run Emacs as a daemon: `emacs --daemon', then
;; `emacsclient -c' (alias it as `e').
(when my/start-server
  (add-hook 'my/first-input-hook
            (lambda ()
              (require 'server)
              (unless (or (daemonp) (server-running-p))
                (server-start)))))

(provide 'init-tools)
;;; init-tools.el ends here

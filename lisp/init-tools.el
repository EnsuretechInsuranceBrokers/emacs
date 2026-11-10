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
        wdired-allow-to-change-permissions t)
  ;; GNU ls for "directories first" (on macOS: brew install coreutils).
  (let ((gls (executable-find "gls")))
    (when (and (eq system-type 'darwin) gls)
      (setq insert-directory-program gls)))
  (setq dired-listing-switches
        (if (or (not (eq system-type 'darwin)) (executable-find "gls"))
            "-alh --group-directories-first"
          "-alh")))

(use-package dired-x
  :ensure nil
  :hook (dired-mode . dired-omit-mode)          ; C-x M-o shows hidden files again
  :config
  (setq dired-omit-files "\\`[.]?#\\|\\`\\.DS_Store\\'\\|\\`\\.\\.?\\'"
        dired-omit-verbose nil))

;;;; Terminal
;; vterm is a real terminal (needs cmake + libtool to build the first time).
(use-package vterm
  :if (and module-file-suffix (not (eq system-type 'windows-nt)))
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

;;;; Docker
(use-package docker :commands docker)

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

;;;; Server: `emacsclient file.c' opens in this Emacs instantly.
;; For zero startup time run Emacs as a daemon: `emacs --daemon', then
;; `emacsclient -c' (alias it as `e').
(when my/start-server
  (add-hook 'after-init-hook
            (lambda ()
              (require 'server)
              (unless (or (daemonp) (server-running-p))
                (server-start)))))

(provide 'init-tools)
;;; init-tools.el ends here

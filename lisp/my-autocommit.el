;;; my-autocommit.el --- Commit (and push) a git repo every time you save -*- lexical-binding: t; -*-

;;; Commentary:
;; For notes, agendas, journals: folders you want backed up and synced
;; without ever thinking about git.  Same idea as rexim's autocommit-rc.el,
;; written from scratch:
;;
;;   - Saves are debounced: ten saves in a row make one commit.
;;   - git runs in the background; Emacs never blocks.
;;   - It pulls once when you first open a file in the repo.
;;   - It only commits when something actually changed.
;;   - `my/autocommit-init' adds itself to an existing .dir-locals.el
;;     instead of overwriting it.
;;
;; Setup, once per repo:  M-x my/autocommit-init RET ~/org/ RET
;; Go offline (commit, don't push):  M-x my/autocommit-toggle-push
;; Output of the last git run:  the buffer " *autocommit*"

;;; Code:

(defgroup my/autocommit nil "Commit on save." :group 'my)

(defcustom my/autocommit-delay 5
  "Seconds after the last save before committing."
  :type 'number)

(defcustom my/autocommit-push t
  "Push after committing.  Toggle with `my/autocommit-toggle-push'."
  :type 'boolean)

(defcustom my/autocommit-pull t
  "Run `git pull --rebase --autostash' the first time a repo is visited."
  :type 'boolean)

(defvar my/autocommit--timers (make-hash-table :test #'equal) "root -> pending timer")
(defvar my/autocommit--running (make-hash-table :test #'equal) "root -> t while git runs")
(defvar my/autocommit--pulled (make-hash-table :test #'equal) "root -> t once pulled")

(defun my/autocommit--root ()
  "Root of the git repo of this buffer, or nil."
  (when-let* ((dir (locate-dominating-file default-directory ".git")))
    (file-name-as-directory (file-truename dir))))

(defun my/autocommit--git (root script on-done)
  "Run shell SCRIPT in ROOT; call ON-DONE with the exit code."
  (let* ((default-directory root)
         (buf (get-buffer-create " *autocommit*"))
         (proc (start-file-process-shell-command "autocommit" buf script)))
    (with-current-buffer buf
      (goto-char (point-max))
      (insert (format "\n$ cd %s && %s\n" root script)))
    (set-process-sentinel
     proc
     (lambda (p _event)
       (when (memq (process-status p) '(exit signal))
         (funcall on-done (process-exit-status p)))))))

(defun my/autocommit--commit (root)
  "Commit everything in ROOT (and push), unless git is already busy there."
  (remhash root my/autocommit--timers)
  (if (gethash root my/autocommit--running)
      (my/autocommit--schedule root)   ; try again after the current run
    (puthash root t my/autocommit--running)
    (my/autocommit--git
     root
     (concat "git add -A && "
             "if git diff --cached --quiet; then echo 'nothing to commit'; else "
             "git commit -q -m " (shell-quote-argument
                                  (format-time-string "Autocommit %Y-%m-%d %H:%M:%S"))
             (if my/autocommit-push " && git push -q" "")
             "; fi")
     (lambda (code)
       (remhash root my/autocommit--running)
       (if (zerop code)
           (message "Autocommit%s: %s" (if my/autocommit-push "" " [offline]")
                    (abbreviate-file-name root))
         (message "Autocommit FAILED in %s (see buffer \" *autocommit*\")"
                  (abbreviate-file-name root)))))))

(defun my/autocommit--schedule (root)
  "Commit ROOT after `my/autocommit-delay' seconds of quiet."
  (when-let* ((old (gethash root my/autocommit--timers)))
    (cancel-timer old))
  (puthash root (run-with-timer my/autocommit-delay nil #'my/autocommit--commit root)
           my/autocommit--timers))

(defun my/autocommit--after-save ()
  (when-let* ((root (my/autocommit--root)))
    (my/autocommit--schedule root)))

(defun my/autocommit--pull-once (root)
  (when (and my/autocommit-pull my/autocommit-push
             (not (gethash root my/autocommit--pulled)))
    (puthash root t my/autocommit--pulled)
    (message "Autocommit: pulling %s..." (abbreviate-file-name root))
    (my/autocommit--git
     root "git pull -q --rebase --autostash"
     (lambda (code)
       (if (zerop code)
           (progn
             (message "Autocommit: %s is up to date" (abbreviate-file-name root))
             ;; Refresh any buffers the pull changed.
             (dolist (b (buffer-list))
               (with-current-buffer b
                 (when (and buffer-file-name (not (buffer-modified-p))
                            (string-prefix-p root (file-truename buffer-file-name)))
                   (revert-buffer t t t)))))
         (message "Autocommit: pull failed in %s (offline?)" (abbreviate-file-name root)))))))

;;;###autoload
(define-minor-mode my/autocommit-mode
  "Commit (and push) this buffer's git repo shortly after every save."
  :lighter " AC"
  (if my/autocommit-mode
      (if-let* ((root (my/autocommit--root)))
          (progn
            (add-hook 'after-save-hook #'my/autocommit--after-save nil t)
            (auto-revert-mode 1)
            (my/autocommit--pull-once root))
        (setq my/autocommit-mode nil)
        (message "Autocommit: %s is not inside a git repo" default-directory))
    (remove-hook 'after-save-hook #'my/autocommit--after-save t)))

;; Let .dir-locals.el turn the mode on without a "risky variable" prompt.
(add-to-list 'safe-local-eval-forms '(my/autocommit-mode 1))

;;;###autoload
(defun my/autocommit-toggle-push ()
  "Switch between committing+pushing (online) and committing only (offline)."
  (interactive)
  (setq my/autocommit-push (not my/autocommit-push))
  (message "Autocommit: %s" (if my/autocommit-push "ONLINE (commit + push)" "OFFLINE (commit only)")))

;;;###autoload
(defun my/autocommit-init (dir)
  "Turn on autocommit for every file under DIR (writes DIR/.dir-locals.el).
Existing settings in .dir-locals.el are kept."
  (interactive "DAutocommit directory: ")
  (let* ((file (expand-file-name dir-locals-file dir))
         (form '(eval . (my/autocommit-mode 1)))
         (alist (when (file-exists-p file)
                  (with-temp-buffer
                    (insert-file-contents file)
                    (ignore-errors (read (current-buffer))))))
         (all (assq nil alist)))
    (unless (file-directory-p (expand-file-name ".git" dir))
      (unless (y-or-n-p (format "%s is not a git repo. Run git init? " dir))
        (user-error "Aborted"))
      (let ((default-directory (file-name-as-directory dir)))
        (call-process "git" nil nil nil "init")))
    (if (member form (cdr all))
        (message "Autocommit already enabled in %s" file)
      (if all
          (setcdr all (cons form (cdr all)))
        (setq alist (cons (list nil form) alist)))
      (with-temp-file file
        (insert ";;; Directory Local Variables -*- no-byte-compile: t -*-\n")
        (pp alist (current-buffer)))
      (message "Autocommit enabled for %s (reopen files there)" dir))))

(provide 'my-autocommit)
;;; my-autocommit.el ends here

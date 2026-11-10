;;; init-git.el --- Magit and the change gutter -*- lexical-binding: t; -*-

;;; Code:

(use-package magit
  :bind (("C-x g"   . magit-status)
         ("C-c g b" . magit-blame-addition)
         ("C-c g l" . magit-log-buffer-file)
         ("C-c g f" . magit-file-dispatch))
  :config
  (setq magit-diff-refine-hunk 'all                ; word-level diff highlights
        magit-save-repository-buffers 'dontask
        magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1
        magit-bury-buffer-function #'magit-restore-window-configuration
        magit-no-confirm '(stage-all-changes unstage-all-changes)
        git-commit-summary-max-length 72)
  ;; Big repos: these status sections are slow and rarely needed.
  (remove-hook 'magit-status-sections-hook #'magit-insert-tags-header)
  (remove-hook 'magit-status-headers-hook #'magit-insert-tags-header))

;; Fringe marks for added/changed/deleted lines (Doom's vc-gutter).
(use-package diff-hl
  :hook ((prog-mode conf-mode text-mode) . diff-hl-mode)
  :hook (dired-mode . diff-hl-dired-mode)
  :hook (magit-pre-refresh . diff-hl-magit-pre-refresh)
  :hook (magit-post-refresh . diff-hl-magit-post-refresh)
  :bind (("C-c g n" . diff-hl-next-hunk)
         ("C-c g p" . diff-hl-previous-hunk)
         ("C-c g r" . diff-hl-revert-hunk)
         ("C-c g s" . diff-hl-show-hunk))
  :config
  (setq diff-hl-draw-borders nil
        diff-hl-update-async t)              ; diff in a thread, never block typing
  (diff-hl-flydiff-mode 1)
  (unless (display-graphic-p) (diff-hl-margin-mode 1)))

(provide 'init-git)
;;; init-git.el ends here

;;; init-editing.el --- Editing power tools -*- lexical-binding: t; -*-

;;; Commentary:
;; rexim's classics: multiple-cursors, move-text, duplicate line.
;; Plus expand-region, visual undo tree, snippets, folding.

;;; Code:

;;;; Multiple cursors, like VSCode (and rexim's bindings)
;;   Option-click / Alt-click   add (or remove) a cursor        [init-platform.el]
;;   Cmd-Opt-Up/Down / C-M-Up/Down  add a cursor above/below    [init-platform.el]
;;   Shift-Option-drag / Shift-Alt-drag  box select -> a cursor per line [init-platform.el]
;;   C-S-click        add a cursor (same on every system)
;;   C-S-c C-S-c      a cursor on every line of the selection (rexim's favourite)
;;   C-> / C-<        add a cursor at the next / previous match (VSCode Ctrl+D)
;;   C-c C-<          a cursor at every match (VSCode Ctrl+Shift+L)
;;   C-" / C-:        skip this match
;;   Esc or C-g       back to one cursor.  RET inserts a newline at every cursor.
;; With Vim keys on, multiple cursors type in Emacs state and go back to
;; normal mode when you're done (multiple-cursors doesn't work in normal mode).
(use-package multiple-cursors
  :bind (("C-S-c C-S-c" . mc/edit-lines)
         ("C->"         . mc/mark-next-like-this)
         ("C-<"         . mc/mark-previous-like-this)
         ("C-c C-<"     . mc/mark-all-like-this)
         ("C-\""        . mc/skip-to-next-like-this)
         ("C-:"         . mc/skip-to-previous-like-this)
         ("C-S-<mouse-1>" . mc/add-cursor-on-click))
  :config
  (keymap-set mc/keymap "<escape>" #'mc/keyboard-quit)
  (keymap-unset mc/keymap "<return>" t)       ; RET types a newline everywhere, like VSCode
  (add-hook 'multiple-cursors-mode-enabled-hook #'my/mc-evil-enter)
  (add-hook 'multiple-cursors-mode-disabled-hook #'my/mc-evil-leave))

(defvar-local my/mc-evil-previous-state nil)
(defun my/mc-evil-enter ()
  "Multiple cursors start: type in Emacs state (Vim normal mode can't drive them)."
  (when (bound-and-true-p evil-local-mode)
    (setq my/mc-evil-previous-state evil-state)
    (evil-emacs-state)))
(defun my/mc-evil-leave ()
  "Multiple cursors end: back to where Vim was (insert stays insert, else normal)."
  (when (and (bound-and-true-p evil-local-mode) my/mc-evil-previous-state)
    (evil-change-state (if (eq my/mc-evil-previous-state 'insert) 'insert 'normal))
    (setq my/mc-evil-previous-state nil)))

(defun my/mouse-column-cursors (event)
  "Drag a box selection, then put a cursor on each line (VSCode Shift-Alt-drag)."
  (interactive "e")
  (mouse-drag-region-rectangle event)
  (when (and (region-active-p)
             (/= (line-number-at-pos (region-beginning))
                 (line-number-at-pos (region-end))))
    (condition-case nil
        (progn (rectangle-mark-mode -1) (mc/edit-lines))
      (error nil))))                          ; no multiple-cursors: keep the box selection

;;;; Move lines/regions up and down (rexim: M-p / M-n)
(use-package move-text
  :bind (("M-p" . move-text-up)
         ("M-n" . move-text-down))
  :config
  ;; Re-indent after moving so code stays tidy.
  (defun my/indent-after-move (&rest _)
    (let ((deactivate deactivate-mark))
      (if (region-active-p)
          (indent-region (region-beginning) (region-end))
        (indent-region (line-beginning-position) (line-end-position)))
      (setq deactivate-mark deactivate)))
  (advice-add 'move-text-up :after #'my/indent-after-move)
  (advice-add 'move-text-down :after #'my/indent-after-move))

;;;; Duplicate line or region (rexim: C-,).  Built into Emacs 29.
(keymap-global-set "C-," #'duplicate-dwim)
(setq duplicate-line-final-position 1)  ; Emacs 30+: cursor lands on the copy

;;;; Grow the selection by syntax: word -> string -> expression -> function.
(use-package expreg
  :bind (("C-=" . expreg-expand)
         ("C-+" . expreg-contract)))

;;;; Undo: C-/ undo, C-? redo, C-x u visual undo tree.
(use-package vundo
  :bind ("C-x u" . vundo)
  :config (setq vundo-glyph-alist vundo-unicode-symbols))

;;;; Snippets: type a keyword, TAB.  Your own go in snippets/.
(use-package yasnippet
  :hook ((prog-mode text-mode conf-mode) . yas-minor-mode)
  :config
  (add-to-list 'yas-snippet-dirs (expand-file-name "snippets" user-emacs-directory))
  (yas-reload-all))
;; (yasnippet-snippets, thousands of generic snippets, is left out: ~6 MB
;; you'd rarely use.  M-x package-install yasnippet-snippets to add it.)

;;;; Folding (hideshow).  C-c f toggles the block at point, C-c F all.
;; hideshow errors in modes without comment syntax, so turn it on carefully.
(defun my/hs-minor-mode-maybe ()
  (ignore-errors (hs-minor-mode 1)))
(add-hook 'prog-mode-hook #'my/hs-minor-mode-maybe)
(defun my/toggle-fold-all ()
  "Fold every block, or unfold all if something is folded."
  (interactive)
  (if (seq-some (lambda (o) (overlay-get o 'hs)) (overlays-in (point-min) (point-max)))
      (hs-show-all)
    (hs-hide-all)))

;;;; Small commands
(defun my/kill-region-or-word ()
  "Kill the region if active, else the word before point (like a shell's C-w)."
  (interactive)
  (if (use-region-p)
      (kill-region (region-beginning) (region-end))
    (backward-kill-word 1)))

(defun my/open-line-below ()
  "Open a new indented line below, like Vim's o."
  (interactive)
  (end-of-line) (newline-and-indent))

(defun my/open-line-above ()
  "Open a new indented line above, like Vim's O."
  (interactive)
  (beginning-of-line) (newline) (forward-line -1) (indent-according-to-mode))

(defun my/copy-file-path ()
  "Copy the current file's path (or directory in dired)."
  (interactive)
  (let ((path (or buffer-file-name default-directory)))
    (kill-new path)
    (message "Copied %s" path)))

(defun my/sudo-edit ()
  "Reopen the current file as root."
  (interactive)
  (find-alternate-file (concat "/sudo::" (or buffer-file-name default-directory))))

;; Editor settings from .editorconfig files (built into Emacs 30).
(use-package editorconfig
  :demand t
  :config (editorconfig-mode 1))

(provide 'init-editing)
;;; init-editing.el ends here

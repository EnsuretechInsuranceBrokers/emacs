;;; init-navigation.el --- Fly between buffers, windows, files -*- lexical-binding: t; -*-

;;; Commentary:
;; The short version of "how Tsoding moves so fast":
;;   C-x b      switch buffer (type 2-3 letters, RET)   -- consult-buffer
;;   C-x C-f    open file, DEL climbs a directory       -- vertico-directory
;;   C-x C-j    dired of the current file's directory
;;   C-x p f    file in this project
;;   M-o        next window (C-u M-o: pick by letter)
;;   C-;        jump to any visible spot by typing 2 chars -- avy
;;   C-c b      toggle back to the previous buffer
;;   M-g i      jump to a function in this file
;; Everything is one or two keystrokes and never asks for confirmation.

;;; Code:

;;;; Windows
(use-package ace-window
  :bind (("M-o" . ace-window))
  :config
  ;; With two windows M-o just swaps, with more it shows home-row letters.
  (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)
        aw-scope 'frame
        aw-dispatch-always nil))

;; S-<arrow> moves to the window in that direction.
(windmove-default-keybindings 'shift)
(setq windmove-wrap-around t)
;; Org uses S-<arrow> itself; fall back to windmove where org has nothing to do.
(with-eval-after-load 'org
  (add-hook 'org-shiftup-final-hook #'windmove-up)
  (add-hook 'org-shiftdown-final-hook #'windmove-down)
  (add-hook 'org-shiftleft-final-hook #'windmove-left)
  (add-hook 'org-shiftright-final-hook #'windmove-right))

(defun my/split-and-follow-below ()
  "Split the window below and move into it."
  (interactive) (select-window (split-window-below)))
(defun my/split-and-follow-right ()
  "Split the window right and move into it."
  (interactive) (select-window (split-window-right)))

;;;; Buffers
(defun my/switch-to-last-buffer ()
  "Toggle between the current and the previous buffer."
  (interactive)
  (switch-to-buffer (other-buffer (current-buffer) t)))

(defun my/kill-other-buffers ()
  "Kill every file buffer except the current one."
  (interactive)
  (dolist (b (buffer-list))
    (when (and (buffer-file-name b) (not (eq b (current-buffer))))
      (kill-buffer b)))
  (message "Killed other file buffers"))

(use-package ibuffer
  :ensure nil
  :bind ("C-x C-b" . ibuffer)
  :config
  (setq ibuffer-expert t                       ; no "really kill?" prompts
        ibuffer-show-empty-filter-groups nil))

;; Group the ibuffer list by project.
(use-package ibuffer-project
  :preface
  (defun my/ibuffer-group-by-project ()
    (setq ibuffer-filter-groups (ibuffer-project-generate-filter-groups)))
  :hook (ibuffer . my/ibuffer-group-by-project))

;;;; Jump anywhere on screen
(use-package avy
  :bind (("C-;"   . avy-goto-char-timer)  ; type 1-2 chars, pause, pick a letter
         ("M-j"   . avy-goto-char-timer)  ; same, works in terminals
         ("M-g w" . avy-goto-word-1)
         ("M-g l" . avy-goto-line)
         :map isearch-mode-map
         ("C-;"   . avy-isearch))         ; jump to any isearch match
  :config
  (setq avy-timeout-seconds 0.25
        avy-style 'at-full
        avy-all-windows t
        avy-background nil))

;;;; Projects (built-in project.el; C-x p is the prefix)
(use-package project
  :ensure nil
  :defer t
  :config
  ;; Also treat these as project roots, even without git.
  (setq project-vc-extra-root-markers
        '(".project" "go.mod" "composer.json" "package.json" "Cargo.toml"
          "Makefile" "build.sh" "nob.c")
        project-switch-commands
        '((project-find-file "File" ?f)
          (consult-ripgrep "Grep" ?g)
          (project-dired "Dired" ?d)
          (magit-project-status "Magit" ?m)
          (project-compile "Compile" ?c)
          (project-eshell "Eshell" ?e)))
  (keymap-set project-prefix-map "g" #'consult-ripgrep)
  (keymap-set project-prefix-map "m" #'magit-project-status))

;;;; Navigation inside a buffer
(defun my/smart-beginning-of-line ()
  "Go to the first non-blank char; press again to go to column 0."
  (interactive "^")
  (let ((orig (point)))
    (back-to-indentation)
    (when (= orig (point))
      (move-beginning-of-line 1))))

(setq imenu-auto-rescan t
      imenu-max-item-length 160
      set-mark-command-repeat-pop t     ; C-u C-SPC C-SPC C-SPC walks back the mark ring
      mark-ring-max 32
      global-mark-ring-max 64)

(provide 'init-navigation)
;;; init-navigation.el ends here

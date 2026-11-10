;;; init-keys.el --- Global keys and the SPC / C-c SPC leader -*- lexical-binding: t; -*-

;;; Commentary:
;; Plain Emacs: the leader is C-c SPC (and the C-c <key> shortcuts below).
;; Evil:        the leader is SPC in normal/visual mode, M-SPC everywhere.
;; The leader is the same map either way, laid out like Doom.

;;; Code:

;;;; Global keys (plain Emacs, also work under evil in insert/emacs state)
(keymap-global-set "C-a"     #'my/smart-beginning-of-line)
(keymap-global-set "C-w"     #'my/kill-region-or-word)
(keymap-global-set "C-x k"   #'kill-current-buffer)     ; no "which buffer?" prompt
(keymap-global-set "C-x K"   #'my/kill-other-buffers)
(keymap-global-set "C-x 2"   #'my/split-and-follow-below)
(keymap-global-set "C-x 3"   #'my/split-and-follow-right)
(keymap-global-set "C-c b"   #'my/switch-to-last-buffer)
(keymap-global-set "C-c c"   #'compile)
(keymap-global-set "C-c r"   #'recompile)               ; your SPC r
(keymap-global-set "C-c x"   #'my/run-file)             ; your SPC m r
(keymap-global-set "C-c i"   #'my/cp-open-input)
(keymap-global-set "C-c t"   #'my/terminal)
(keymap-global-set "C-c d d" #'dape)
(keymap-global-set "C-c d b" #'dape-breakpoint-toggle)
(keymap-global-set "C-c f"   #'hs-toggle-hiding)
(keymap-global-set "C-c F"   #'my/toggle-fold-all)
(keymap-global-set "C-c R"   #'rename-visited-file)
(keymap-global-set "C-c y"   #'my/copy-file-path)
(keymap-global-set "C-c e"   #'eval-buffer)
(keymap-global-set "C-o"     #'my/open-line-below)
(keymap-global-set "C-S-o"   #'my/open-line-above)
(keymap-global-set "M-z"     #'zap-up-to-char)
(keymap-global-set "M-/"     #'hippie-expand)
(keymap-global-set "C-x C-z" #'ignore)                  ; no accidental suspend
(keymap-global-set "<f5>"    #'my/compile-dwim)
(keymap-global-set "C-c ="   #'my/font-bigger)
(keymap-global-set "C-c -"   #'my/font-smaller)
(keymap-global-set "<escape>" #'keyboard-escape-quit)   ; Esc gets you out of anything

;;;; Leader map (Doom layout)
(defvar-keymap my/leader-buffer-map
  :doc "SPC b"
  "b" #'consult-buffer   "k" #'kill-current-buffer  "K" #'my/kill-other-buffers
  "i" #'ibuffer          "r" #'revert-buffer-quick  "s" #'save-buffer
  "l" #'my/switch-to-last-buffer)

(defvar-keymap my/leader-file-map
  :doc "SPC f"
  "f" #'find-file        "r" #'consult-recent-file  "s" #'save-buffer
  "R" #'rename-visited-file "D" #'delete-file       "y" #'my/copy-file-path
  "u" #'my/sudo-edit     "p" (lambda () (interactive) (find-file user-init-file)))

(defvar-keymap my/leader-search-map
  :doc "SPC s"
  "s" #'consult-line     "S" #'consult-line-multi   "p" #'consult-ripgrep
  "d" (lambda () (interactive) (consult-ripgrep default-directory))
  "i" #'consult-imenu    "I" #'consult-imenu-multi  "g" #'consult-git-grep
  "f" #'consult-find     "o" #'consult-outline      "r" #'query-replace-regexp)

(defvar-keymap my/leader-code-map
  :doc "SPC c"
  "c" #'compile          "r" #'eglot-rename         "a" #'eglot-code-actions
  "f" #'eglot-format-buffer "F" #'my/toggle-format-on-save
  "o" #'eglot-code-action-organize-imports
  "d" #'xref-find-definitions "D" #'xref-find-references
  "x" #'consult-flymake  "e" #'eval-buffer          "k" #'kill-compilation)

(defvar-keymap my/leader-git-map
  :doc "SPC g"
  "g" #'magit-status     "b" #'magit-blame-addition "l" #'magit-log-buffer-file
  "f" #'magit-file-dispatch "n" #'diff-hl-next-hunk "p" #'diff-hl-previous-hunk
  "r" #'diff-hl-revert-hunk "s" #'diff-hl-show-hunk)

(defvar-keymap my/leader-open-map
  :doc "SPC o"
  "t" #'my/terminal      "T" #'vterm-other-window   "d" #'dired-jump
  "-" #'dired-jump       "e" #'eshell               "D" #'docker
  "a" #'org-agenda       "c" #'org-capture)

(defvar-keymap my/leader-window-map
  :doc "SPC w"
  "w" #'ace-window       "s" #'my/split-and-follow-below
  "v" #'my/split-and-follow-right "d" #'delete-window "o" #'delete-other-windows
  "h" #'windmove-left    "j" #'windmove-down        "k" #'windmove-up
  "l" #'windmove-right   "u" #'winner-undo          "r" #'winner-redo
  "=" #'balance-windows)

(defvar-keymap my/leader-debug-map
  :doc "SPC d"
  "d" #'dape             "b" #'dape-breakpoint-toggle)

(defvar-keymap my/leader-local-map
  :doc "SPC m  (local leader)"
  "r" #'my/run-file      "i" #'my/cp-open-input     "c" #'compile)

(defvar-keymap my/leader-map
  :doc "Doom-style leader.  SPC (evil) or C-c SPC (Emacs)."
  "SPC" #'project-find-file
  "."   #'find-file
  ","   #'consult-buffer
  "<"   #'consult-buffer
  "/"   #'consult-ripgrep
  "*"   (lambda () (interactive) (consult-ripgrep nil (thing-at-point 'symbol)))
  ":"   #'execute-extended-command
  ";"   #'eval-expression
  "TAB" #'my/switch-to-last-buffer
  "`"   #'my/switch-to-last-buffer
  "r"   #'recompile                       ; your `SPC r'
  "u"   #'universal-argument
  "x"   #'scratch-buffer
  "p"   project-prefix-map                ; SPC p a = artisan, SPC p f, SPC p p ...
  "b"   my/leader-buffer-map
  "f"   my/leader-file-map
  "s"   my/leader-search-map
  "c"   my/leader-code-map
  "g"   my/leader-git-map
  "o"   my/leader-open-map
  "w"   my/leader-window-map
  "d"   my/leader-debug-map
  "m"   my/leader-local-map
  "h"   help-map
  "q"   #'save-buffers-kill-terminal)

(keymap-global-set "C-c SPC" my/leader-map)

(with-eval-after-load 'evil
  (evil-define-key '(normal visual motion) 'global (kbd "SPC") my/leader-map)
  (keymap-global-set "M-SPC" my/leader-map)        ; leader from insert state too
  (evil-define-key 'normal 'global (kbd "-") #'dired-jump))

(provide 'init-keys)
;;; init-keys.el ends here

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
(keymap-global-set "C-c i i" #'my/cp-open-input)          ; C-c i m = imenu (rexim)
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

;;;; M-w with nothing selected copies the whole line (like Vim's yy)
(defun my/copy-region-or-line ()
  "Copy the region, or the current line if nothing is selected."
  (interactive)
  (if (use-region-p)
      (kill-ring-save (region-beginning) (region-end))
    (kill-ring-save (line-beginning-position) (line-beginning-position 2))
    (pulse-momentary-highlight-one-line (point))
    (message "Copied line")))
(keymap-global-set "M-w" #'my/copy-region-or-line)

;;;; Vim <-> Emacs keys
(defun my/toggle-evil ()
  "Switch between Vim keys (evil) and plain Emacs keys, everywhere.
Good for practising Emacs keys for a while, then going back."
  (interactive)
  (cond ((not (featurep 'evil))
         (setq my/use-evil t)
         (require 'init-evil)
         (message (if (bound-and-true-p evil-mode) "Vim keys ON" "evil could not be loaded")))
        ((bound-and-true-p evil-mode)
         (evil-mode -1)
         (message "Emacs keys ON.  C-c v brings Vim keys back.  Cheat sheet: C-c SPC ?"))
        (t (evil-mode 1)
           (message "Vim keys ON"))))
(keymap-global-set "C-c v" #'my/toggle-evil)

(defconst my/vim-to-emacs-table
  "Vim / Neovim            Emacs                          What
──────────────────────  ─────────────────────────────  ──────────────────────────────
h j k l                 C-b C-n C-p C-f                move
w  b  e                 M-f  M-b                       word forward / back
0  ^  $                 C-a (again: column 0)  C-e      line start / end
gg  G                   M-<  M->                       top / bottom of file
:42  42G                M-g g 42                       go to line
C-d  C-u                C-v  M-v                       page down / up
zz                      C-l (again: top, bottom)       center the screen
{  }                    M-{  M-}                       paragraph back / forward
%                       C-M-f  C-M-b                   jump over brackets
f x  /  t x             M-j (avy)  or  C-s x RET       jump to a character
/foo  ?foo  n  N        C-s foo  C-r foo  C-s  C-r     search (press again = next)
*                       M-s .                          search the word under the cursor
i  a  o  O              just type   C-o  C-S-o         insert (Emacs has no modes)
v                       C-SPC                          start a selection
C-v (block)             C-x SPC                        rectangle selection
x                       C-d                            delete character
dd                      C-S-<backspace>                delete line
D  C                    C-k                            delete to end of line
dw  db                  M-d  M-<backspace>             delete word
yy                      M-w (nothing selected)         copy line            [this config]
y (visual)              M-w                            copy selection
p                       C-y  (then M-y to cycle)       paste
u  C-r                  C-/  C-?                       undo / redo
.                       C-x z (then z z z)             repeat last command
qa ... q   @a           F3 ... F4   F4                 record / play macro
:%s/a/b/g               M-%  (C-M-% for regexp)        replace (! = all)
>>  <<                  C-x TAB, then arrows           indent / dedent
gcc  gc                 C-x C-;   M-;                  comment line / selection
~                       M-c  M-u  M-l                  capitalize / upper / lower word
J                       C-u M-^                        join with next line
ma  'a                  C-x r SPC a   C-x r j a        set / jump to a mark
C-o                     C-u C-SPC                      jump back
gd   C-o                M-.   M-,                      go to definition / back
:w   :q   :wq           C-x C-s   C-x k   C-x C-c      save / close / quit
:e file                 C-x C-f                        open file
:b name   :ls           C-x b   C-x C-b                switch / list buffers
:sp  :vs                C-x 2   C-x 3                  split
C-w w   C-w o   C-w q   M-o   C-x 1   C-x 0            other / only / close window
Esc                     C-g                            cancel anything
:term                   C-c t                          terminal

Practise:  C-z  = Emacs keys in this buffer only (C-z again to go back)
           C-c v = Emacs keys everywhere (C-c v again to go back)
           In insert mode the Emacs keys already work: C-a C-e C-k M-f M-b ...
           C-h k <key> tells you what any key does."
  "Cheat sheet shown by `my/vim-to-emacs'.")

(defun my/vim-to-emacs ()
  "Show the Vim -> Emacs key cheat sheet."
  (interactive)
  (with-current-buffer (get-buffer-create "*Vim -> Emacs*")
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert my/vim-to-emacs-table "\n")
      (goto-char (point-min))
      (special-mode)))
  (pop-to-buffer "*Vim -> Emacs*"))

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

(defvar-keymap my/leader-toggle-map
  :doc "SPC t"
  "e" #'my/toggle-evil           "f" #'my/toggle-format-on-save
  "w" #'whitespace-mode          "l" #'display-line-numbers-mode
  "t" #'my/toggle-transparency   "r" #'read-only-mode
  "v" #'visual-line-mode         "c" #'my/autocommit-mode)

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
  "t"   my/leader-toggle-map
  "?"   #'my/vim-to-emacs
  "h"   help-map
  "q"   #'save-buffers-kill-terminal)

;; `my/leader-prefix' is the leader as a prefix command, so other files can
;; bind it before or after this one loads (init-evil binds SPC to it).
(defalias 'my/leader-prefix my/leader-map)
(keymap-global-set "C-c SPC" 'my/leader-prefix)
(with-eval-after-load 'evil
  (keymap-global-set "M-SPC" 'my/leader-prefix))   ; leader from insert state too

(provide 'init-keys)
;;; init-keys.el ends here

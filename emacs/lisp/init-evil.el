;;; init-evil.el --- Vim keys, tuned for moving from Neovim to Emacs -*- lexical-binding: t; -*-

;;; Commentary:
;; On by default (`my/use-evil').  Set up so you can learn Emacs keys
;; gradually instead of all at once:
;;
;;   - Normal/visual mode is Vim, with a Doom-style SPC leader.
;;   - INSERT mode uses Emacs keys: C-a/C-e line start/end, C-k kill to end,
;;     C-n/C-p/C-f/C-b move, M-f/M-b words, C-y paste...  You pick them up
;;     while typing, without losing Vim.
;;   - C-z flips the current buffer to pure Emacs keys and back.
;;   - C-c v (SPC t e) turns Vim keys off/on everywhere: practice mode.
;;   - SPC ? shows a Vim -> Emacs cheat sheet.
;;
;; When you don't need Vim any more: (setq my/use-evil nil) in personal.el.

;;; Code:

(use-package evil
  :demand t
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil          ; evil-collection handles other modes
        evil-want-C-u-scroll t            ; C-u / C-d scroll like Vim
        evil-want-C-d-scroll t
        evil-want-Y-yank-to-eol t         ; Y = y$ (Neovim default)
        evil-want-fine-undo t             ; from your Doom config
        evil-undo-system 'undo-redo       ; u / C-r, built in
        evil-disable-insert-state-bindings t ; Emacs keys while typing
        evil-split-window-below t
        evil-vsplit-window-right t
        evil-symbol-word-search t         ; * searches foo_bar, not foo
        evil-respect-visual-line-mode t
        evil-search-module 'evil-search   ; n/N, :s, gn like Vim
        evil-ex-search-vim-style-regexp t
        evil-ex-substitute-global nil
        evil-kill-on-visual-paste nil     ; pasting over a selection keeps the register
        evil-shift-width 4
        evil-echo-state nil               ; the cursor shape says the state
        evil-normal-state-cursor '(box)
        evil-insert-state-cursor '(bar)
        evil-visual-state-cursor '(hollow)
        evil-emacs-state-cursor '(bar)
        evil-mode-line-format '(before . mode-line-front-space))
  :config
  (evil-mode 1)
  ;; Buffers where Vim keys get in the way.
  (dolist (mode '(vterm-mode eshell-mode term-mode))
    (evil-set-initial-state mode 'emacs))
  ;; Neovim-isms
  (evil-define-key 'normal 'global
    (kbd "-") #'dired-jump)                ; vim-vinegar / oil.nvim
  (evil-define-key '(normal visual) 'global
    (kbd "C-;") #'avy-goto-char-timer      ; like flash.nvim / leap
    (kbd "gs")  #'avy-goto-char-timer)
  (evil-ex-define-cmd "W" #'evil-write)    ; :W typo
  (evil-ex-define-cmd "Q" #'evil-quit))

(use-package evil-collection               ; Vim keys in magit, dired, help, ...
  :defer t
  ;; ~50 ms to set up, so it waits for the first key press (or idle warm-up).
  :init (my/on-first-input (lambda () (require 'evil-collection)))
  :config
  (setq evil-collection-want-unimpaired-p t ; ]b [b ]q [q, like vim-unimpaired
        evil-collection-setup-minibuffer nil)
  (evil-collection-init))

(use-package evil-surround                  ; cs"' / ysiw) / ds(  (nvim-surround)
  :after evil
  :demand t
  :config (global-evil-surround-mode 1))

(use-package evil-commentary                ; gcc comments a line, gc in visual
  :after evil
  :demand t
  :config (evil-commentary-mode 1))

;;;; SPC leader that wins over other modes' SPC (magit, dired, help...)
(defvar my/leader-mode-map (make-sparse-keymap)
  "Keymap of `my/leader-mode'.")

(define-minor-mode my/leader-mode
  "Make SPC the leader in Vim normal/visual/motion state everywhere."
  :global t
  :group 'my
  :keymap my/leader-mode-map)

(with-eval-after-load 'evil
  ;; Minor-mode maps beat the per-major-mode maps evil-collection sets up.
  (evil-define-key '(normal visual motion) my/leader-mode-map
    (kbd "SPC") 'my/leader-prefix)       ; defined in init-keys.el
  (my/leader-mode 1))

(provide 'init-evil)
;;; init-evil.el ends here

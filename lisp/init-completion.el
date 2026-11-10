;;; init-completion.el --- Minibuffer and in-buffer completion -*- lexical-binding: t; -*-

;;; Commentary:
;; This is the engine behind fast buffer flying:
;;   vertico     vertical candidate list in the minibuffer (like ido, but for everything)
;;   orderless   type words in any order: "init comp" finds init-completion.el
;;   marginalia  extra info next to candidates (file size, docstring, mode)
;;   consult     search/switch commands with live preview
;;   embark      act on the candidate under point (C-.)
;;   corfu+cape  popup completion while typing code

;;; Code:

(setq completion-ignore-case t
      read-buffer-completion-ignore-case t
      read-file-name-completion-ignore-case t
      completions-detailed t)

;;;; Minibuffer
(use-package vertico
  :demand t
  :config
  (setq vertico-cycle t
        vertico-count 15
        vertico-resize nil
        vertico-scroll-margin 2)
  ;; Sorted by history (savehist): recently used things float to the top.
  (vertico-mode 1))

;; Ido-style file navigation: DEL on "~/src/" goes up a whole directory,
;; and typing "~/" or "/" after a path jumps there.
(use-package vertico-directory
  :ensure nil                           ; ships inside vertico
  :after vertico
  :bind (:map vertico-map
              ("RET"   . vertico-directory-enter)
              ("DEL"   . vertico-directory-delete-char)
              ("M-DEL" . vertico-directory-delete-word))
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

(use-package orderless
  :demand t
  :config
  ;; "foo bar" = both words, any order.  Prefix a word with ! to exclude
  ;; it, ~ for flex (ido-style "icmp" -> "init-completion"), ^ to anchor.
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles basic partial-completion)))
        orderless-matching-styles '(orderless-literal orderless-regexp orderless-initialism)))

(use-package marginalia
  :demand t
  :bind (:map minibuffer-local-map ("M-A" . marginalia-cycle))
  :config (marginalia-mode 1))

(use-package consult
  :bind (;; Buffers & files
         ("C-x b"   . consult-buffer)              ; buffers + recent files + bookmarks
         ("C-x 4 b" . consult-buffer-other-window)
         ("C-x 5 b" . consult-buffer-other-frame)
         ("C-x p b" . consult-project-buffer)
         ("C-x r b" . consult-bookmark)
         ("C-x C-r" . consult-recent-file)
         ;; Jumping inside a buffer
         ("M-g g"   . consult-goto-line)           ; with live preview
         ("M-g M-g" . consult-goto-line)
         ("M-g i"   . consult-imenu)               ; functions in this file
         ("M-g I"   . consult-imenu-multi)         ; ...in all project buffers
         ("M-g o"   . consult-outline)
         ("M-g m"   . consult-mark)
         ("M-g e"   . consult-compile-error)
         ("M-g f"   . consult-flymake)
         ;; Searching
         ("M-s l"   . consult-line)                ; search this buffer
         ("M-s L"   . consult-line-multi)          ; search all buffers
         ("M-s r"   . consult-ripgrep)             ; search project (needs rg)
         ("M-s g"   . consult-git-grep)
         ("M-s f"   . consult-find)
         ("M-s k"   . consult-keep-lines)
         ;; Kill ring / registers / misc
         ("M-y"     . consult-yank-pop)
         ("C-x r r" . consult-register)
         ("C-c h"   . consult-history)
         ("C-c k"   . consult-kmacro)
         ("C-c M-x" . consult-mode-command)
         :map isearch-mode-map
         ("M-s l"   . consult-line)                ; promote isearch to consult-line
         :map minibuffer-local-map
         ("M-s"     . consult-history)
         ("M-r"     . consult-history))
  :init
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref
        register-preview-delay 0.3
        register-preview-function #'consult-register-format)
  :config
  (setq consult-narrow-key "<"          ; C-x b < b = only buffers, < f = files, < p = project
        consult-preview-key '(:debounce 0.15 any)
        consult-line-start-from-top nil)
  (when (executable-find "fd")
    (keymap-global-set "M-s f" #'consult-fd))
  ;; Previewing a buffer that is already open is instant; previewing a file
  ;; means opening it.  For the "file" commands, preview only on M-.
  (consult-customize consult-ripgrep consult-git-grep consult-grep
                     consult-recent-file consult-bookmark consult-find
                     :preview-key "M-."))

(use-package embark
  :bind (("C-."   . embark-act)     ; "what can I do with this?"
         ("C-M-." . embark-dwim)    ; M-. stays xref "go to definition"
         ("C-h B" . embark-bindings))
  :init
  (setq prefix-help-command #'embark-prefix-help-command))
;; In a consult-ripgrep list: C-. E exports results to a grep buffer;
;; with wgrep (C-c C-p) you can then edit all matches at once.
(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))
(use-package wgrep
  :defer t
  :config (setq wgrep-auto-save-buffer t))

;;;; In-buffer completion (replaces company)
(use-package corfu
  :demand t
  :bind (:map corfu-map
              ("TAB"     . corfu-next)
              ([tab]     . corfu-next)
              ("S-TAB"   . corfu-previous)
              ([backtab] . corfu-previous)
              ("M-SPC"   . corfu-insert-separator))
  :config
  (setq corfu-auto t
        corfu-auto-delay 0.1             ; your company-idle-delay
        corfu-auto-prefix 2              ; your company-minimum-prefix-length
        corfu-cycle t
        corfu-preselect 'prompt
        corfu-quit-no-match 'separator
        corfu-on-exact-match nil
        corfu-popupinfo-delay '(0.5 . 0.2))
  (global-corfu-mode 1)
  (corfu-history-mode 1)
  (corfu-popupinfo-mode 1)
  (add-to-list 'savehist-additional-variables 'corfu-history))

;; Emacs < 31 cannot draw child frames in a terminal; this draws the popup with text.
(use-package corfu-terminal
  :if (< emacs-major-version 31)
  :after corfu
  :config (corfu-terminal-mode 1))

(use-package cape
  :demand t
  :config
  ;; Fallbacks after the mode's own completion (LSP, elisp...).
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-dabbrev 90))

(setq tab-always-indent 'complete
      text-mode-ispell-word-completion nil)

(provide 'init-completion)
;;; init-completion.el ends here

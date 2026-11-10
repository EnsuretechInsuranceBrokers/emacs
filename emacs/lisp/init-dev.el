;;; init-dev.el --- LSP (eglot), tree-sitter, diagnostics, formatting -*- lexical-binding: t; -*-

;;; Commentary:
;; eglot is built in and much lighter than lsp-mode: no UI widgets, no
;; lenses, no breadcrumb.  Same speed settings as your Doom lsp-mode
;; block, with symbol highlighting, lenses and inlay hints off.
;;
;; Language servers to install yourself:
;;   C/C++   clangd
;;   Go      gopls (+ gofumpt)          go install golang.org/x/tools/gopls@latest
;;   PHP     intelephense               npm i -g intelephense
;;   Python  basedpyright or pyright    pip install basedpyright
;;   JS/TS   typescript-language-server npm i -g typescript-language-server typescript
;;   Nix     nil or nixd

;;; Code:

;;;; Tree-sitter: faster, more accurate highlighting for each language.
;; treesit-auto picks the *-ts-mode when a grammar is installed and
;; offers to install grammars the first time (needs a C compiler).
(use-package treesit-auto
  :demand t
  :config
  (setq treesit-auto-install 'prompt
        ;; Only grammars for languages you actually use (each is 0.5-5 MB).
        treesit-auto-langs '(c cpp go gomod python javascript typescript tsx
                             php json yaml bash rust toml css html dockerfile
                             cmake lua))
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode 1))

;;;; eglot
(defconst my/eglot-modes
  '(c-mode c-ts-mode c++-mode c++-ts-mode
    go-mode go-ts-mode go-mod-ts-mode
    python-mode python-ts-mode
    js-mode js-ts-mode typescript-ts-mode tsx-ts-mode
    php-mode php-ts-mode
    fast-c-mode
    rust-mode rust-ts-mode zig-mode haskell-mode lua-mode lua-ts-mode)
  "Major modes that start a language server automatically.
If the server is not installed eglot prints one warning and the buffer
works as normal.")

(defun my/eglot-maybe-ensure ()
  "Start eglot for local file buffers (not scratch, remote or huge files)."
  (when (and buffer-file-name
             (not (file-remote-p buffer-file-name))
             (not (my/big-buffer-p)))
    (eglot-ensure)))

(dolist (mode my/eglot-modes)
  (add-hook (intern (format "%s-hook" mode)) #'my/eglot-maybe-ensure))

(use-package eglot
  :ensure nil
  :defer t
  :bind (:map eglot-mode-map
              ("C-c l a" . eglot-code-actions)
              ("C-c l r" . eglot-rename)
              ("C-c l f" . eglot-format-buffer)
              ("C-c l o" . eglot-code-action-organize-imports)
              ("C-c l i" . eglot-find-implementation)
              ("C-c l t" . eglot-find-typeDefinition)
              ("C-c l d" . eldoc-doc-buffer)
              ("C-c l R" . eglot-reconnect))
  :config
  (setq eglot-autoshutdown t                 ; kill the server with the last buffer
        eglot-sync-connect nil               ; never block opening a file
        eglot-connect-timeout 30
        eglot-send-changes-idle-time 0.3     ; your lsp-idle-delay
        eglot-extend-to-xref t               ; M-. into a library stays in the same server
        eglot-report-progress nil
        eglot-ignored-server-capabilities
        '(:documentHighlightProvider         ; lsp-enable-symbol-highlighting nil
          :codeLensProvider                  ; lsp-lens-enable nil
          :inlayHintProvider
          :documentOnTypeFormattingProvider))
  ;; lsp-log-io nil: don't keep a log of every JSON message.
  (if (boundp 'eglot-events-buffer-config)
      (setq eglot-events-buffer-config '(:size 0 :format full))
    (setq eglot-events-buffer-size 0))
  (with-eval-after-load 'jsonrpc
    (fset #'jsonrpc--log-event #'ignore))

  ;; PHP: intelephense first (Laravel friendly), phpactor as fallback.
  (add-to-list 'eglot-server-programs
               `((php-mode php-ts-mode)
                 . ,(eglot-alternatives '(("intelephense" "--stdio")
                                          ("phpactor" "language-server")))))
  (add-to-list 'eglot-server-programs
               `((python-mode python-ts-mode)
                 . ,(eglot-alternatives '(("basedpyright-langserver" "--stdio")
                                          ("pyright-langserver" "--stdio")
                                          "pylsp" "ruff-lsp"))))
  (add-to-list 'eglot-server-programs
               '((c-mode c-ts-mode c++-mode c++-ts-mode (fast-c-mode :language-id "c"))
                 . ("clangd" "--background-index" "--clang-tidy"
                    "--header-insertion=never" "--completion-style=detailed"
                    "-j=4")))

  ;; Go: gofumpt formatting + the analyses from your Doom config.
  (setq-default eglot-workspace-configuration
                '(:gopls (:gofumpt t
                          :usePlaceholders t
                          :staticcheck t
                          :analyses (:nilness t :shadow t :unusedparams t
                                     :unusedwrite t :useany t))
                  :intelephense (:files (:maxSize 5000000)))))

;; Show docs in the echo area, one line only (lsp-signature-doc-lines 1).
(setq eldoc-echo-area-use-multiline-p nil
      eldoc-idle-delay 0.2
      eldoc-echo-area-display-truncation-message nil)

;;;; Diagnostics: flymake (eglot feeds it).
(use-package flymake
  :ensure nil
  :defer t
  :bind (:map flymake-mode-map
              ("C-c ! n" . flymake-goto-next-error)
              ("C-c ! p" . flymake-goto-prev-error)
              ("C-c ! l" . consult-flymake)
              ("C-c ! b" . flymake-show-buffer-diagnostics)
              ("C-c ! P" . flymake-show-project-diagnostics))
  :config
  (setq flymake-no-changes-timeout 0.5       ; your flycheck-idle-change-delay
        flymake-fringe-indicator-position 'right-fringe
        flymake-suppress-zero-counters t))
(add-hook 'emacs-lisp-mode-hook
          (lambda () (when buffer-file-name (flymake-mode 1))))

;;;; Format on save (apheleia: async, keeps point, skips missing formatters).
(use-package apheleia
  :hook (my/first-file . apheleia-global-mode)
  :config
  ;; C/C++: only format when the project has a .clang-format.  Otherwise
  ;; clang-format's default style would rewrite your whole file on save.
  (setf (alist-get 'fast-c-mode apheleia-mode-alist) 'clang-format)
  (defun my/apheleia-inhibit-p ()
    (or (my/big-buffer-p)
        (and (my/c-like-kind)
             (not (locate-dominating-file default-directory ".clang-format")))))
  (add-hook 'apheleia-inhibit-functions #'my/apheleia-inhibit-p)
  ;; gofumpt if installed, otherwise gofmt.
  (when (executable-find "gofumpt")
    (setf (alist-get 'go-mode apheleia-mode-alist) 'gofumpt
          (alist-get 'go-ts-mode apheleia-mode-alist) 'gofumpt)))

(defun my/toggle-format-on-save ()
  "Turn format-on-save on/off in this buffer."
  (interactive)
  (apheleia-mode 'toggle)
  (message "Format on save: %s" (if apheleia-mode "on" "off")))

;;;; Go: organize imports on save (your lsp-organize-imports hook).
(defun my/eglot-organize-imports ()
  (when (and (fboundp 'eglot-managed-p) (eglot-managed-p))
    (ignore-errors (eglot-code-action-organize-imports (point-min) (point-max)))))
(dolist (hook '(go-mode-hook go-ts-mode-hook))
  (add-hook hook (lambda () (add-hook 'before-save-hook #'my/eglot-organize-imports -10 t))))

;;;; Debugger (DAP).  M-x dape, or SPC d d / C-c d d.
;; Installed the first time you run it (saves disk if you never debug).
(my/lazy-command dape dape)
(my/lazy-command dape-breakpoint-toggle dape)
(with-eval-after-load 'dape
  (setq dape-buffer-window-arrangement 'right
        dape-inlay-hints t))

;;;; direnv / nix-shell environments per project.
(use-package envrc
  :if (and (executable-find "direnv") (my/package-p 'envrc))
  :hook (after-init . envrc-global-mode))

;;;; Evaluate elisp with an inline result overlay (Doom's eval +overlay).
(use-package eros
  :hook (emacs-lisp-mode . eros-mode))

(provide 'init-dev)
;;; init-dev.el ends here

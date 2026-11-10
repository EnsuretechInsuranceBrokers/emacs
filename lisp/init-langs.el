;;; init-langs.el --- Per-language settings -*- lexical-binding: t; -*-

;;; Code:

;;;; C / C++
(setq c-default-style '((java-mode . "java") (awk-mode . "awk") (other . "k&r"))
      c-basic-offset 4
      c-ts-mode-indent-offset 4
      c-ts-mode-indent-style 'k&r)
(with-eval-after-load 'cc-mode
  (keymap-set c-mode-base-map "C-c C-o" #'ff-find-other-file)) ; .c <-> .h
(with-eval-after-load 'c-ts-mode
  (keymap-set c-ts-base-mode-map "C-c C-o" #'ff-find-other-file))

;;;; Go (tabs, like gofmt)
(use-package go-mode :defer t)
(setq go-ts-mode-indent-offset 4)
(dolist (hook '(go-mode-hook go-ts-mode-hook))
  (add-hook hook (lambda () (setq-local indent-tabs-mode t tab-width 4))))

;;;; Python
(setq python-indent-guess-indent-offset-verbose nil
      python-indent-offset 4)

;;;; JavaScript / TypeScript / JSON
(setq js-indent-level 2
      typescript-ts-mode-indent-offset 2
      json-ts-mode-indent-offset 2)

;;;; PHP / Laravel
(use-package php-mode
  :defer t
  :config (setq php-mode-coding-style 'psr2))

;; Blade templates, HTML, Vue, etc.
(use-package web-mode
  :mode ("\\.blade\\.php\\'" "\\.html?\\'" "\\.vue\\'" "\\.twig\\'"
         "\\.tpl\\'" "\\.erb\\'" "\\.jsx\\'" "\\.svelte\\'")
  :config
  (setq web-mode-markup-indent-offset 2
        web-mode-css-indent-offset 2
        web-mode-code-indent-offset 2
        web-mode-enable-auto-pairing nil      ; electric-pair does this
        web-mode-enable-current-element-highlight t
        web-mode-engines-alist '(("blade" . "\\.blade\\."))))

;;;; Markdown
(use-package markdown-mode
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'" . markdown-mode))
  :config
  (setq markdown-fontify-code-blocks-natively t
        markdown-command (if (executable-find "pandoc") "pandoc" "markdown")))

;;;; Config formats
(use-package yaml-mode :defer t)
(use-package nix-mode :mode "\\.nix\\'")
(use-package dockerfile-mode :defer t)
(add-to-list 'auto-mode-alist '("\\.env\\'" . conf-mode))
(add-to-list 'auto-mode-alist '("\\.env\\..*\\'" . conf-mode))

;;;; More languages.  Each one costs nothing until you open such a file.
;; Turn the whole group off with (setq my/extra-languages nil) in personal.el.
(defcustom my/extra-languages t
  "Install modes for Rust, Zig, Lua, Haskell, Kotlin, GLSL, CMake, TOML..."
  :type 'boolean :group 'my)

(when my/extra-languages
  (use-package rust-mode :defer t
    :config (setq rust-format-on-save nil))      ; apheleia formats with rustfmt
  (use-package zig-mode :defer t)
  (use-package lua-mode :defer t)
  (use-package haskell-mode :defer t
    :hook (haskell-mode . interactive-haskell-mode))
  (use-package kotlin-mode :defer t)
  (use-package glsl-mode :defer t)
  (use-package cmake-mode :defer t)
  (use-package csv-mode :defer t)
  (use-package nginx-mode :defer t)
  (use-package graphviz-dot-mode :defer t))   ; TOML, Bash, CSS...: tree-sitter modes via treesit-auto

;;;; Shell
(setq sh-basic-offset 4)
(add-hook 'after-save-hook #'executable-make-buffer-file-executable-if-script-p)

;;;; Emacs Lisp
(add-hook 'emacs-lisp-mode-hook (lambda () (setq-local tab-width 8)))

(provide 'init-langs)
;;; init-langs.el ends here

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

;;;; Go (tabs, like gofmt).  go-ts-mode is built in; go-mode only without the grammar.
(my/lazy-mode "\\.go\\'" go-mode nil go-ts-mode go)
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

;;;; Everything else: installed the first time you open such a file.
;; Built-in tree-sitter modes are used when the grammar is there, so most of
;; these never install anything.  `my/extra-languages' nil = don't even try.
(defcustom my/extra-languages t
  "Open (and install on first use) modes for less common languages."
  :type 'boolean :group 'my)

(add-to-list 'auto-mode-alist '("\\.env\\'" . conf-mode))
(add-to-list 'auto-mode-alist '("\\.env\\..*\\'" . conf-mode))

(when my/extra-languages
  (my/lazy-mode "\\.ya?ml\\'" yaml-mode nil yaml-ts-mode yaml)
  (my/lazy-mode "\\(?:Dockerfile\\|Containerfile\\)\\(?:\\..*\\)?\\'" dockerfile-mode nil dockerfile-ts-mode dockerfile)
  (my/lazy-mode "\\.rs\\'" rust-mode nil rust-ts-mode rust)
  (my/lazy-mode "\\.lua\\'" lua-mode nil lua-ts-mode lua)
  (my/lazy-mode "\\.nix\\'" nix-mode)
  (my/lazy-mode "\\.zig\\'" zig-mode)
  (my/lazy-mode "\\.hs\\'" haskell-mode)
  (my/lazy-mode "\\.kts?\\'" kotlin-mode)
  (my/lazy-mode "\\.\\(?:glsl\\|vert\\|frag\\|geom\\|comp\\)\\'" glsl-mode)
  (my/lazy-mode "\\.[ct]sv\\'" csv-mode)
  (my/lazy-mode "/nginx/.*\\.conf\\'" nginx-mode)
  (my/lazy-mode "\\.\\(?:dot\\|gv\\)\\'" graphviz-dot-mode)
  (with-eval-after-load 'rust-mode (setq rust-format-on-save nil)) ; apheleia formats
  (add-hook 'haskell-mode-hook #'interactive-haskell-mode))
;; TOML, Bash, CSS, CMake, JSON...: built-in tree-sitter modes via treesit-auto.

;;;; Shell
(setq sh-basic-offset 4)
(add-hook 'after-save-hook #'executable-make-buffer-file-executable-if-script-p)

;;;; Emacs Lisp
(add-hook 'emacs-lisp-mode-hook (lambda () (setq-local tab-width 8)))

(provide 'init-langs)
;;; init-langs.el ends here

;;; init-langs.el --- Per-language settings -*- lexical-binding: t; -*-

;;; Code:

;;;; C / C++
(setq c-default-style '((java-mode . "java") (awk-mode . "awk") (other . "k&r"))
      c-basic-offset 4
      c-ts-mode-indent-offset 4
      c-ts-mode-indent-style 'k&r)
(add-to-list 'auto-mode-alist '("\\.h\\'" . c-mode))   ; .h is C unless you say otherwise
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

;;;; Shell
(setq sh-basic-offset 4)
(add-hook 'after-save-hook #'executable-make-buffer-file-executable-if-script-p)

;;;; Emacs Lisp
(add-hook 'emacs-lisp-mode-hook (lambda () (setq-local tab-width 8)))

(provide 'init-langs)
;;; init-langs.el ends here

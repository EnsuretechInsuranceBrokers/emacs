;;; init.el -*- lexical-binding: t; -*-
;; Doom version of this config (the main one is the vanilla config in the
;; repo root).  To use it: link this folder to ~/.config/doom, run `doom sync'.
;; Lean module list.  Re-enable anything you need later (rust, zig, haskell...).

(doom! :completion
       (corfu +orderless)     ; faster than company, same feel
       vertico

       :ui
       doom
       doom-dashboard
       hl-todo
       modeline
       ophints
       (popup +defaults)
       (vc-gutter +pretty)
       vi-tilde-fringe
       workspaces

       :editor
       (evil +everywhere)
       file-templates
       fold
       (format +onsave)
       multiple-cursors
       snippets

       :emacs
       dired
       electric
       ibuffer
       undo
       vc

       :term
       vterm

       :checkers
       syntax

       :tools
       docker
       editorconfig
       (eval +overlay)
       lookup
       lsp
       magit
       tree-sitter

       :os
       (:if (featurep :system 'macos) macos)   ; IS-MAC is deprecated

       :lang
       (cc +lsp +tree-sitter)
       emacs-lisp
       (go +lsp +tree-sitter)
       (javascript +lsp +tree-sitter)
       json
       markdown
       nix
       org
       (php +lsp +tree-sitter)
       (python +lsp +tree-sitter)
       sh
       (web +lsp +tree-sitter)
       yaml

       :config
       (default +bindings +smartparens))

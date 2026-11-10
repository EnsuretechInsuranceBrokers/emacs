;;; init-platform.el --- macOS / Fedora settings: switch by (un)commenting -*- lexical-binding: t; -*-

;;; Commentary:
;;
;;   ##################################################################
;;   ##  THIS FILE IS SET UP FOR macOS.                              ##
;;   ##                                                              ##
;;   ##  ON FEDORA (or any Linux), do ONE of these:                  ##
;;   ##    a) run:   ./setup.sh --platform fedora                    ##
;;   ##       (setup.sh also does this by itself on Linux)           ##
;;   ##    b) by hand, in this file:                                 ##
;;   ##       1. comment out every line between                      ##
;;   ##            >>> MACOS BEGIN   and   <<< MACOS END             ##
;;   ##          (put ";; " in front of each line)                   ##
;;   ##       2. uncomment every line between                        ##
;;   ##            >>> FEDORA BEGIN  and   <<< FEDORA END            ##
;;   ##          (remove the ";; " in front of each line)            ##
;;   ##       3. restart Emacs                                       ##
;;   ##                                                              ##
;;   ##  Evil tip: select the block with V, then gc toggles comments.  ##
;;   ##  Emacs keys: select the block, then M-; toggles comments.      ##
;;   ##  M-x my/doctor says which block is active.                   ##
;;   ##################################################################
;;
;; This is the ONLY file with platform-specific settings.  Every other file
;; works on both systems unchanged.  The two blocks have the same settings
;; in the same order, so you can compare them line by line.
;; Inside a block every line is code (notes go at the end of the line), so
;; commenting/uncommenting a whole block never breaks anything.

;;; Code:

(defvar my/platform nil
  "Which block of init-platform.el is active: `macos' or `fedora'.")
(defvar my/exec-path-from-shell nil
  "Copy PATH and friends from your login shell (needed for GUI Emacs on macOS).")

;;;; >>> MACOS BEGIN ==================================================== macOS
(setq my/platform 'macos)
(setq my/font-size 16)                           ; Retina: 16pt looks like rexim's 20 on Linux
(setq mac-command-modifier 'meta                 ; Cmd = Meta (M-x is Cmd-x), like Alt on Linux
      mac-option-modifier 'super                 ; Option = Super (s-...)
      mac-right-option-modifier 'none            ; right Option still types é ü ñ
      mac-function-modifier 'hyper)              ; fn = Hyper
(setq ns-use-proxy-icon nil                      ; no file icon in the title bar
      ns-pop-up-frames nil                       ; open files from Finder in this frame
      ns-use-native-fullscreen nil               ; instant fullscreen, no slow Space animation
      frame-resize-pixelwise t)
(add-to-list 'default-frame-alist '(ns-transparent-titlebar . t)) ; title bar = theme colour
(add-to-list 'default-frame-alist '(ns-appearance . dark))
(setq trash-directory (expand-file-name "~/.Trash")) ; deleting in dired goes to the Finder Trash
(setq locate-command "mdfind")                   ; M-x locate uses Spotlight
(setq my/exec-path-from-shell t)                 ; Dock-launched Emacs doesn't see your shell PATH
(setq insert-directory-program (or (executable-find "gls") "ls")) ; GNU ls (brew coreutils) for dired
(setq dired-listing-switches (if (executable-find "gls") "-alh --group-directories-first" "-alh"))
(setq command-line-x-option-alist nil)           ; startup: skip X11 option parsing
(keymap-global-unset "s-<down-mouse-1>")          ; free Option-press for the click below
(keymap-global-set "s-<mouse-1>" #'mc/add-cursor-on-click)  ; Option-click: add a cursor (VSCode)
(keymap-global-set "M-s-<up>" #'mc/mark-previous-lines)     ; Cmd-Option-Up: cursor above (VSCode)
(keymap-global-set "M-s-<down>" #'mc/mark-next-lines)       ; Cmd-Option-Down: cursor below (VSCode)
(keymap-global-set "S-s-<down-mouse-1>" #'my/mouse-column-cursors) ; Shift-Option-drag: box -> cursors
;;;; <<< MACOS END ========================================================== macOS

;;;; >>> FEDORA BEGIN ================================================== Fedora
;; (setq my/platform 'fedora)
;; (setq my/font-size 20)                           ; rexim's Iosevka-20 on a normal-DPI screen
;; (setq x-super-keysym 'super                      ; Super stays Super (GNOME uses it for windows)
;;       x-alt-keysym 'meta)                        ; Alt = Meta
;; (when (boundp 'pgtk-wait-for-event-timeout)      ; Fedora's Emacs is the pure-GTK (Wayland) build:
;;   (setq pgtk-wait-for-event-timeout 0.001))      ;   removes its typing lag
;; (setq frame-resize-pixelwise t)
;; (setq trash-directory nil)                       ; deleting in dired goes to the GNOME Trash
;; (setq locate-command "plocate")                  ; M-x locate (dnf install plocate)
;; (setq my/exec-path-from-shell nil)               ; GNOME already gives Emacs your PATH
;; (setq insert-directory-program "ls")             ; Fedora's ls is GNU ls
;; (setq dired-listing-switches "-alh --group-directories-first")
;; (setq command-line-ns-option-alist nil)          ; startup: skip macOS option parsing
;; (keymap-global-unset "M-<down-mouse-1>")          ; free Alt-press (was: secondary selection)
;; (keymap-global-set "M-<mouse-1>" #'mc/add-cursor-on-click)  ; Alt-click: add a cursor (VSCode)
;; (keymap-global-set "C-M-<up>" #'mc/mark-previous-lines)     ; Ctrl-Alt-Up: cursor above (VSCode)
;; (keymap-global-set "C-M-<down>" #'mc/mark-next-lines)       ; Ctrl-Alt-Down: cursor below (VSCode)
;; (keymap-global-set "M-S-<down-mouse-1>" #'my/mouse-column-cursors) ; Shift-Alt-drag: box -> cursors
;;;; <<< FEDORA END ========================================================= Fedora

;; Started Emacs on the "wrong" block?  Say so once (doesn't break anything).
(add-hook 'emacs-startup-hook
          (lambda ()
            (let ((want (if (eq system-type 'darwin) 'macos 'fedora)))
              (unless (or (eq my/platform want) (memq system-type '(windows-nt ms-dos)))
                (message "init-platform.el has the %s block active but this is %s: run ./setup.sh --platform %s"
                         my/platform system-type want)))))

(provide 'init-platform)
;;; init-platform.el ends here

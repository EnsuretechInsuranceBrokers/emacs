;;; init-maint.el --- Keep this config healthy for decades -*- lexical-binding: t; -*-

;;; Commentary:
;; Tools for the long run:
;;   M-x my/doctor            what's installed, what's missing, what to fix
;;   M-x my/upgrade           snapshot packages, then upgrade everything
;;   M-x my/rollback          go back to a snapshot if an upgrade broke something
;;   M-x my/snapshots-prune   keep only the newest few snapshots
;;   M-x my/clean             free disk: orphan packages, old native code, old snapshots
;;   M-x my/disk-usage        how much space Emacs uses, and where
;;   M-x my/compile-config    byte- and native-compile lisp/ (faster startup)
;;   M-x my/benchmark-startup start a fresh Emacs and time it
;;
;; The shell equivalents are `./setup.sh --doctor' and `./setup.sh --update'.

;;; Code:

(require 'cl-lib)
;; package.el is loaded by each command below, not at startup.
(declare-function package-installed-p "package")

(defconst my/snapshot-dir (expand-file-name "elpa-snapshots/" my/var-dir)
  "Where `my/upgrade' saves copies of the package directory.")

(defcustom my/snapshots-keep 3
  "How many package snapshots `my/snapshots-prune' keeps."
  :type 'integer :group 'my)

;;;; Snapshots and upgrades
(defun my/copy-tree-cheap (src dest)
  "Copy directory SRC to DEST using hard links where possible.
Upgrades replace whole package directories instead of editing files, so a
hard-linked snapshot costs almost no disk: only packages that later change
take space."
  (unless (and (not (memq system-type '(windows-nt ms-dos)))
               (executable-find "cp")
               (zerop (call-process "cp" nil nil nil "-al"
                                    (directory-file-name src) (directory-file-name dest))))
    (copy-directory src dest t t t)))

(defun my/snapshot (&optional label)
  "Snapshot the installed packages (hard links: nearly free).  Returns its path."
  (interactive)
  (require 'package)
  (let* ((name (format-time-string "%Y%m%d-%H%M%S"))
         (dest (expand-file-name (if label (concat name "-" label) name) my/snapshot-dir)))
    (make-directory my/snapshot-dir t)
    (my/copy-tree-cheap package-user-dir dest)
    (message "Package snapshot: %s" (abbreviate-file-name dest))
    dest))

(defun my/upgrade ()
  "Snapshot installed packages, then upgrade all of them.
If anything breaks, restart Emacs and run \\[my/rollback]."
  (interactive)
  (require 'package)
  (when (file-directory-p package-user-dir)
    (my/snapshot "before-upgrade"))
  (package-refresh-contents)
  (if (fboundp 'package-upgrade-all)
      (package-upgrade-all nil)                     ; Emacs 29+
    (user-error "Needs Emacs 29+"))
  (when (fboundp 'treesit-auto-install-all)
    (let ((treesit-auto-install t)) (ignore-errors (treesit-auto-install-all))))
  (package-quickstart-refresh)
  (my/clean)
  (my/compile-config)
  (message "Upgrade done.  Restart Emacs.  If something broke: M-x my/rollback"))

(defun my/rollback (snapshot)
  "Replace the installed packages with SNAPSHOT, then ask to restart."
  (interactive
   (list (let ((all (and (file-directory-p my/snapshot-dir)
                         (reverse (directory-files my/snapshot-dir nil "\\`[0-9]")))))
           (unless all (user-error "No snapshots in %s" my/snapshot-dir))
           (completing-read "Roll back to: " all nil t nil nil (car all)))))
  (require 'package)
  (let ((src (expand-file-name snapshot my/snapshot-dir))
        (broken (concat (directory-file-name package-user-dir) ".broken")))
    (when (file-exists-p broken) (delete-directory broken t))
    (rename-file package-user-dir broken)
    (my/copy-tree-cheap src package-user-dir)
    (package-quickstart-refresh)
    (when (y-or-n-p (format "Rolled back to %s (old packages in %s). Restart now? "
                            snapshot (abbreviate-file-name broken)))
      (restart-emacs))))

(defun my/snapshots-prune ()
  "Delete all but the newest `my/snapshots-keep' snapshots."
  (interactive)
  (when (file-directory-p my/snapshot-dir)
    (let ((all (reverse (directory-files my/snapshot-dir t "\\`[0-9]"))))
      (dolist (old (nthcdr my/snapshots-keep all))
        (delete-directory old t)))))

;;;; Disk
(defun my/dir-size (dir)
  "Size of DIR in bytes (0 if missing)."
  (cond ((not (file-directory-p dir)) 0)
        ((executable-find "du")
         (with-temp-buffer
           (if (zerop (call-process "du" nil t nil "-sk" (expand-file-name dir)))
               (* 1024 (string-to-number (buffer-string)))
             0)))
        (t (apply #'+ (mapcar (lambda (f) (or (file-attribute-size (file-attributes f)) 0))
                              (directory-files-recursively dir "" nil t))))))

(defun my/disk-places ()
  "Alist of (LABEL . DIR) for everything this config stores on disk."
  (require 'package)
  `(("packages (elpa)" . ,package-user-dir)
    ("native code (eln-cache)" . ,(expand-file-name "eln-cache" user-emacs-directory))
    ("tree-sitter grammars" . ,(expand-file-name "tree-sitter" user-emacs-directory))
    ("package snapshots" . ,my/snapshot-dir)
    ("rolled-back packages" . ,(concat (directory-file-name package-user-dir) ".broken"))
    ("history, auto-saves (var)" . ,my/var-dir)))

(defun my/disk-usage ()
  "Show how much disk this Emacs setup uses."
  (interactive)
  (let ((total 0) lines)
    (dolist (place (my/disk-places))
      (let ((size (my/dir-size (cdr place))))
        (setq total (+ total size))
        (push (format "  %-28s %8s  %s" (car place) (file-size-human-readable size)
                      (abbreviate-file-name (cdr place)))
              lines)))
    (let ((report (concat (mapconcat #'identity (nreverse lines) "\n")
                          (format "\n  %-28s %8s" "total" (file-size-human-readable total)))))
      (if (called-interactively-p 'any)
          (message "%s\nFree space: M-x my/clean" report)
        report))))

(defun my/clean (&optional deep)
  "Free disk space without losing anything you need.
Removes packages nothing depends on any more, native code compiled for
other Emacs versions, old snapshots and leftovers of a rollback.
With a prefix argument (DEEP), also clear the whole native-code cache;
it rebuilds itself in the background as you use Emacs."
  (interactive "P")
  (require 'package)
  (let ((before (apply #'+ (mapcar (lambda (p) (my/dir-size (cdr p))) (my/disk-places)))))
    ;; Orphaned dependencies.
    (when (fboundp 'package-autoremove)
      (cl-letf (((symbol-function 'yes-or-no-p) (lambda (&rest _) t))
                ((symbol-function 'y-or-n-p) (lambda (&rest _) t)))
        (ignore-errors (package-autoremove))))
    ;; Native code for Emacs versions you no longer run.
    (when (fboundp 'native-compile-prune-cache)
      (ignore-errors (native-compile-prune-cache)))
    (when deep
      (let ((eln (expand-file-name "eln-cache" user-emacs-directory)))
        (when (file-directory-p eln) (delete-directory eln t))))
    (my/snapshots-prune)
    (let ((broken (concat (directory-file-name package-user-dir) ".broken")))
      (when (file-directory-p broken) (delete-directory broken t)))
    ;; Old auto-saves (30+ days).
    (let ((dir (expand-file-name "auto-save/" my/var-dir)))
      (when (file-directory-p dir)
        (dolist (f (directory-files dir t "\\`[^.]"))
          (when (> (float-time (time-since (file-attribute-modification-time
                                            (file-attributes f))))
                   (* 30 24 3600))
            (delete-file f)))))
    (let ((after (apply #'+ (mapcar (lambda (p) (my/dir-size (cdr p))) (my/disk-places)))))
      (message "my/clean: freed %s (now %s)"
               (file-size-human-readable (max 0 (- before after)))
               (file-size-human-readable after)))))

;;;; Compiling the config itself
;; Loading lisp/*.el means macro-expanding ~60 use-package forms on every
;; start.  Byte-compiled (and then native-compiled) they load several times
;; faster.  `load-prefer-newer' (early-init.el) makes an edited .el win over
;; a stale .elc, and saving a file in lisp/ recompiles it.
(defun my/compile-config ()
  "Byte-compile lisp/*.el, then native-compile them in the background."
  (interactive)
  (let ((byte-compile-warnings nil)
        (inhibit-message (not (called-interactively-p 'any)))
        (n 0))
    (dolist (file (directory-files my/lisp-dir t "\\.el\\'"))
      (unless (string-prefix-p "." (file-name-nondirectory file))
        (when (ignore-errors (byte-compile-file file))
          (setq n (1+ n)))))
    ;; Native code: Emacs compiles each loaded .elc in the background on
    ;; its own (`native-comp-jit-compilation'), so nothing to do here.
    (message "Config compiled (%d files)" n)))

(defun my/recompile-config-file ()
  "After saving a file in lisp/, recompile it quietly."
  (when (and buffer-file-name
             (string-suffix-p ".el" buffer-file-name)
             (file-in-directory-p buffer-file-name my/lisp-dir))
    (let ((byte-compile-warnings nil)
          (inhibit-message t))
      (ignore-errors (byte-compile-file buffer-file-name)))))
(add-hook 'after-save-hook #'my/recompile-config-file)

;;;; Doctor
(defconst my/doctor-tools
  '(("git"    "everything (magit, diff-hl, autocommit)" t)
    ("rg"     "project search: M-s r, SPC /" t)
    ("fd"     "fast file search: M-s f" nil)
    ("cc"     "compiling C, tree-sitter grammars, vterm" t)
    ("cmake"  "building vterm" nil)
    ("clangd" "C/C++ language server" nil)
    ("clang-format" "C/C++ formatting" nil)
    ("gopls"  "Go language server" nil)
    ("gofumpt" "Go formatting" nil)
    ("intelephense" "PHP language server" nil)
    ("typescript-language-server" "JS/TS language server" nil)
    ("basedpyright-langserver" "Python language server" nil)
    ("ruff"   "Python formatting" nil)
    ("prettier" "JS/JSON/YAML/Markdown formatting" nil)
    ("rust-analyzer" "Rust language server" nil)
    ("zls"    "Zig language server" nil)
    ("direnv" "per-project environments" nil))
  "Programs `my/doctor' checks: (NAME WHAT-FOR REQUIRED).")

(defun my/doctor--line (ok what &optional fix)
  (insert (if ok "  [ok]   " "  [--]   ") what)
  (when (and fix (not ok)) (insert "\n           -> " fix))
  (insert "\n"))

(defun my/doctor ()
  "Show a health report of this Emacs setup."
  (interactive)
  (require 'package)
  (let ((buf (get-buffer-create "*doctor*")))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (format "Emacs %s%s, config at %s\n\n"
                        emacs-version
                        (if (and (fboundp 'native-comp-available-p) (native-comp-available-p))
                            " (native-comp)" " (no native-comp: slower, consider a build with it)")
                        (abbreviate-file-name user-emacs-directory)))
        (insert "Emacs\n")
        (my/doctor--line (>= emacs-major-version 29) "Emacs 29 or newer" "upgrade Emacs")
        (my/doctor--line (and (fboundp 'treesit-available-p) (treesit-available-p))
                         "tree-sitter support" "use an Emacs built with tree-sitter")
        (my/doctor--line (and (fboundp 'json-available-p) (json-available-p))
                         "native JSON (fast LSP)")
        (my/doctor--line (and module-file-suffix t) "dynamic modules (vterm)")
        (insert "\nPackages\n")
        (let* ((wanted (seq-filter (lambda (p) (not (package-built-in-p p)))
                                   (my/doctor--configured-packages)))
               (missing (seq-remove #'package-installed-p wanted)))
          (my/doctor--line (null missing)
                           (format "%d/%d configured packages installed"
                                   (- (length wanted) (length missing)) (length wanted))
                           (format "missing: %s.  Restart with network, or M-x package-install"
                                   (mapconcat #'symbol-name missing " "))))
        (my/doctor--line (custom-theme-enabled-p 'gruber-darker) "gruber-darker theme")
        (my/doctor--line (or (not (display-graphic-p))
                             (seq-find (lambda (f) (find-font (font-spec :name f))) my/fonts))
                         (format "font (%s)" (car my/fonts))
                         "./setup.sh installs Iosevka; or set my/fonts in personal.el")
        (when (fboundp 'treesit-language-available-p)
          (let* ((langs '(c cpp go python javascript typescript tsx php json yaml bash rust))
                 (have (seq-filter #'treesit-language-available-p langs)))
            (my/doctor--line (= (length have) (length langs))
                             (format "tree-sitter grammars: %d/%d" (length have) (length langs))
                             "M-x treesit-auto-install-all")))
        (insert "\nPrograms\n")
        (dolist (tool my/doctor-tools)
          (my/doctor--line (executable-find (nth 0 tool))
                           (format "%-28s %s%s" (nth 0 tool) (nth 1 tool)
                                   (if (nth 2 tool) "  (needed)" ""))))
        (insert "\nDisk\n" (my/disk-usage) "\n")
        (insert (format "\nStartup: %s, %d GCs.  Snapshots: %d.  Packages dir: %s\n"
                        (emacs-init-time "%.2fs") gcs-done
                        (if (file-directory-p my/snapshot-dir)
                            (length (directory-files my/snapshot-dir nil "\\`[0-9]")) 0)
                        (abbreviate-file-name package-user-dir)))
        (insert "\nEverything marked [--] is optional unless it says (needed).\n")
        (goto-char (point-min))
        (special-mode)))
    (if noninteractive
        (princ (with-current-buffer buf (buffer-string)))
      (pop-to-buffer buf))))

(defun my/doctor--configured-packages ()
  "Packages in `use-package' forms under lisp/ that install from an archive.
Skips blocks with `:ensure nil' (built in) or `:if' (only on some systems)."
  (let (pkgs)
    (cl-labels ((walk (form)
                  (when (consp form)
                    (cond
                     ;; (when my/some-option ...) with the option off: skip.
                     ((and (eq (car form) 'when) (symbolp (cadr form))
                           (boundp (cadr form)) (not (symbol-value (cadr form))))
                      nil)
                     ((and (eq (car form) 'use-package) (symbolp (cadr form)))
                        (let ((args (cddr form)))
                          (unless (or (and (plist-member args :ensure)
                                           (null (plist-get args :ensure)))
                                      (plist-member args :if))
                            (push (cadr form) pkgs))))
                     ;; Walk proper and dotted lists alike.
                     (t (while (consp form)
                          (walk (car form))
                          (setq form (cdr form))))))))
      (dolist (file (directory-files (expand-file-name "lisp" user-emacs-directory) t "\\.el\\'"))
        (unless (and (not my/use-evil) (string-suffix-p "init-evil.el" file))
         (with-temp-buffer
          (insert-file-contents file)
          (goto-char (point-min))
          (condition-case nil
              (while t (walk (read (current-buffer))))
            (error nil))))))
    (delete-dups (nreverse pkgs))))

;;;; Startup benchmark
(defun my/benchmark-startup ()
  "Start a separate Emacs with this config and report how long init took."
  (interactive)
  (let* ((emacs (expand-file-name invocation-name invocation-directory))
         (out (with-temp-buffer
                (call-process emacs nil t nil "--batch" "--init-directory" user-emacs-directory
                              "-l" (expand-file-name "early-init.el" user-emacs-directory)
                              "--eval" (format "(let ((t0 (current-time))) (load %S nil t) (princ (format \"%%.3f\" (float-time (time-since t0)))))"
                                               (expand-file-name "init.el" user-emacs-directory)))
                (buffer-string))))
    (message "Config loads in %ss (batch, without the first frame)" (string-trim out))))

(provide 'init-maint)
;;; init-maint.el ends here

;;; init-maint.el --- Keep this config healthy for decades -*- lexical-binding: t; -*-

;;; Commentary:
;; Tools for the long run:
;;   M-x my/doctor            what's installed, what's missing, what to fix
;;   M-x my/upgrade           snapshot packages, then upgrade everything
;;   M-x my/rollback          go back to a snapshot if an upgrade broke something
;;   M-x my/snapshots-prune   keep only the newest few snapshots
;;   M-x my/benchmark-startup start a fresh Emacs and time it
;;
;; The shell equivalents are `./setup.sh --doctor' and `./setup.sh --update'.

;;; Code:

(require 'package)
(require 'cl-lib)

(defconst my/snapshot-dir (expand-file-name "elpa-snapshots/" my/var-dir)
  "Where `my/upgrade' saves copies of the package directory.")

(defcustom my/snapshots-keep 5
  "How many package snapshots `my/snapshots-prune' keeps."
  :type 'integer :group 'my)

;;;; Snapshots and upgrades
(defun my/snapshot (&optional label)
  "Copy the installed packages to a dated snapshot.  Returns its path."
  (interactive)
  (let* ((name (format-time-string "%Y%m%d-%H%M%S"))
         (dest (expand-file-name (if label (concat name "-" label) name) my/snapshot-dir)))
    (make-directory my/snapshot-dir t)
    (copy-directory package-user-dir dest t t t)
    (message "Package snapshot: %s" (abbreviate-file-name dest))
    dest))

(defun my/upgrade ()
  "Snapshot installed packages, then upgrade all of them.
If anything breaks, restart Emacs and run \\[my/rollback]."
  (interactive)
  (when (file-directory-p package-user-dir)
    (my/snapshot "before-upgrade"))
  (package-refresh-contents)
  (if (fboundp 'package-upgrade-all)
      (package-upgrade-all nil)                     ; Emacs 29+
    (user-error "Needs Emacs 29+"))
  (when (fboundp 'treesit-auto-install-all)
    (let ((treesit-auto-install t)) (ignore-errors (treesit-auto-install-all))))
  (package-quickstart-refresh)
  (my/snapshots-prune)
  (message "Upgrade done.  Restart Emacs.  If something broke: M-x my/rollback"))

(defun my/rollback (snapshot)
  "Replace the installed packages with SNAPSHOT, then ask to restart."
  (interactive
   (list (let ((all (and (file-directory-p my/snapshot-dir)
                         (reverse (directory-files my/snapshot-dir nil "\\`[0-9]")))))
           (unless all (user-error "No snapshots in %s" my/snapshot-dir))
           (completing-read "Roll back to: " all nil t nil nil (car all)))))
  (let ((src (expand-file-name snapshot my/snapshot-dir))
        (broken (concat (directory-file-name package-user-dir) ".broken")))
    (when (file-exists-p broken) (delete-directory broken t))
    (rename-file package-user-dir broken)
    (copy-directory src package-user-dir t t t)
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

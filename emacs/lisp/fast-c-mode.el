;;; fast-c-mode.el --- Small, fast major mode for C and C++ -*- lexical-binding: t; -*-

;;; Commentary:
;; cc-mode and even tree-sitter get slow on enormous files (amalgamated
;; sqlite3.c, single-header libraries like miniaudio.h, generated code).
;; This mode stays fast on any size because it does only cheap things:
;;
;;   - highlighting from a handful of regexps plus the syntax table
;;   - indentation from `syntax-ppss' (cached paren depth) and a look at
;;     the previous line of code; nothing scans the whole file
;;
;; It still handles what you'd want while editing:
;;   - braces, K&R and Allman styles, `case'/`default' labels, access
;;     specifiers (public:/private:)
;;   - braceless bodies:  if (x)\n    foo();  and nested ones
;;   - continuation lines inside ( ) and [ ] (aligned to the open paren)
;;     and inside blocks (one extra level)
;;   - block comments (` * ' lines line up), preprocessor lines at column 0
;;   - imenu (functions, types, macros), comments, hideshow, electric }
;;
;; Usage: (setq my/c-mode 'fast) to use it for every C/C++ file; by default
;; it is used only for files over `my/c-big-file-size'.

;;; Code:

(require 'subr-x)

(defgroup fast-c nil
  "Small, fast C/C++ mode."
  :group 'languages)

(defcustom fast-c-indent-offset 4
  "Spaces per indentation level."
  :type 'integer)

;;;; Syntax
(defvar fast-c-mode-syntax-table
  (let ((st (make-syntax-table)))
    ;; // line comments (style b) and /* block comments */
    (modify-syntax-entry ?/ ". 124b" st)
    (modify-syntax-entry ?* ". 23" st)
    (modify-syntax-entry ?\n "> b" st)
    (modify-syntax-entry ?\r "> b" st)
    ;; Identifiers may contain _ ; chars are strings; \ escapes
    (modify-syntax-entry ?_ "_" st)
    (modify-syntax-entry ?' "\"" st)
    (modify-syntax-entry ?\\ "\\" st)
    ;; Operators are punctuation, so < > in templates don't act as parens.
    (dolist (c '(?+ ?- ?= ?% ?< ?> ?& ?| ?! ?^ ?~ ?? ?: ?. ?, ?\; ?#))
      (modify-syntax-entry c "." st))
    st)
  "Syntax table for `fast-c-mode'.")

;;;; Highlighting
(defconst fast-c--keywords
  '(;; C
    "auto" "break" "case" "const" "continue" "default" "do" "else" "enum"
    "extern" "for" "goto" "if" "inline" "register" "restrict" "return"
    "sizeof" "static" "struct" "switch" "typedef" "union" "volatile" "while"
    "_Alignas" "_Alignof" "_Atomic" "_Generic" "_Noreturn" "_Static_assert"
    "_Thread_local" "alignas" "alignof" "static_assert" "thread_local"
    "typeof" "constexpr"
    ;; C++
    "catch" "class" "concept" "consteval" "constinit" "const_cast" "co_await"
    "co_return" "co_yield" "decltype" "delete" "dynamic_cast" "explicit"
    "export" "final" "friend" "import" "module" "mutable" "namespace" "new"
    "noexcept" "operator" "override" "private" "protected" "public"
    "reinterpret_cast" "requires" "static_cast" "template" "this" "throw"
    "try" "typeid" "typename" "using" "virtual"))

(defconst fast-c--types
  '("void" "char" "short" "int" "long" "float" "double" "signed" "unsigned"
    "bool" "_Bool" "_Complex" "wchar_t" "char8_t" "char16_t" "char32_t"
    "FILE" "va_list" "string" "string_view" "vector" "map" "set"))

(defconst fast-c--constants '("true" "false" "NULL" "nullptr" "EOF" "stdin" "stdout" "stderr"))

(defconst fast-c-font-lock-keywords
  `(;; Preprocessor: #include <file> / "file", then the directive itself.
    ("^\\s-*#\\s-*\\(?:include\\|import\\)\\s-*\\(<[^>\n]*>\\)" 1 font-lock-string-face)
    ("^\\s-*#\\s-*\\(?:error\\|warning\\)\\_>.*" 0 font-lock-warning-face)
    ("^\\s-*\\(#\\s-*[a-z_]+\\)" 1 font-lock-preprocessor-face)
    ("^\\s-*#\\s-*define\\s-+\\([A-Za-z_][A-Za-z0-9_]*\\)" 1 font-lock-constant-face)
    ;; Words
    (,(regexp-opt fast-c--keywords 'symbols) . font-lock-keyword-face)
    (,(regexp-opt fast-c--types 'symbols) . font-lock-type-face)
    (,(regexp-opt fast-c--constants 'symbols) . font-lock-constant-face)
    ;; foo_t / int32_t / size_t: POSIX-style type names
    ("\\_<[A-Za-z_][A-Za-z0-9_]*_t\\_>" . font-lock-type-face)
    ;; struct Name / enum Name / class Name / union Name
    ("\\_<\\(?:struct\\|enum\\|union\\|class\\|namespace\\)\\s-+\\([A-Za-z_][A-Za-z0-9_]*\\)"
     1 font-lock-type-face)
    ;; Function definitions: a line starting at column 0 with `type name('.
    ("^\\(?:[A-Za-z_][A-Za-z0-9_:<>,]*[ \t*&]+\\)+\\([A-Za-z_~][A-Za-z0-9_:~]*\\)\\s-*("
     1 font-lock-function-name-face)
    ;; Calls: name(
    ("\\_<\\([A-Za-z_][A-Za-z0-9_]*\\)\\s-*("
     1 ,(if (facep 'font-lock-function-call-face)
            ''font-lock-function-call-face
          ''font-lock-function-name-face))
    ;; MACROS_IN_CAPS and numbers
    ("\\_<[A-Z][A-Z0-9_]+\\_>" . font-lock-constant-face)
    ("\\_<\\(?:0[xX][0-9A-Fa-f']+\\|0[bB][01']+\\|[0-9][0-9']*\\(?:\\.[0-9']*\\)?\\(?:[eE][-+]?[0-9]+\\)?\\)[uUlLfF]*\\_>"
     . font-lock-constant-face))
  "Highlighting rules for `fast-c-mode'.")

;;;; Indentation
(defun fast-c--line-starts-with (regexp)
  "Non-nil if the current line's first non-blank text matches REGEXP."
  (save-excursion (back-to-indentation) (looking-at-p regexp)))

(defun fast-c--prev-code-end ()
  "Position just after the last code before this line, or nil.
Skips blank lines, comments and preprocessor lines."
  (save-excursion
    (beginning-of-line)
    (catch 'found
      (while t
        (forward-comment (- (point)))
        (when (bobp) (throw 'found nil))
        (let ((bol (line-beginning-position)))
          (if (save-excursion (goto-char bol) (looking-at-p "[ \t]*#"))
              (goto-char bol)
            (throw 'found (point))))))))

(defun fast-c--header-indent (pos)
  "If the code ending at POS is a braceless control header, its indentation.
Headers are `if (...)', `for (...)', `while (...)', `switch (...)',
`else' and `do', also when the condition spans several lines."
  (save-excursion
    (goto-char pos)
    (cond
     ((eq (char-before) ?\))
      (condition-case nil
          (progn
            (backward-sexp)                  ; to the matching (
            (skip-chars-backward " \t")
            (when (looking-back "\\_<\\(?:if\\|for\\|while\\|switch\\)"
                                (line-beginning-position))
              (current-indentation)))
        (scan-error nil)))
     ((looking-back "\\_<\\(?:else\\|do\\)" (line-beginning-position))
      (current-indentation)))))

(defun fast-c--calculate-indent ()
  "Column this line should be indented to, or nil to leave it alone."
  (save-excursion
    (beginning-of-line)
    (let* ((ppss (syntax-ppss))
           (open (nth 1 ppss))
           (off fast-c-indent-offset))
      (cond
       ;; Inside a string literal: don't touch.
       ((nth 3 ppss) nil)
       ;; Inside a /* block comment */: line up the * with the opening one.
       ((nth 4 ppss)
        (if (fast-c--line-starts-with "\\*")
            (save-excursion (goto-char (nth 8 ppss)) (1+ (current-column)))
          nil))
       ;; Preprocessor lines start at column 0.
       ((fast-c--line-starts-with "#") 0)
       ;; Inside ( ) or [ ]: align with the first thing after the opener,
       ;; or one level in if the opener ends its line.
       ((and open (memq (char-after open) '(?\( ?\[)))
        (let ((closing (fast-c--line-starts-with "[])]")))
          (goto-char open)
          (let ((opener-indent (current-indentation)))
            (forward-char 1)
            (skip-chars-forward " \t")
            (cond (closing opener-indent)
                  ((or (eolp) (looking-at-p "//\\|/\\*")) (+ opener-indent off))
                  (t (current-column))))))
       ;; In a { block } or at top level.
       (t
        (let* ((base (if open
                         (save-excursion (goto-char open) (+ (current-indentation) off))
                       0))
               (prev (fast-c--prev-code-end))
               (prev-char (and prev (char-before prev)))
               (open-line (and prev prev-char
                               (not (memq prev-char '(?\; ?{ ?} ?, ?:)))
                               (or (null open) (> prev open))))
               (header (and open-line (fast-c--header-indent prev))))
          (cond
           ((fast-c--line-starts-with "}") (- base off))
           ((fast-c--line-starts-with
             "\\(?:case\\_>[^:]*\\|default\\s-*\\):\\(?:[^:]\\|$\\)")
            (- base off))
           ((fast-c--line-starts-with
             "\\(?:public\\|private\\|protected\\)\\s-*:\\(?:[^:]\\|$\\)")
            (- base off))
           ;; A { on its own line goes where its header is.
           ((fast-c--line-starts-with "{") (or header base))
           ;; Body of a braceless if/for/while/else/do.
           (header (+ header off))
           ;; Statement continued from the previous line.
           ((and open-line open) (+ base off))
           (t base))))))))

(defun fast-c-indent-line ()
  "Indent the current line as C/C++."
  (interactive)
  (let ((indent (fast-c--calculate-indent)))
    (if (not indent)
        'noindent
      (let ((offset (- (current-column) (current-indentation))))
        (indent-line-to (max 0 indent))
        (when (> offset 0) (forward-char offset))))))

;;;; imenu
(defconst fast-c-imenu-generic-expression
  '(("Macros" "^\\s-*#\\s-*define\\s-+\\([A-Za-z_][A-Za-z0-9_]*\\)" 1)
    ("Types" "^\\(?:typedef\\s-+\\)?\\(?:struct\\|enum\\|union\\|class\\)\\s-+\\([A-Za-z_][A-Za-z0-9_]*\\)\\s-*\\(?:{\\|:\\|$\\)" 1)
    (nil "^\\(?:[A-Za-z_][A-Za-z0-9_:<>,]*[ \t*&]+\\)+\\([A-Za-z_~][A-Za-z0-9_:~]*\\)\\s-*([^;]*$" 1))
  "Functions (top level), types and macros for \\[imenu].")

;;;; Mode
;;;###autoload
(define-derived-mode fast-c-mode prog-mode "FastC"
  "Small, fast major mode for C and C++.
Highlighting and indentation stay quick on files of any size.

\\{fast-c-mode-map}"
  :syntax-table fast-c-mode-syntax-table
  (setq-local font-lock-defaults '(fast-c-font-lock-keywords nil nil))
  (setq-local indent-line-function #'fast-c-indent-line)
  (setq-local comment-start "// "
              comment-end ""
              comment-start-skip "\\(?://+\\|/\\*+\\)\\s-*"
              comment-multi-line t)
  (setq-local electric-indent-chars (append '(?{ ?} ?: ?#) electric-indent-chars))
  (setq-local imenu-generic-expression fast-c-imenu-generic-expression)
  (setq-local indent-tabs-mode nil
              tab-width fast-c-indent-offset))

(provide 'fast-c-mode)
;;; fast-c-mode.el ends here

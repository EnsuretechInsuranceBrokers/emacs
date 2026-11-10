# emacs

A fast, keyboard-first Emacs config in the rexim / Tsoding style:
gruber-darker, Iosevka, instant buffer and file switching, and a
compile-driven "edit, build, run" loop. It's a vanilla Emacs config
(no Doom), built from the settings in my old Doom config. A tidied
Doom version is still in [`doom/`](doom/).

Needs **Emacs 29.1+** (30 recommended).

## Install

```bash
git clone <this repo> ~/src/emacs-config
```

```bash
~/src/emacs-config/install.sh
```

`install.sh` backs up any existing `~/.emacs`, `~/.emacs.d` or
`~/.config/emacs`, links this repo to `~/.config/emacs`, creates
`personal.el`, and lists which optional tools you have. Start Emacs once
with network access and it installs its packages (1–2 minutes, only the
first time). If you're offline it still opens, using built-in parts
only, and installs the rest on the next start.

For **zero startup time**, run Emacs as a daemon and open frames with the client:

```bash
emacs --daemon
```

```bash
emacsclient -c -a ''
```

### Vim keys?

Put `(setq my/use-evil t)` in `personal.el` to get evil, evil-collection,
surround and commentary, plus a Doom-style `SPC` leader. Without evil,
the same leader map is on `C-c SPC`.

## Why it's fast

| What | How |
|---|---|
| Startup | GC off during init, file handlers trimmed, UI disabled before the first frame, `package-quickstart`, every heavy package loads lazily |
| Typing | GC never runs while the minibuffer is open, it runs when idle or when Emacs loses focus; `redisplay-skip-fontification-on-input` |
| LSP | eglot (built in, lighter than lsp-mode), no event log, no highlights, lenses or inlay hints, 4 MB process reads |
| Big files | `so-long-mode`, simpler bidi handling |
| Switching | vertico + orderless + consult: every list is fuzzy, sorted by recent use, previewed live |

## Flying around (Emacs keys)

| Key | Does |
|---|---|
| `C-x b` | Switch buffer, recent file or bookmark. Type 2–3 letters, `RET`. `<` narrows: `< b` buffers, `< f` files, `< p` project |
| `C-c b` | Toggle to the previous buffer |
| `C-x C-f` | Open a file. `DEL` climbs a whole directory, typing `~/` jumps home |
| `C-x C-r` | Recent files |
| `C-x p f` / `C-x p p` | File in project / switch project |
| `C-x p g`, `M-s r` | ripgrep the project (`C-. E` then `C-c C-p` edits all matches) |
| `C-x C-j` | dired on the current file (`-` goes up, `C-c C-e` renames by editing text) |
| `M-o` | Next window; with 3+ windows, pick one by letter |
| `S-<arrow>` | Window in that direction |
| `C-;` / `M-j` | avy: type a char or two, pause, then jump to the labelled spot |
| `M-g i` | Jump to a function in this file (`M-g I`: all project buffers) |
| `M-s l` | Search this buffer with a live list |
| `M-.` / `M-,` / `M-?` | Definition / back / references |
| `C-x k` | Kill this buffer, no prompt |
| `C-x C-b` | ibuffer, grouped by project |
| `C-c <left>` | Undo the last window change (winner) |

## Editing

| Key | Does |
|---|---|
| `C->` / `C-<` / `C-c C-<` | Multiple cursors: next / previous / all like this |
| `C-S-c C-S-c` | A cursor on every line of the region |
| `M-p` / `M-n` | Move line or region up / down |
| `C-,` | Duplicate line or region |
| `C-=` / `C-+` | Expand / shrink the selection by syntax |
| `C-a` | Go to the first non-blank; press again for column 0 |
| `C-w` | Kill region, or the word before point |
| `C-o` / `C-S-o` | Open a line below / above |
| `C-x u` | Visual undo tree (`C-/` undo, `C-?` redo) |
| `C-c f` / `C-c F` | Fold block / fold everything |
| `C-.` | embark: act on the thing at point |
| `TAB` | Indent, or complete |

## Compile loop

| Key | Does |
|---|---|
| `C-c c` | `compile`: asks for a command and remembers it |
| `C-c r` / `F5` | Rerun the last build without asking (your `SPC r`) |
| `C-c x` | Run this file. C++ builds with `-O2` and reads `input.txt` if it's there (your `SPC m r`); Go, Python, PHP, JS and sh also work |
| `C-c i` | Open `input.txt` next to the current file |
| `M-g n` / `M-g p` | Next / previous error, in the source |
| `C-x p a` | `php artisan …` from the project root, with completion |
| `C-x p c` | Compile from the project root |

Default `compile-command`s: `nob.c` → `./nob`, then `build.sh`,
`Makefile`, `CMakeLists.txt`, and finally gcc/g++ for a single file. A
`.dir-locals.el` in the project root wins:

```elisp
((nil . ((compile-command . "make -j && ./main"))))
```

Snippets: `cp` (competitive programming template), `main` and `nob` in C/C++.

## Code intelligence

eglot starts by itself for C/C++, Go, Python, JS/TS and PHP when the
server is installed. Prefix: `C-c l` (`a` code actions, `r` rename,
`f` format, `o` organize imports). Diagnostics: `C-c ! n/p/l`.

| Language | Server | Install |
|---|---|---|
| C/C++ | clangd | your package manager |
| Go | gopls + gofumpt | `go install golang.org/x/tools/gopls@latest mvdan.cc/gofumpt@latest` |
| PHP | intelephense (phpactor as fallback) | `npm i -g intelephense` |
| Python | basedpyright / pyright / pylsp | `pip install basedpyright` |
| JS/TS | typescript-language-server | `npm i -g typescript-language-server typescript` |

Format on save uses apheleia (clang-format, gofumpt, black/ruff,
prettier, …) and quietly skips formatters you don't have. Toggle it per
buffer with `C-c SPC c F`. Go also organizes imports on save. Tree-sitter
grammars are offered the first time you open each language (needs a C
compiler). Debugger: `C-c d d` (dape).

## Leader (`SPC` with evil, `C-c SPC` without)

Doom layout: `SPC SPC` project file, `SPC ,` buffer, `SPC .` file,
`SPC /` grep, `SPC r` recompile, `SPC TAB` last buffer, `SPC p a`
artisan, `SPC m r` run file, `SPC g g` magit, `SPC o t` terminal,
`SPC w` windows, `SPC s`/`f`/`b`/`c` search/file/buffer/code. which-key
lists the rest after a short pause.

## Layout

```
early-init.el        startup speed, frame setup
init.el              options (my/use-evil, fonts) + module loading
lisp/init-*.el       one file per topic: perf, ui, completion, navigation,
                     editing, evil, dev, compile, langs, git, tools, keys
snippets/            your yasnippets
personal.el          machine-local overrides (git-ignored)
doom/                the Doom version (init.el, packages.el, config.el)
```

Update packages: `M-x package-upgrade-all`. Profile startup: set
`use-package-compute-statistics` to `t`, restart, `M-x use-package-report`.

## Doom version

To keep using Doom instead, link `doom/` to `~/.config/doom` and run
`doom sync`. Changes from the original files:

- `+treesitter` → `+tree-sitter` (Doom's real flag name).
- `IS-MAC` → `(featurep :system 'macos)`, since `IS-MAC` is deprecated.
- company → `(corfu +orderless)`; added `multiple-cursors` and `ibuffer`.
- The single-file C compile command no longer overrides `.dir-locals.el`, also works in `c-ts-mode`, and knows `nob.c`.
- `my/cp-run` works without `input.txt` and is bound in the tree-sitter C/C++ modes too.
- Go organize-imports no longer errors before the server is up.
- A few speed settings, `SPC j` for avy, `-` for dired-jump, and completion in `artisan`.

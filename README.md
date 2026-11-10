# emacs

A fast, keyboard-first Emacs config in the rexim / Tsoding style:
gruber-darker, Iosevka, instant buffer and file switching, and a
compile-driven "edit, build, run" loop. It's plain Emacs 29+ (no Doom),
built from my old Doom config plus everything useful in
[rexim's own config](https://github.com/rexim/dotfiles). It's made to last:
health checks, safe upgrades with rollback, and tests that run every week
on several Emacs versions. A tidied Doom version is in [`doom/`](doom/).

- [One-command setup](#one-command-setup)
- [What the script does](#what-the-script-does)
- [Manual install](#manual-install)
- [Getting fast](#getting-fast): the part that actually matters
- [Key reference](#key-reference)
- [Languages](#languages)
- [What's from rexim's config](#whats-from-rexims-config)
- [Notes that back themselves up](#notes-that-back-themselves-up)
- [Customizing](#customizing)
- [Keeping it working for decades](#keeping-it-working-for-decades)
- [Troubleshooting](#troubleshooting)

---

## One-command setup

From a clone:

```bash
git clone https://github.com/EnsuretechInsuranceBrokers/emacs.git ~/src/emacs-config && ~/src/emacs-config/setup.sh
```

Then start `emacs`. That's it.

Common variants:

```bash
./setup.sh --evil                 # Vim keys + Doom-style SPC leader
```

```bash
./setup.sh --daemon --keyboard    # instant startup + Caps->Ctrl + fast key repeat (recommended)
```

```bash
./setup.sh --minimal              # Emacs + core tools + config, no font or language servers
```

```bash
./setup.sh --dry-run              # show every command, change nothing
```

| Option | Effect |
|---|---|
| `--evil` | Vim keybindings, `SPC` leader (writes `(setq my/use-evil t)` to `personal.el`) |
| `--daemon` | Runs Emacs as a background service at login (systemd / launchd). `emacsclient` then opens in ~50 ms |
| `--keyboard` | Caps Lock → Ctrl and a 200 ms / 40 Hz key repeat (GNOME, X11, macOS) |
| `--minimal` | Skips the font and language servers |
| `--no-emacs` `--no-tools` `--no-font` `--no-lsp` `--no-packages` | Skip that step |
| `-y` | Don't ask before using `sudo` |
| `--dry-run` | Print, don't run |
| `--update` | Later on: pull this repo, snapshot packages, upgrade them, update grammars |
| `--doctor` | Print a health report (what's installed, what's missing) and exit |

You can re-run it any time: steps that are already done are skipped.
Supports macOS (Homebrew), Ubuntu/Debian, Fedora, Arch and openSUSE.

## What the script does

1. **Emacs 29+.** Uses yours if it's new enough. On Ubuntu it adds the
   `ubuntuhandbook1/emacs` PPA if the distro version is too old; on macOS it
   installs the `emacs` cask.
2. **Core tools:** git, ripgrep (project search), fd (file search), a C compiler,
   cmake + libtool + libvterm (for the vterm terminal), direnv.
3. **Iosevka font,** from Homebrew, pacman, or the official GitHub release into `~/.local/share/fonts`.
4. **Language servers** for the toolchains you already have: clangd,
   gopls + gofumpt (if `go` exists), intelephense + typescript-language-server +
   prettier (if `npm` exists), basedpyright + ruff (if `pipx` exists).
5. **Config.** Moves any old `~/.emacs`, `~/.emacs.d` or `~/.config/emacs` to
   `*.bak-<date>` and links this repo to `~/.config/emacs`. It also creates `personal.el`.
6. **Packages.** Runs Emacs headless once to download and natively compile every
   package, install tree-sitter grammars and build vterm. So the first real
   start is already fast. Log: `var/setup.log`.
7. **Optional:** daemon service and keyboard settings.

## Manual install

If you'd rather not run the script:

```bash
mv ~/.emacs.d ~/.emacs.d.bak 2>/dev/null; ln -s "$PWD" ~/.config/emacs
```

```bash
cp personal.example.el personal.el
```

Install `ripgrep` and `fd` and start `emacs`. Packages install on the first start
(1–2 minutes, once). If you're offline, Emacs still starts with the built-in parts and
installs the rest on the next start.

---

## Getting fast

The config only removes friction. The speed you see in Tsoding's streams
comes from habits. Here are the ones that matter most, in order of payoff.

### 0. Fix your keyboard first (10 minutes, biggest win)

- **Caps Lock → Ctrl.** Emacs is all Ctrl, and the pinky stretch to the
  bottom-left Ctrl is what makes people slow (and sore). `./setup.sh --keyboard` does it.
- **Fast key repeat:** about 200 ms delay and 40 repeats/second. Holding `C-n` should
  fly down the file. The default OS settings are about half that speed.
- **Never touch the mouse or arrow keys.** Hide the mouse if you have to.

### 1. Never wait for Emacs

- Use the daemon: `./setup.sh --daemon`, then `alias e='emacsclient -c -a ""'`.
  `e file.c` opens instantly in a frame of the running Emacs.
- Keep **one** Emacs open all day. Buffers are cheap; keep hundreds of them.
- Never confirm anything. The config already kills buffers, saves before
  compile, restarts builds and reverts changed files without asking.

### 2. Move by intent, not by line

Ask "where do I want to be?", not "how many lines down is that?":

| You want to… | Press | Not |
|---|---|---|
| go to a word you can see | `C-s word RET` (isearch) or `C-;` + 2 letters (avy) | `C-n C-n C-n C-f C-f…` |
| go to a function | `M-g i` + part of its name | scrolling |
| go to a definition | `M-.` (and `M-,` to come back) | grep + scroll |
| go back where you were | `C-u C-SPC` (repeat `C-SPC` to keep going back) | remembering |
| go to line 120 | `M-g g 120` | |
| go to the top / bottom | `M-<` / `M->` | holding `C-p` |
| by paragraph / function | `M-{` `M-}` / `C-M-a` `C-M-e` | |
| by expression (brackets) | `C-M-f` `C-M-b` | |

`C-s` is the most underrated movement key in Emacs: it's how Tsoding gets
anywhere on screen. Type a few letters, press `RET`, and you're there. `C-r` goes backwards.

### 3. Switch buffers by name, never by cycling

- `C-x b` + **2–3 letters** + `RET`. The list puts the buffers you used last on top, so
  usually you just press `C-x b RET` to go back to the last one.
- The letters can be any part of the name, in any order: `C-x b cfg ini`
  finds `init-config.el`. Prefix a word with `!` to exclude it.
- `C-c b` toggles between the last two buffers: use it constantly.
- In `C-x C-f`, `DEL` climbs a whole directory and `~/` jumps home. Don't type full
  paths; type fragments.
- In a project: `C-x p f` for files, `M-s r` for text (ripgrep), `C-x p p` to switch project.
- `C-x C-j` opens dired on the current file's folder. Treat dired as your file manager:
  `C` copy, `R` move/rename, `D` delete, `+` new folder, `-` up.

### 4. Two windows, side by side, that's all

Tsoding almost always has just code on the left and compilation/second file on the right.

- `C-x 3` split right (and move there), `C-x 1` back to one, `M-o` other window.
- `C-x 4 b` / `C-x 4 f`: open a buffer/file *in the other window* without leaving this one.
- `C-c <left>` undoes a window mess (winner-mode).

### 5. The compile loop is your IDE

```
C-c c   make -j && ./main RET     (once)
C-c r                             (forever after: rebuild + run)
M-g n                             (jump to the next error, in the source)
```

- Errors in `*compilation*` are links: `M-g n` / `M-g p` walk through them from any buffer.
- Put the command in `.dir-locals.el` so every file in the project uses it.
- `C-u C-c c` runs the command interactively (for programs that read stdin).
- For one-off files: `C-c x` builds and runs the current file (C++ reads `input.txt`).
- `M-!` runs a shell command, and `C-u M-!` inserts its output at point. `M-|` pipes the
  region through a command (`sort`, `jq .`, `column -t`, ...).

### 6. Edit in bulk

When you're about to make the same change three times, stop and use one of these:

| Tool | Keys | Use it for |
|---|---|---|
| Keyboard macro | `F3` … `F4`, then `F4 F4 F4` (or `C-u 0 F4` till the end) | any repeated edit. Tsoding uses these all the time |
| Multiple cursors | `C->` next match, `C-c C-<` all, `C-S-c C-S-c` every line | renaming a local, aligning lines |
| Rectangle | `C-x SPC` select, `C-x r t` type into every line, `C-x r k` cut | columns, prefixes |
| Query replace | `M-%` (`M-x query-replace-regexp` for regexps), `!` = all | file-wide changes |
| Project replace | `M-s r foo`, `C-. E`, `C-c C-p`, edit, `C-c C-c` | rename across the whole repo |
| Duplicate / move line | `C-,` / `M-p` `M-n` | shuffling code |
| Others | `M-x sort-lines`, `M-x align-regexp`, `M-x delete-duplicate-lines` | tidying |

### 7. Learn Emacs from inside Emacs

- `C-h k <key>` tells you what a key does. `C-h f` / `C-h v` describe functions and variables.
- After a prefix like `C-x`, wait half a second and which-key lists what comes next.
- `M-x` + part of a name finds anything; the binding is shown next to it. Next time, use the binding.
- `C-h t` is the built-in tutorial: do it once, it takes 30 minutes.

### A 4-week plan

Speed comes from not thinking about keys. Learn a few at a time until they're automatic.

| Week | Only focus on | Drill |
|---|---|---|
| 1 | Caps→Ctrl; `C-f/b/n/p`, `M-f/b`, `C-a/e`, `C-s/r`, `C-x b`, `C-x C-f`, `C-g` | Do all your editing in Emacs. No mouse, no arrows. Tutorial (`C-h t`) |
| 2 | `C-SPC`, `C-w`, `M-w`, `C-y`, `M-y`, `C-/`, `C-x 3`, `M-o`, `C-c b`, `C-x p f` | Every time you reach for the mouse, find the key (`C-h k` / which-key) |
| 3 | Compile loop (`C-c c`, `C-c r`, `M-g n`), dired, `M-.`, `M-g i`, `M-s r`, avy | Solve some problems with `cp` snippet + `C-c x`. Fix every error with `M-g n` |
| 4 | Macros (`F3`/`F4`), multiple cursors, `M-%`, rectangles, `M-|` | Any repeated edit: use a macro, even when it's slower the first time |

When something feels slow, press `C-h l`: it shows your last 300 keystrokes.
Look for the long runs of `C-n C-n C-n` and replace them with a jump. Then watch
a Tsoding stream and, whenever he does something fast, work out which of the
above it was.

---

## Key reference

Without evil, these are plain Emacs keys. With `--evil`, the same commands
are on the `SPC` leader (see [below](#leader-spc-with-evil-c-c-spc-without)).

### Moving around

| Key | Does |
|---|---|
| `C-x b` | Buffers + recent files + bookmarks, live preview. `< b`/`< f`/`< p` narrows to buffers/files/project |
| `C-c b` | Toggle to the previous buffer |
| `C-x C-f` | Open file (`DEL` climbs a directory) |
| `C-x C-r` | Recent files |
| `C-x p f` / `C-x p p` / `C-x p b` | Project file / switch project / project buffer |
| `M-s r` / `C-x p g` | ripgrep the project |
| `M-s l` / `M-s L` | Search this buffer / all buffers |
| `M-g i` / `M-g I` | Functions in this file / in all project buffers |
| `M-g g` | Go to line (with preview) |
| `C-;` or `M-j` | avy: type 1–2 chars, pause, jump to the label |
| `M-.` / `M-,` / `M-?` | Definition / back / references |
| `C-x C-j` | dired here (`-` up, `C-c C-e` rename by editing) |
| `M-o` | Next window (pick by letter with 3+) |
| `S-<arrows>` | Window in that direction |
| `C-x 2` / `C-x 3` | Split below / right and move there |
| `C-c <left>` / `C-c <right>` | Undo / redo window changes |
| `C-x k` / `C-x K` | Kill buffer / kill all other file buffers |
| `C-x C-b` | ibuffer, grouped by project |

### Editing

| Key | Does |
|---|---|
| `C->` `C-<` `C-c C-<` | Multiple cursors: next / previous / all like this |
| `C-S-c C-S-c` | A cursor on every line of the region |
| `M-p` / `M-n` | Move line or region up / down |
| `C-,` | Duplicate line or region |
| `C-=` / `C-+` | Expand / shrink selection by syntax |
| `C-a` | First non-blank, press again for column 0 |
| `C-w` | Kill region, or the word before point |
| `C-o` / `C-S-o` | New line below / above |
| `C-/` / `C-?` / `C-x u` | Undo / redo / visual undo tree |
| `M-y` | Pick from the kill ring |
| `C-c f` / `C-c F` | Fold block / fold everything |
| `C-.` | embark: actions on the thing at point |
| `TAB` | Indent, or complete. Completion pops up by itself after 2 chars |

### Build and run

| Key | Does |
|---|---|
| `C-c c` | `compile` (asks, remembers) |
| `C-c r` / `F5` | Recompile, no questions |
| `C-c x` | Run this file (C++ + `input.txt`, C, Go, Python, PHP, JS, sh) |
| `C-c i i` | Open `input.txt` next to this file |
| `M-g n` / `M-g p` | Next / previous error |
| `C-x p c` | Compile from the project root |
| `C-x p a` | `php artisan …` (with completion) |
| `C-c t` | Terminal in the project root (vterm) |
| `C-c d d` / `C-c d b` | Debugger (dape) / toggle breakpoint |

Default `compile-command`: `nob.c` → `./nob`, else `build.sh`, `Makefile`,
`CMakeLists.txt`, else gcc/g++ on the single file. A `.dir-locals.el` wins:

```elisp
((nil . ((compile-command . "make -j && ./main"))))
```

Snippets (type the word, then `TAB`): `cp` (competitive programming template),
`main`, `nob`, and for C/C++ `for`, `fori`, `if`, `ife`, `elif`, `while`, `sw`,
`st` (typedef struct), `inc`, `incq`, `once` (include guard), `pr` (printf), `todo`.

### rexim's own keys

| Key | Does |
|---|---|
| `C-x C-g` | Open the file or URL at point |
| `C-c i m` | Functions in this file (imenu) |
| `C-c m s` / `C-c m l` | magit status / log |
| `C-c M-q` | Unfill: join a paragraph into one line |
| `C-c s` | Search the project for the selection (or symbol at point) |
| `C-c T` | Insert a timestamp `(20261110-130512)` |
| `C-c C-j` | In Emacs Lisp: evaluate and print the result below |
| `M-x my/copy-org-link-here` | Copy an org link to this file and line |
| `M-x my/toggle-transparency` | Make the frame see-through |

### Code (when a language server is running)

| Key | Does |
|---|---|
| `C-c l a` / `r` / `f` / `o` | Code actions / rename / format / organize imports |
| `C-c ! n` / `p` / `l` | Next / previous / list diagnostics |
| `C-x g` | magit (`C-c g b` blame, `C-c g n`/`p` next/prev change, `C-c g r` revert hunk) |

### Leader (`SPC` with evil, `C-c SPC` without)

Doom layout, so Doom habits carry over:

| Key | Does | Key | Does |
|---|---|---|---|
| `SPC SPC` | project file | `SPC ,` | buffer |
| `SPC .` | file | `SPC /` | ripgrep project |
| `SPC TAB` | last buffer | `SPC r` | recompile |
| `SPC m r` | run this file | `SPC p a` | artisan |
| `SPC g g` | magit | `SPC o t` | terminal |
| `SPC s s` | search buffer | `SPC s i` | functions |
| `SPC c a` | code action | `SPC c r` | rename |
| `SPC w` | windows… | `SPC b` / `SPC f` | buffers… / files… |

which-key shows everything else after a short pause.

---

## Languages

eglot (built-in LSP) starts by itself when the server is installed. Format on save
uses apheleia (clang-format, gofumpt, ruff/black, prettier, …) and quietly skips
formatters you don't have (toggle per buffer: `C-c SPC c F`). Tree-sitter
grammars are installed by `setup.sh`, or offered on first use.

| Language | Server | Notes |
|---|---|---|
| C / C++ | clangd | `C-c C-o` switches `.c` ↔ `.h`. A `compile_commands.json` helps (`bear -- make`) |
| Go | gopls + gofumpt | Organizes imports on save, uses tabs |
| PHP / Laravel | intelephense (phpactor fallback) | Blade files use web-mode, `C-x p a` runs artisan |
| Python | basedpyright / pyright / pylsp | |
| JS / TS | typescript-language-server | |
| Rust | rust-analyzer | |
| Zig | zls | |
| Lua, Haskell | lua-language-server, haskell-language-server | if installed |
| Web, JSON, YAML, TOML, Markdown, Nix, Docker, CMake, Kotlin, GLSL, CSV, nginx, Graphviz, sh | modes only | |

C/C++ formatting only runs when the project has a `.clang-format` file.
Without one, clang-format's default style would rewrite your whole file on
every save. Big files (over 256 KB) never start a language server, never get
formatted, and C/C++ ones open in simpc-mode.

## What's from rexim's config

I read through [rexim/dotfiles](https://github.com/rexim/dotfiles)
(`.emacs`, `.emacs.rc/*.el`, `.emacs.local/`, `.emacs.snippets/`). His
dotfiles repo has no license, so nothing is copied from it: the ideas are
written fresh here. The one exception is **simpc-mode**, his fast C mode,
which has its own MIT-licensed repo and is bundled in `site-lisp/simpc-mode/`
with its license.

| rexim has | Here |
|---|---|
| gruber-darker, Iosevka 20, no tool/menu/scroll bars | same |
| relative line numbers everywhere | same, in code/text/config buffers |
| ido + smex for files, buffers, `M-x` | vertico + orderless + consult (same feel, works for every prompt, live preview) |
| company | corfu (lighter, same idle completion) |
| multiple-cursors with `C->` `C-<` `C-c C-<` `C-S-c C-S-c` `C-"` `C-:` | same keys |
| move-text on `M-p` / `M-n` | same, plus re-indent after moving |
| `C-,` duplicate line | same (Emacs 29's `duplicate-dwim`, also does regions) |
| `simpc-mode` for all C/C++ | `my/c-mode`: `auto` (default) uses tree-sitter/cc-mode, and simpc for files over 256 KB. `simpc` = exactly rexim |
| whitespace-mode in code, trailing space deleted on save | `my/whitespace-style`: `light` (default) or `rexim` (dots for every space, like his streams) |
| `compile` with ANSI colours, `compilation-scroll-output` | same, plus `C-c r` recompile and smart default commands |
| dired-x, `dired-dwim-target`, `-alh` | same, plus directories first and one dired buffer at a time |
| windmove on `S-<arrows>` | same |
| paredit in Lisp buffers, `C-c C-j` eval-print | same (paredit leaves `M-s`/`M-?` alone) |
| yasnippet with his own snippets | yasnippet with similar C snippets written fresh (`for`, `if`, `once`…) |
| `C-x C-g` ffap, `C-c i m` imenu, `C-c m s`/`l` magit, `C-c M-q` unfill | same keys |
| `C-x p d` timestamp, `C-x p s` rgrep selection | moved to `C-c T` and `C-c s`, because Emacs 28+ uses `C-x p` for projects |
| org agenda/capture | `C-c o a` / `C-c o c` (his `C-c c` is compile here) |
| autocommit-rc.el (git-synced agenda) | `my/autocommit-mode`, rewritten: see below |
| magit, editorconfig, many language modes | same, lazily loaded |
| haskell, rust, lua, nix, go, php, kotlin, glsl, cmake, … modes | same (`my/extra-languages`) |

Left out on purpose: helm (replaced by consult), his toy-language modes
(porth, basm, noq, jai…), Coq/Proof General, tide (eglot does TypeScript), and
`confirm-kill-emacs` (your Doom config turned it off).

## Notes that back themselves up

rexim keeps his agenda in a git repo that commits and pushes on every save.
Here that's `my/autocommit-mode`:

```
M-x my/autocommit-init RET ~/org/ RET
```

After that, every file under `~/org/` commits a few seconds after you save. Ten
quick saves make one commit, and it pushes in the background. When you open the
first file there in a session, it pulls first. Offline? Run
`M-x my/autocommit-toggle-push` to commit without pushing. It adds itself to
`.dir-locals.el` without touching what's already there. If a run fails, the
git output is in the ` *autocommit*` buffer.

## Customizing

Put machine-local settings in `personal.el` (git-ignored, loaded before everything):

```elisp
(setq my/use-evil t                  ; Vim keys
      my/fonts '("Iosevka" "JetBrains Mono")
      my/font-size 18
      my/start-server nil)
```

| Option | Default | What it does |
|---|---|---|
| `my/use-evil` | `nil` | Vim keys + `SPC` leader |
| `my/fonts`, `my/font-size` | Iosevka, 20 | First installed font wins |
| `my/c-mode` | `auto` | `auto` / `simpc` (rexim) / `cc` |
| `my/c-big-file-size` | 256 KB | Above this: simpc, no LSP, no formatting, no whitespace-mode |
| `my/whitespace-style` | `light` | `light` / `rexim` / `nil` |
| `my/use-paredit` | `t` | Structural editing in Lisp buffers |
| `my/extra-languages` | `t` | Rust, Zig, Lua, Haskell, Kotlin… modes |
| `my/start-server` | `t` | So `emacsclient` opens files in this Emacs |
| `my/autocommit-delay`, `my/autocommit-push` | 5 s, `t` | Autocommit tuning |
| `my/snapshots-keep` | 5 | Package snapshots kept by `my/upgrade` |

Everything else is one topic per file in `lisp/`:

```
early-init.el          startup speed, frame setup
init.el                knobs + module loading
lisp/init-package.el   package.el + use-package
lisp/init-perf.el      GC, redisplay, process I/O
lisp/init-defaults.el  built-in settings, history, backups
lisp/init-ui.el        theme, font, line numbers
lisp/init-completion.el vertico, orderless, consult, embark, corfu
lisp/init-navigation.el windows, avy, project, ibuffer
lisp/init-editing.el   multiple cursors, move-text, snippets, folding
lisp/init-evil.el      optional Vim layer
lisp/init-dev.el       eglot, tree-sitter, flymake, apheleia, dape
lisp/init-compile.el   compile loop, run-file, CP, artisan
lisp/init-langs.el     per-language settings
lisp/init-rexim.el     rexim's habits: simpc, whitespace, paredit, his keys
lisp/init-git.el       magit, diff-hl
lisp/init-tools.el     dired, vterm, docker, org, server
lisp/init-keys.el      global keys + leader map
lisp/init-maint.el     doctor, snapshots, upgrade, rollback
lisp/my-autocommit.el  commit-on-save for notes repos
site-lisp/simpc-mode/  rexim's simpc-mode (MIT, with its LICENSE)
snippets/              your yasnippets
test/                  smoke tests (./test/run.sh)
doom/                  the Doom version of this config
```

To add a package, put a `use-package` block in the right `lisp/` file. It
installs on the next start, and if it ever fails to install, the block is
skipped instead of breaking Emacs.

## Keeping it working for decades

Packages change, Emacs changes, machines change. These are the habits and
tools that keep the config alive:

| When | Do | What it does |
|---|---|---|
| Every month or two | `./setup.sh --update` (or `M-x my/upgrade`) | Pulls this repo, **snapshots** the installed packages, upgrades everything, updates grammars |
| An upgrade broke something | `M-x my/rollback` | Puts the previous snapshot back and restarts Emacs. The broken set is kept in `elpa.broken/` |
| Something feels off | `./setup.sh --doctor` (or `M-x my/doctor`) | Lists Emacs features, missing packages, grammars, language servers and tools, each with a fix |
| Startup got slow | `M-x my/benchmark-startup` | Times a clean load. Then set `use-package-compute-statistics` to `t`, restart, `M-x use-package-report` |
| You changed the config | `make test` | Loads the config and runs the smoke tests (C modes, compile commands, keys, autocommit…) |
| New machine | `./setup.sh` | Same setup in one command |
| New Emacs release | nothing | CI already tests it every week |

**CI.** `.github/workflows/ci.yml` installs every package from scratch on Emacs
29, 30 and the development snapshot, runs the tests, byte-compiles the config
and shellchecks the scripts. It does this on every push and every Monday, so
when an upstream package breaks or Emacs changes, you hear about it from a
red check, not from a broken editor on a deadline.

**Rules that keep it maintainable:**

- One topic per file in `lisp/`. Machine-specific settings go only in `personal.el`.
- Prefer built-ins (eglot, project.el, tree-sitter, which-key in 30, editorconfig
  in 30). They don't disappear.
- Every package is lazy and optional. If one dies upstream, delete its block
  and nothing else breaks.
- Commit `personal.example.el` changes and keep secrets out of the repo.
- `make` lists the shortcuts: `make update`, `make doctor`, `make test`, `make clean`.

### Using Doom instead

Link `doom/` to `~/.config/doom` and run `doom sync`. Changes from the original files:
`+treesitter` → `+tree-sitter` (Doom's real flag name), `IS-MAC` →
`(featurep :system 'macos)`, company → `(corfu +orderless)`, plus
`multiple-cursors`/`ibuffer`. The C compile command now respects `.dir-locals.el`
and knows `nob.c`, `my/cp-run` works without `input.txt`, Go organize-imports no
longer errors before LSP starts, and `SPC j` (avy) and `-` (dired) are added.

## Troubleshooting

| Problem | Fix |
|---|---|
| "Failed to install X" on start | Network/proxy issue. Emacs retries every start; or `M-x package-refresh-contents` then `M-x package-install` |
| No language server ("eglot: no server") | Install the server from the table above and make sure it's on `PATH` (on macOS from the Dock, `exec-path-from-shell` copies your shell's PATH) |
| `M-s r` does nothing | Install ripgrep (`rg`) |
| Popup completion missing in a terminal | Works in GUI. In `emacs -nw` on Emacs < 31 it uses corfu-terminal |
| Font isn't Iosevka | `fc-list \| grep -i iosevka`; set `my/fonts` in `personal.el` |
| Something's broken after editing config | `emacs --debug-init` shows the exact error |
| Upgrade broke something | `M-x my/rollback`, pick the latest snapshot |
| Not sure what's wrong | `./setup.sh --doctor` |
| Huge C file is slow | It should open in simpc-mode (check the mode line). Lower `my/c-big-file-size` |
| clang-format didn't run | Add a `.clang-format` to the project (`clang-format -style=llvm -dump-config > .clang-format`) |
| Start over | `make clean` (packages and caches; keeps history) and start Emacs |

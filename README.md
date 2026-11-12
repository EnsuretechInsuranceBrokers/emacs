# dotfiles

Three separate folders. Each one has its own README and setup script, and none
depends on living inside another.

| Folder | What | Start here |
|---|---|---|
| [`emacs/`](emacs/) | A fast, keyboard-first Emacs config (gruber-darker, Vim keys while you learn Emacs keys, compile loop, LSP). Only this folder is linked to `~/.config/emacs` | [`emacs/README.md`](emacs/README.md) |
| [`fedora-rice/`](fedora-rice/) | Rices a fresh Fedora Workstation around it: dark GNOME, gruber-darker terminal/tmux/zsh, keyboard-first shortcuts, and systemd timers that update Emacs on the fourth Sunday of every month | [`fedora-rice/README.md`](fedora-rice/README.md) |
| [`doom/`](doom/) | The old Doom Emacs version of the same setup | `doom/config.el` |

Just Emacs, on macOS, Ubuntu/Debian, Fedora, Arch or openSUSE:

```bash
git clone https://github.com/EnsuretechInsuranceBrokers/emacs.git ~/src/emacs-config && ~/src/emacs-config/emacs/setup.sh
```

The whole Fedora desktop (also runs the Emacs setup):

```bash
git clone https://github.com/EnsuretechInsuranceBrokers/emacs.git ~/src/emacs-config && ~/src/emacs-config/fedora-rice/rice.sh
```

Tests run on every push and every Monday on Emacs 29, 30 and the development
version ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)).

---

# Keybindings

Everything important, on one page. Inside Emacs, `SPC ?` (or `C-c SPC ?`)
shows a Vim → Emacs cheat sheet, and after any prefix key (`SPC`, `C-x`,
`C-c`…) which-key lists what comes next.

### How to read the keys

| Written | macOS | Fedora |
|---|---|---|
| `C-` | Control (Caps Lock after `--keyboard` / the rice) | Control (Caps Lock after the rice) |
| `M-` | **Cmd** | **Alt** |
| `s-` | **Option** | Super (Windows key) |
| `S-` | Shift | Shift |
| `RET` / `SPC` / `DEL` / `TAB` | Return / Space / Backspace / Tab | same |

`C-x b` means: hold Control, press x, let go, press b. `SPC f f` means: in Vim
normal mode press Space, then f, then f. Keys that differ between macOS and
Fedora come from `emacs/lisp/init-platform.el` (macOS block active by
default; `./emacs/setup.sh --platform fedora` switches).

**Vim keys are on by default.** In Vim normal mode these keep their Vim
meaning: `C-w C-o C-i C-d C-u C-f C-b C-e C-y C-v C-r C-n C-p C-. M-.`
(so use `gd` for "go to definition" there). Every other key below works in
normal mode too, and all of them work in insert mode, with Vim keys off
(`C-c v`), or in a buffer switched to Emacs keys (`C-z`).

## Multiple cursors (VSCode-style)

| Do | macOS | Fedora | Any system |
|---|---|---|---|
| Add a cursor where you click (click it again to remove it) | **Option-click** | **Alt-click** | `C-S-` click |
| Add a cursor on the line above | **Cmd-Option-Up** | **Ctrl-Alt-Up** | |
| Add a cursor on the line below | **Cmd-Option-Down** | **Ctrl-Alt-Down** | |
| Box-select with the mouse → one cursor per line | **Shift-Option-drag** | **Shift-Alt-drag** | |
| A cursor on every line of the selection | | | `C-S-c C-S-c` |
| Also select the next match (VSCode Ctrl/Cmd+D) | | | `C->` |
| Also select the previous match | | | `C-<` |
| Select every match (VSCode Ctrl+Shift+L) | | | `C-c C-<` |
| Skip this match, go to the next / previous | | | `C-"` / `C-:` |
| Back to one cursor | | | `Esc` or `C-g` |

While there are several cursors, typing, `DEL`, `RET` (a newline everywhere),
`C-a`, `C-e`, `M-f`, `M-b`, `C-k` and paste work at every cursor. With Vim keys
on, the cursors type in Emacs state and you're back in normal mode after
`Esc`. From Vim: `V`, `j j j`, then `C-S-c C-S-c` puts a cursor on each line.

## Line numbers

Relative numbers count up and down from the cursor, and the cursor's own line
shows its real number in bold yellow (rexim's setup):

```
  2  int total = 0;
  1  for (int i = 0; i < n; i++) {
 42      total += a[i];        <- the cursor is on line 42
  1  }
  2  return total;
```

`5j`/`5k` (Vim) or `C-u 5 C-n`/`C-u 5 C-p` (Emacs) jump exactly to the line marked 5.
`SPC t l` turns numbers off and on in this buffer. They're on everywhere except
terminals, images and files over 1 MB.

## Leader (`SPC` in Vim normal mode, `C-c SPC` anywhere, `M-SPC` in insert mode)

| Key | Does | Key | Does |
|---|---|---|---|
| `SPC SPC` | file in this project | `SPC ,` | switch buffer |
| `SPC .` | open file | `SPC /` | search the project (ripgrep) |
| `SPC *` | search the project for the word under the cursor | `SPC TAB` | previous buffer |
| `SPC r` | recompile (rerun the last build) | `SPC :` | `M-x` |
| `SPC ?` | Vim → Emacs cheat sheet | `SPC x` | scratch buffer |
| `SPC q` | quit Emacs | `SPC u` | prefix argument |

| Group | Keys |
|---|---|
| `SPC b` buffers | `b` switch · `k` kill · `K` kill all others · `i` ibuffer · `l` previous · `r` revert · `s` save |
| `SPC f` files | `f` open · `r` recent · `s` save · `R` rename · `D` delete · `y` copy path · `u` reopen as root · `p` open init.el |
| `SPC s` search | `s` this buffer · `S` all buffers · `p` project · `d` this directory · `i` functions · `I` functions in all buffers · `g` git grep · `f` find file · `o` outline · `r` replace (regexp) |
| `SPC p` project | `f` file · `p` switch project · `g` grep · `b` buffer · `c` compile · `D` dired · `d` find a directory · `m` magit · `a` **artisan** · `e` eshell |
| `SPC c` code | `c` compile · `a` code action · `r` rename · `f` format · `F` format-on-save on/off · `o` organize imports · `d` definition · `D` references · `x` errors list · `k` stop the build |
| `SPC g` git | `g` magit · `b` blame · `l` log of this file · `f` file actions · `n`/`p` next/previous change · `r` revert change · `s` show change |
| `SPC o` open | `t` terminal (project root) · `T` terminal in other window · `d` / `-` dired · `e` eshell · `D` docker · `a` agenda · `c` capture |
| `SPC w` windows | `w` pick window · `s` split below · `v` split right · `d` close · `o` only this · `h j k l` move · `u`/`r` undo/redo layout · `=` balance |
| `SPC m` this file | `r` **run this file** (C++ with input.txt) · `i` open input.txt · `c` compile |
| `SPC d` debug | `d` start debugger · `b` toggle breakpoint |
| `SPC t` toggles | `e` **Vim keys** · `l` line numbers · `f` format on save · `w` whitespace · `v` word wrap · `r` read-only · `t` transparency · `c` autocommit |
| `SPC h` help | `k` what does this key do · `f` function · `v` variable · `m` this mode |

## Vim extras (normal mode)

| Key | Does |
|---|---|
| `-` | file browser (dired) on this file's folder, like oil.nvim / vinegar |
| `gs` or `C-;` | jump: type 1–2 characters, then the label (like flash.nvim / leap) |
| `gcc` / `gc` (visual) | comment line / selection |
| `cs"'` · `ysiw)` · `ds(` | change / add / delete surrounding quotes and brackets |
| `gd` · `K` · `C-o` / `C-i` | definition · docs for the symbol (language server) · jump back / forward |
| `]b [b` · `]q [q` | next/previous buffer · next/previous error (unimpaired) |
| `:w :q :W :Q` | save / quit (typo-proof) |
| `C-z` | this buffer: Vim keys ↔ Emacs keys |
| `C-c v` | everywhere: Vim keys off / on (practise Emacs keys) |

## Moving around

| Key | Does |
|---|---|
| `C-x b` | switch buffer, recent file or bookmark (live preview; `< b` / `< f` / `< p` narrows) |
| `C-c b` | previous buffer (toggle) |
| `C-x C-f` | open file (`DEL` goes up a whole folder, `~/` jumps home) |
| `C-x C-r` | recent files |
| `C-x p f` / `C-x p p` / `C-x p b` | project file / switch project / project buffer |
| `M-s r` / `C-x p g` | search the project (ripgrep) |
| `C-c s` | search the project for the selection or the word under the cursor |
| `M-s l` / `M-s L` | search this buffer / all buffers |
| `C-s` / `C-r` | search forward / backward as you type (`C-;` there: jump to any match) |
| `M-g i` / `M-g I` (or `C-c i m`) | jump to a function in this file / in all buffers |
| `M-g g` | go to line |
| `C-;` or `M-j` | jump to any visible spot: type 1–2 chars, then the label |
| `M-g w` / `M-g l` | jump to a word / line by label |
| `M-.` / `M-,` / `M-?` | go to definition / back / find references |
| `C-x C-g` | open the file or URL under the cursor |
| `C-a` | first non-blank character; press again for column 0 |
| `M-<` / `M->` | top / bottom of the buffer |
| `C-x C-j` | dired here (`-` up, `C-c C-e` rename files by editing text) |
| `C-x C-b` | buffer list, grouped by project |
| `C-x k` / `C-x K` | close this buffer / close all other file buffers |

## Dired (file manager)

Open it with `-` (Vim normal mode), `C-x C-j` (this file's folder), or `SPC o d`.

| Key | Does |
|---|---|
| `RET` / `-` (or `^`) | open file or folder / go up |
| `TAB` / `S-TAB` | **expand a folder inline as a tree** / cycle how deep |
| `P` | **preview** the file under the cursor in the other window (as you move) |
| `/` (Emacs keys) · `F` (Vim keys) | **filter** the list as you type; `g` brings everything back |
| `)` | show each file's **last git commit** |
| `(` | show / hide details (size, date, permissions); hidden by default |
| `E` | open in the default app (macOS `open`, Fedora `xdg-open`) |
| `C` / `R` / `D` | copy / rename-or-move / delete (to the Trash), in the background |
| `+` | new folder |
| `m` / `u` / `U` | mark / unmark / unmark all (`C`, `R`, `D`, `E` act on all marked files) |
| `C-c C-e` (Emacs) · `i` (Vim) | rename files by editing the text, `C-c C-c` to apply |
| `C-x M-o` | show / hide dotfiles |
| `!` / `&` | run a shell command on the file / in the background |
| drag a file | drag it out of Emacs into another app |

With two dired windows side by side, copy and move default to the other
window's folder, like a two-pane file manager. Files are coloured by type and
have icons; `setup.sh` installs the icon font.

## Windows

| Key | Does |
|---|---|
| `M-o` | next window (with 3+ windows: pick one by letter) |
| `S-<arrows>` | window to the left / right / up / down |
| `C-x 3` / `C-x 2` | split right / below and move there |
| `C-x 1` / `C-x 0` | only this window / close this window |
| `C-c <left>` / `C-c <right>` | undo / redo a window change |
| `C-c =` / `C-c -` | bigger / smaller font everywhere |

## Editing

| Key | Does |
|---|---|
| `M-p` / `M-n` | move the line (or selection) up / down |
| `C-,` | duplicate the line (or selection) |
| `M-w` | copy the selection, or the **whole line** if nothing is selected (like `yy`) |
| `C-w` | cut the selection, or delete the word before the cursor |
| `C-y` / `M-y` | paste / pick from everything you copied |
| `C-/` / `C-?` / `C-x u` | undo / redo / visual undo tree |
| `C-=` / `C-+` | grow / shrink the selection (word → string → block → function) |
| `C-o` / `C-S-o` | new line below / above |
| `C-c f` / `C-c F` | fold this block / fold everything |
| `M-;` / `C-x C-;` | comment selection / comment line |
| `M-%` / `C-M-%` | replace / replace with regexp (`!` = all) |
| `C-x SPC` | box (rectangle) selection; `C-x r t` types into every line of it |
| `F3` … `F4`, then `F4 F4 F4` | record a keyboard macro, then replay it |
| `C-.` | actions on the thing at point (embark) |
| `M-/` | complete the word from other text in your buffers |
| `TAB` | indent, or complete (the popup also appears by itself after 2 chars) |
| `C-c M-q` | join a paragraph into one line |
| `C-c T` | insert a timestamp |
| `C-c y` | copy this file's path |
| `C-c R` | rename this file |

## Build and run

| Key | Does |
|---|---|
| `C-c c` | compile: asks for the command once, remembers it |
| `C-c r` or `F5` | **recompile**: rerun the last build, no questions |
| `C-c x` | **run this file**: C++ (`-O2`, reads `input.txt`), C, Go, Python, PHP, JS, shell |
| `C-c i i` | open `input.txt` next to this file |
| `M-g n` / `M-g p` | next / previous error, in the source |
| `M-g e` | list of all errors |
| `C-x p c` | compile from the project root |
| `C-x p a` | `php artisan …` from the project root |
| `C-c t` | terminal in the project root |
| `C-c d d` / `C-c d b` | debugger / toggle breakpoint |
| `C-c C-o` (C/C++) | switch between `.c` and `.h` |

## Code (language server)

| Key | Does |
|---|---|
| `C-c l a` | code actions (quick fixes) |
| `C-c l r` | rename everywhere |
| `C-c l f` | format the buffer |
| `C-c l o` | organize imports |
| `C-c l i` / `C-c l t` | go to implementation / type definition |
| `C-c l d` | documentation for the symbol |
| `C-c ! n` / `C-c ! p` / `C-c ! l` | next / previous / list errors and warnings |

## Git

| Key | Does |
|---|---|
| `C-x g` or `C-c m s` | magit status (`s` stage, `c c` commit, `P u` push, `F u` pull, `?` help) |
| `C-c g b` | blame |
| `C-c g l` or `C-c m l` | log |
| `C-c g n` / `C-c g p` | next / previous changed hunk |
| `C-c g s` / `C-c g r` | show / revert this hunk |

## Org and notes

| Key | Does |
|---|---|
| `C-c o a` / `C-c o c` / `C-c o l` | agenda / capture / store a link |
| `M-x my/autocommit-init` | make a folder (e.g. `~/org`) commit and push itself on every save |

## Escape hatches

| Key | Does |
|---|---|
| `C-g` (or `Esc`) | cancel anything |
| `C-h k` then a key | what does this key do? |
| `C-h B` | every key binding, searchable |
| `M-x my/doctor` | health report (also `./emacs/setup.sh --doctor`) |
| `M-x my/rollback` | undo the last package upgrade |

The full documentation is in [`emacs/README.md`](emacs/README.md).

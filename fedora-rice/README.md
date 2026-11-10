# Fedora rice

Turns a fresh **Fedora Workstation** (GNOME) into a dark, quiet,
keyboard-first desktop built around this Emacs config, and keeps Emacs
updated by itself every month.

```bash
git clone https://github.com/EnsuretechInsuranceBrokers/emacs.git ~/src/emacs-config
```

```bash
~/src/emacs-config/fedora-rice/rice.sh
```

Then log out and back in. Want to see first? Add `--dry-run`: it prints
every command and changes nothing.

## What you get

| Area | Changes |
|---|---|
| **dnf** | 10 parallel downloads, `y` as the default answer. Optional: RPM Fusion (`--rpmfusion`), full Flathub (`--flathub`) |
| **Packages** | zsh + autosuggestions + syntax highlighting, alacritty, tmux, ripgrep, fd, fzf, bat, eza, zoxide, btop, git-delta, jq, tldr, fastfetch, wl-clipboard, gnome-tweaks, adw-gtk3 (dark GTK3 apps) |
| **Look** | Dark mode everywhere, yellow accent (GNOME 47+), solid `#181818` wallpaper, Iosevka as the monospace font, gruber-darker in the terminal, tmux, fzf, prompt and bat. Matches Emacs |
| **Speed** | Animations off, hot corner off, key repeat at 200 ms / 40 per second |
| **Keyboard** | Caps Lock → Ctrl (your other keyboard options are kept). `Super+Return` terminal, `Super+E` Emacs, `Super+1..4` workspaces, `Super+Shift+1..4` move window, `Super+Q` close, `Super+F` fullscreen. 4 fixed workspaces |
| **Shell** | zsh as login shell, with Emacs-style line editing (same keys you're learning), a prompt that shows the git branch, `z` to jump to directories, `C-r` fuzzy history, `C-t` fuzzy files, `e file` opens in Emacs |
| **git** | delta for diffs, `zdiff3` conflicts, `pull.ff only`, auto upstream on first push, rerere, histogram diffs. Only for settings you haven't already set |
| **Emacs** | Runs `emacs/setup.sh --daemon` (the sibling folder, or a fresh clone if this folder was copied on its own). That also switches `emacs/lisp/init-platform.el` from its macOS block to the **Fedora block** (Alt-click cursors, font 20, Wayland typing-lag fix…); see [what to change on Fedora](../emacs/README.md#on-your-fedora-machine-what-to-change). Plus: Emacs, Iosevka, language servers, all packages, and Emacs as a background service so `Super+E` opens instantly |
| **Updates** | systemd timers on the fourth Sunday of every month, below |

Everything it replaces is backed up as `<file>.bak-<date>`. `~/.zshrc` isn't
replaced: one `source` line is added to it, and the settings live in
`~/.config/zsh/rice.zsh`.

## Monthly Emacs update (systemd)

Two timers, both on the **fourth Sunday of every month**:

| Time | Unit | Runs as | Does |
|---|---|---|---|
| 03:30 | `emacs-update-system.timer` | root | `dnf upgrade --refresh emacs*`: the Emacs program from Fedora |
| 04:00 | `emacs-update.timer` | you | `emacs/setup.sh --update`: pulls this repo (only if you have no local changes), **snapshots** your packages, upgrades them, updates tree-sitter grammars. A desktop notification says whether it worked |

"Fourth Sunday" is `OnCalendar=Sun *-*-22..28`: the fourth Sunday of a month
always falls on day 22–28. Both timers are `Persistent=true`, so if the
machine is off or you're logged out at that time, the update runs at the
next boot or login.

If an update breaks something, `M-x my/rollback` in Emacs restores the
snapshot taken just before it.

```bash
systemctl list-timers emacs-update-system.timer
```

```bash
systemctl --user list-timers emacs-update.timer
```

```bash
systemctl --user start emacs-update          # run the update now
```

```bash
journalctl --user -u emacs-update            # what the last update did
```

```bash
./fedora-rice/rice.sh --only-timer                # install just the timers
```

```bash
./fedora-rice/rice.sh --remove-timers             # uninstall them
```

To run the user update even while you're logged out, enable lingering:
`loginctl enable-linger "$USER"`. You won't see the notification then, but
it's in the journal.

## Options

| Option | Effect |
|---|---|
| `--dry-run` | Print every command, change nothing |
| `-y` | Don't ask before using sudo |
| `--no-dnf` `--no-gnome` `--no-dotfiles` `--no-shell` `--no-git` `--no-emacs` `--no-timer` | Skip that step |
| `--only-timer` / `--remove-timers` | Just install / uninstall the update timers |
| `--rpmfusion` | Enable RPM Fusion free + nonfree (codecs, NVIDIA drivers) |
| `--flathub` | Enable the full Flathub instead of Fedora's filtered one |
| `--emacs-keys` | Plain Emacs keys instead of Vim keys in Emacs |
| `--force` | Run on something that isn't Fedora (most steps still assume dnf/GNOME) |

## Files

```
rice.sh                          the script
dotfiles/alacritty/alacritty.toml -> ~/.config/alacritty/
dotfiles/tmux/tmux.conf          -> ~/.config/tmux/
dotfiles/zsh/rice.zsh            -> ~/.config/zsh/ (sourced from ~/.zshrc)
dotfiles/bat/config              -> ~/.config/bat/
systemd/emacs-update-system.*    -> /etc/systemd/system/
systemd/emacs-update.*           -> ~/.config/systemd/user/ (paths filled in)
```

Edit the files here and re-run `./fedora-rice/rice.sh --no-dnf` to apply your
changes. Unchanged files are skipped, changed ones are backed up first.

## Undo

- **GNOME settings:** GNOME Settings / Tweaks, or `gsettings reset <schema> <key>`
  (for example `gsettings reset org.gnome.desktop.interface enable-animations`).
- **Dotfiles:** restore the `*.bak-<date>` copies.
- **Shell:** `sudo usermod -s /bin/bash "$USER"`.
- **Timers:** `./fedora-rice/rice.sh --remove-timers`.
- **dnf.conf:** delete the two lines it appended to `/etc/dnf/dnf.conf`.

## Notes

- Built for Fedora Workstation (GNOME). On KDE or other spins, the GNOME step
  skips itself and everything else still works.
- The tmux prefix stays `C-b`. Escape-time is 0, so Vim keys in Emacs/nvim
  inside tmux don't lag.
- `EDITOR` is set to `emacsclient -t`, so git commit messages open in Emacs
  inside the terminal.

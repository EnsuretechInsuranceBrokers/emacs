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

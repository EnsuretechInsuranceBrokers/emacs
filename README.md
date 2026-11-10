# dotfiles

| Folder | What | Start here |
|---|---|---|
| [`emacs/`](emacs/) | A fast, keyboard-first Emacs config (gruber-darker, Vim keys while you learn Emacs keys, compile loop, LSP). This folder alone is linked to `~/.config/emacs` | [`emacs/README.md`](emacs/README.md) |
| [`doom/`](doom/) | The old Doom Emacs version of the same setup | `doom/config.el` |

One command sets up Emacs on macOS, Ubuntu/Debian, Fedora, Arch or openSUSE:

```bash
git clone https://github.com/EnsuretechInsuranceBrokers/emacs.git ~/src/emacs-config && ~/src/emacs-config/emacs/setup.sh
```

Tests run on every push and every Monday on Emacs 29, 30 and the development
version ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)).

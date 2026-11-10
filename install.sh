#!/usr/bin/env bash
# Link this repo as your Emacs config.  Backs up whatever is there first.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="${XDG_CONFIG_HOME:-$HOME/.config}/emacs"
stamp="$(date +%Y%m%d-%H%M%S)"

backup() {
  if [ -e "$1" ] || [ -L "$1" ]; then
    if [ "$(readlink "$1" 2>/dev/null)" = "$repo" ]; then return; fi
    echo "Backing up $1 -> $1.bak-$stamp"
    mv "$1" "$1.bak-$stamp"
  fi
}

# ~/.emacs and ~/.emacs.d win over ~/.config/emacs, so move them aside.
backup "$HOME/.emacs"
backup "$HOME/.emacs.el"
backup "$HOME/.emacs.d"
backup "$target"

mkdir -p "$(dirname "$target")"
ln -s "$repo" "$target"
echo "Linked $target -> $repo"

[ -f "$repo/personal.el" ] || cp "$repo/personal.example.el" "$repo/personal.el"

echo
echo "Optional tools (the config works without them):"
for t in rg fd git clangd gopls gofumpt intelephense node pandoc cmake direnv; do
  if command -v "$t" >/dev/null 2>&1; then echo "  [x] $t"; else echo "  [ ] $t"; fi
done
echo
echo "Start Emacs once with network access; it installs its packages (1-2 min)."

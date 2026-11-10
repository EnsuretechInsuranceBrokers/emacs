#!/usr/bin/env bash
# Rice a fresh Fedora Workstation around this Emacs config.
#
#   ./fedora-rice/rice.sh                everything below
#   ./fedora-rice/rice.sh --dry-run      show every command, change nothing
#   ./fedora-rice/rice.sh --only-timer   just the monthly Emacs update timers
#   ./fedora-rice/rice.sh --help         all options
#
# What it does (each step can be skipped, see --help):
#   dnf      faster dnf (parallel downloads), CLI tools, zsh plugins, alacritty
#   gnome    dark theme, gruber-darker solid wallpaper, Iosevka, no animations,
#            Caps->Ctrl, fast key repeat, 4 fixed workspaces on Super+1..4,
#            Super+Return terminal, Super+E Emacs, Super+Q close, tap to click
#   dotfiles alacritty, tmux, zsh and bat configs in gruber-darker
#   shell    zsh as your login shell
#   git      delta pager and sane defaults (only settings you haven't set)
#   emacs    emacs/setup.sh --daemon (Emacs, fonts, language servers, packages)
#   timer    systemd timers: update Emacs on the fourth Sunday of every month
#
# Safe to re-run.  Files it replaces are backed up as *.bak-<date>.

set -euo pipefail

# ---------------------------------------------------------------- options
DO_DNF=1 DO_GNOME=1 DO_DOTFILES=1 DO_SHELL=1 DO_GIT=1 DO_EMACS=1 DO_TIMER=1
RPMFUSION=0 FLATHUB=0 DRY=0 YES=0 FORCE=0 REMOVE_TIMERS=0
EMACS_ARGS=()

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
  cat <<'EOF'

Options:
  --no-dnf --no-gnome --no-dotfiles --no-shell --no-git --no-emacs --no-timer
                   skip that step
  --only-timer     install only the monthly update timers
  --remove-timers  uninstall the update timers and exit
  --rpmfusion      also enable RPM Fusion (free + nonfree: codecs, drivers)
  --flathub        also enable the full (unfiltered) Flathub
  --emacs-keys     pass to setup.sh: plain Emacs keys instead of Vim keys
  --force          run even if this doesn't look like Fedora
  -y, --yes        don't ask before using sudo
  --dry-run        print the commands instead of running them
EOF
}

for arg in "$@"; do
  case "$arg" in
    --no-dnf) DO_DNF=0 ;;
    --no-gnome) DO_GNOME=0 ;;
    --no-dotfiles) DO_DOTFILES=0 ;;
    --no-shell) DO_SHELL=0 ;;
    --no-git) DO_GIT=0 ;;
    --no-emacs) DO_EMACS=0 ;;
    --no-timer) DO_TIMER=0 ;;
    --only-timer) DO_DNF=0 DO_GNOME=0 DO_DOTFILES=0 DO_SHELL=0 DO_GIT=0 DO_EMACS=0 DO_TIMER=1 ;;
    --remove-timers) REMOVE_TIMERS=1 ;;
    --rpmfusion) RPMFUSION=1 ;;
    --flathub) FLATHUB=1 ;;
    --emacs-keys) EMACS_ARGS+=(--emacs-keys) ;;
    --force) FORCE=1 ;;
    -y|--yes) YES=1 ;;
    --dry-run) DRY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg (see --help)"; exit 1 ;;
  esac
done

# ---------------------------------------------------------------- helpers
if [ -t 1 ]; then B=$'\e[1m' G=$'\e[32m' Y=$'\e[33m' R=$'\e[31m' N=$'\e[0m'; else B='' G='' Y='' R='' N=''; fi
step() { echo; echo "${B}==> $*${N}"; }
ok()   { echo "  ${G}✓${N} $*"; }
warn() { echo "  ${Y}!${N} $*"; }
die()  { echo "${R}error:${N} $*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
run()  { if [ "$DRY" = 1 ]; then echo "  + $*"; else "$@"; fi; }
try()  { if [ "$DRY" = 1 ]; then echo "  + $*"; return 0; fi; "$@" || { warn "failed (skipped): $*"; return 0; }; }

SUDO=""
if [ "$(id -u)" != 0 ]; then SUDO="sudo"; fi
as_root() { if [ -n "$SUDO" ]; then try sudo "$@"; else try "$@"; fi; }

ME="$(id -un)"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # this fedora-rice/ folder
# The Emacs config: the sibling emacs/ folder of this repo, or a fresh clone
# if fedora-rice/ was copied somewhere on its own.  Override with EMACS_DIR=...
EMACS_REPO_URL="https://github.com/EnsuretechInsuranceBrokers/emacs.git"
EMACS_CLONE="${EMACS_CONFIG_DIR:-$HOME/src/emacs-config}"
if [ -z "${EMACS_DIR:-}" ]; then
  if [ -f "$HERE/../emacs/init.el" ]; then EMACS_DIR="$(cd "$HERE/../emacs" && pwd)"
  else EMACS_DIR="$EMACS_CLONE/emacs"; fi
fi
STAMP="$(date +%Y%m%d-%H%M%S)"

# install_file SRC DEST: copy, backing up a different existing DEST.
install_file() {
  local src="$1" dest="$2"
  if [ -f "$dest" ] && cmp -s "$src" "$dest"; then ok "$dest (unchanged)"; return; fi
  run mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ]; then run cp -a "$dest" "$dest.bak-$STAMP"; warn "backed up $dest -> $dest.bak-$STAMP"; fi
  run cp "$src" "$dest"
  ok "$dest"
}

# ---------------------------------------------------------------- checks
if [ "$FORCE" = 0 ] && ! grep -qi '^ID=fedora' /etc/os-release 2>/dev/null; then
  die "this is for Fedora (use --force to try anyway, or emacs/setup.sh for just Emacs)"
fi
FEDORA_VERSION="$(rpm -E %fedora 2>/dev/null || echo '?')"

if [ "$REMOVE_TIMERS" = 1 ]; then
  step "Removing the monthly Emacs update timers"
  try systemctl --user disable --now emacs-update.timer
  run rm -f "$HOME/.config/systemd/user/emacs-update.timer" "$HOME/.config/systemd/user/emacs-update.service"
  try systemctl --user daemon-reload
  as_root systemctl disable --now emacs-update-system.timer
  as_root rm -f /etc/systemd/system/emacs-update-system.timer /etc/systemd/system/emacs-update-system.service
  as_root systemctl daemon-reload
  ok "removed"
  exit 0
fi

NEEDS_ROOT=$(( DO_DNF + DO_SHELL + DO_TIMER ))
if [ -n "$SUDO" ] && [ "$YES" = 0 ] && [ "$DRY" = 0 ] && [ "$NEEDS_ROOT" -gt 0 ]; then
  echo "This changes system settings and installs packages with sudo. Continue? [Y/n] "
  read -r reply </dev/tty || reply=y
  case "$reply" in [nN]*) exit 1 ;; esac
  sudo -v   # ask for the password once, up front
fi

echo "${B}Fedora $FEDORA_VERSION rice${N}  (rice: $HERE, emacs config: $EMACS_DIR)"

# ---------------------------------------------------------------- 1. dnf
if [ "$DO_DNF" = 1 ]; then
  step "dnf: parallel downloads, then packages"
  conf=/etc/dnf/dnf.conf
  for kv in "max_parallel_downloads=10" "defaultyes=True"; do
    key="${kv%%=*}"
    if grep -q "^$key" "$conf" 2>/dev/null; then ok "$conf: $key already set"
    else
      if [ "$DRY" = 1 ]; then echo "  + echo $kv | sudo tee -a $conf"
      else echo "$kv" | ${SUDO:+sudo} tee -a "$conf" >/dev/null; fi
      ok "$conf: $kv"
    fi
  done

  if [ "$RPMFUSION" = 1 ]; then
    as_root dnf install -y \
      "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$FEDORA_VERSION.noarch.rpm" \
      "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$FEDORA_VERSION.noarch.rpm"
  fi

  PKGS=(
    # shell + terminal
    zsh zsh-autosuggestions zsh-syntax-highlighting alacritty tmux
    # CLI tools (rg/fd are also what Emacs uses for search)
    ripgrep fd-find fzf bat eza zoxide btop git-delta jq tldr fastfetch
    wl-clipboard xclip unzip curl
    # GNOME tweaking + consistent dark GTK3 apps
    gnome-tweaks gnome-extensions-app adw-gtk3-theme
    # notifications for the update timer
    libnotify
  )
  # One by one, so a package missing from this Fedora release doesn't stop the rest.
  for p in "${PKGS[@]}"; do
    if rpm -q "$p" >/dev/null 2>&1; then continue; fi
    as_root dnf install -y -q "$p"
  done
  ok "packages"

  if [ "$FLATHUB" = 1 ] && have flatpak; then
    as_root flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    as_root flatpak remote-modify --enable --no-filter flathub
    ok "Flathub (unfiltered)"
  fi
fi

# ---------------------------------------------------------------- 2. GNOME
# gset SCHEMA KEY VALUE: set only if the key exists in this GNOME version.
gset() {
  if gsettings writable "$1" "$2" >/dev/null 2>&1; then try gsettings set "$1" "$2" "$3"
  else warn "no $1 $2 in this GNOME (skipped)"; fi
}

if [ "$DO_GNOME" = 1 ]; then
  step "GNOME: dark, quiet, keyboard-first"
  if ! have gsettings || ! gsettings list-schemas 2>/dev/null | grep -q '^org.gnome.desktop.interface$'; then
    warn "GNOME not found (KDE/Sway/other spin?): skipping desktop settings"
  else
    I=org.gnome.desktop.interface
    gset $I color-scheme "'prefer-dark'"
    if [ -d /usr/share/themes/adw-gtk3-dark ]; then gset $I gtk-theme "'adw-gtk3-dark'"; fi
    gset $I accent-color "'yellow'"             # GNOME 47+: matches gruber-darker
    gset $I enable-animations false              # everything feels instant
    gset $I enable-hot-corners false
    gset $I clock-show-weekday true
    gset $I show-battery-percentage true
    if fc-list 2>/dev/null | grep -qi iosevka || [ "$DO_EMACS" = 1 ]; then
      gset $I monospace-font-name "'Iosevka 13'"
    fi

    # Solid gruber-darker wallpaper
    BG=org.gnome.desktop.background
    gset $BG picture-uri "''"
    gset $BG picture-uri-dark "''"
    gset $BG picture-options "'none'"
    gset $BG color-shading-type "'solid'"
    gset $BG primary-color "'#181818'"

    # Keyboard: Caps Lock -> Ctrl (kept with any options you already have), fast repeat
    cur="$(gsettings get org.gnome.desktop.input-sources xkb-options 2>/dev/null || echo '@as []')"
    if ! grep -q "ctrl:nocaps" <<<"$cur"; then
      new="$(python3 -c 'import ast,sys; s=sys.argv[1].replace("@as ",""); l=ast.literal_eval(s); l.append("ctrl:nocaps"); print(str(l))' "$cur")"
      gset org.gnome.desktop.input-sources xkb-options "$new"
    fi
    K=org.gnome.desktop.peripherals.keyboard
    gset $K delay "uint32 200"
    gset $K repeat-interval "uint32 25"
    gset org.gnome.desktop.peripherals.touchpad tap-to-click true

    # 4 fixed workspaces: Super+1..4 to switch, Super+Shift+1..4 to move a window
    gset org.gnome.mutter dynamic-workspaces false
    gset org.gnome.desktop.wm.preferences num-workspaces 4
    for i in 1 2 3 4; do
      gset org.gnome.shell.keybindings "switch-to-application-$i" "@as []"   # frees Super+N
      gset org.gnome.desktop.wm.keybindings "switch-to-workspace-$i" "['<Super>$i']"
      gset org.gnome.desktop.wm.keybindings "move-to-workspace-$i" "['<Super><Shift>$i']"
    done
    gset org.gnome.desktop.wm.keybindings close "['<Super>q', '<Alt>F4']"
    gset org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Super>f']"

    # Night light in the evening
    gset org.gnome.settings-daemon.plugins.color night-light-enabled true
    gset org.gnome.settings-daemon.plugins.color night-light-temperature "uint32 4000"

    # Super+Return terminal, Super+E Emacs (added to your existing custom shortcuts)
    MK=org.gnome.settings-daemon.plugins.media-keys
    BASE=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings
    add_shortcut() {   # add_shortcut ID NAME COMMAND BINDING
      local path="$BASE/$1/"
      local list
      list="$(gsettings get $MK custom-keybindings 2>/dev/null || echo '@as []')"
      if ! grep -q "$path" <<<"$list"; then
        list="$(python3 -c 'import ast,sys; s=sys.argv[1].replace("@as ",""); l=ast.literal_eval(s); l.append(sys.argv[2]); print(str(l))' "$list" "$path")"
        try gsettings set $MK custom-keybindings "$list"
      fi
      local schema="$MK.custom-keybinding:$path"
      try gsettings set "$schema" name "'$2'"
      try gsettings set "$schema" command "'$3'"
      try gsettings set "$schema" binding "'$4'"
      ok "shortcut $4 -> $2"
    }
    TERM_CMD=alacritty; have alacritty || TERM_CMD=ptyxis; have "$TERM_CMD" || TERM_CMD=gnome-terminal
    add_shortcut rice-terminal "Terminal" "$TERM_CMD" "<Super>Return"
    add_shortcut rice-emacs "Emacs" "emacsclient -c -n -a \"\"" "<Super>e"
    ok "GNOME settings (some apply after logging out and in)"
  fi
fi

# ---------------------------------------------------------------- 3. dotfiles
if [ "$DO_DOTFILES" = 1 ]; then
  step "Dotfiles (gruber-darker everywhere)"
  install_file "$HERE/dotfiles/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
  install_file "$HERE/dotfiles/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
  install_file "$HERE/dotfiles/bat/config" "$HOME/.config/bat/config"
  install_file "$HERE/dotfiles/zsh/rice.zsh" "$HOME/.config/zsh/rice.zsh"
  # Hook it into ~/.zshrc once, keeping whatever else is there.
  line='[ -r ~/.config/zsh/rice.zsh ] && source ~/.config/zsh/rice.zsh   # fedora-rice/rice.sh'
  if ! grep -qF "config/zsh/rice.zsh" "$HOME/.zshrc" 2>/dev/null; then
    if [ "$DRY" = 1 ]; then echo "  + echo '$line' >> ~/.zshrc"; else echo "$line" >> "$HOME/.zshrc"; fi
    ok "$HOME/.zshrc sources rice.zsh"
  fi
fi

# ---------------------------------------------------------------- 4. shell
if [ "$DO_SHELL" = 1 ]; then
  step "zsh as login shell"
  zsh_bin="$(command -v zsh || echo /usr/bin/zsh)"
  current="$(getent passwd "$ME" | cut -d: -f7)"
  if [ "$current" = "$zsh_bin" ]; then ok "already zsh"
  elif [ "$DRY" = 1 ] || [ -x "$zsh_bin" ]; then as_root usermod -s "$zsh_bin" "$ME"; ok "login shell -> zsh (next login)"
  else warn "zsh isn't installed (was --no-dnf used?)"; fi
fi

# ---------------------------------------------------------------- 5. git
if [ "$DO_GIT" = 1 ] && have git; then
  step "git defaults (only ones you haven't set)"
  gdef() { if [ -z "$(git config --global --get "$1" 2>/dev/null)" ]; then run git config --global "$1" "$2"; ok "$1 = $2"; fi; }
  if have delta; then
    gdef core.pager delta
    gdef interactive.diffFilter "delta --color-only"
    gdef delta.navigate true
    gdef delta.line-numbers true
  fi
  gdef init.defaultBranch main
  gdef merge.conflictStyle zdiff3
  gdef pull.ff only
  gdef push.autoSetupRemote true
  gdef rerere.enabled true
  gdef diff.algorithm histogram
  gdef diff.colorMoved default
  gdef branch.sort -committerdate
  gdef column.ui auto
  gdef fetch.prune true
fi

# ---------------------------------------------------------------- 6. Emacs
if [ "$DO_EMACS" = 1 ]; then
  step "Emacs ($EMACS_DIR/setup.sh --daemon)"
  if [ ! -f "$EMACS_DIR/setup.sh" ]; then
    run git clone "$EMACS_REPO_URL" "$EMACS_CLONE"
  fi
  setup_args=(--daemon -y)
  [ "$DRY" = 1 ] && setup_args+=(--dry-run)
  if [ "$DRY" = 1 ] && [ ! -f "$EMACS_DIR/setup.sh" ]; then echo "  + $EMACS_DIR/setup.sh ${setup_args[*]}"
  else "$EMACS_DIR/setup.sh" "${setup_args[@]}" ${EMACS_ARGS[@]+"${EMACS_ARGS[@]}"}; fi
fi

# ---------------------------------------------------------------- 7. timers
if [ "$DO_TIMER" = 1 ]; then
  step "Monthly Emacs update: fourth Sunday, 03:30 (dnf) and 04:00 (config + packages)"
  # System: upgrade the Emacs RPMs.
  for u in emacs-update-system.service emacs-update-system.timer; do
    if [ "$DRY" = 1 ]; then echo "  + sudo install -m 644 $HERE/systemd/$u /etc/systemd/system/$u"
    else ${SUDO:+sudo} install -m 644 "$HERE/systemd/$u" "/etc/systemd/system/$u"; fi
  done
  as_root systemctl daemon-reload
  as_root systemctl enable --now emacs-update-system.timer

  # User: pull the config + snapshot + upgrade packages (emacs/setup.sh --update).
  udir="$HOME/.config/systemd/user"
  run mkdir -p "$udir"
  for u in emacs-update.service emacs-update.timer; do
    if [ "$DRY" = 1 ]; then echo "  + sed @EMACS_DIR@=$EMACS_DIR @RICE_DIR@=$HERE $HERE/systemd/$u > $udir/$u"
    else sed -e "s|@EMACS_DIR@|$EMACS_DIR|g" -e "s|@RICE_DIR@|$HERE|g" "$HERE/systemd/$u" > "$udir/$u"; fi
  done
  try systemctl --user daemon-reload
  try systemctl --user enable --now emacs-update.timer
  if [ "$DRY" = 0 ]; then
    systemctl list-timers --all emacs-update-system.timer 2>/dev/null | sed -n '1,2p' || true
    systemctl --user list-timers --all emacs-update.timer 2>/dev/null | sed -n '2p' || true
  fi
  ok "timers on. Run now: systemctl --user start emacs-update   Logs: journalctl --user -u emacs-update"
fi

# ---------------------------------------------------------------- done
step "Done"
cat <<EOF
  Log out and back in for the shell, keyboard and some GNOME settings.
  Super+Return  terminal (alacritty, gruber-darker, Iosevka)
  Super+E       Emacs (daemon: opens instantly)
  Super+1..4    workspaces, Super+Shift+1..4 move window, Super+Q close
  Undo:         settings -> GNOME Settings / gnome-tweaks; files -> *.bak-$STAMP
                timers   -> ./fedora-rice/rice.sh --remove-timers
EOF

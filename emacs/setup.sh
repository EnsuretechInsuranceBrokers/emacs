#!/usr/bin/env bash
# One-command Emacs setup.
#
#   ./setup.sh                 everything (Emacs, tools, font, language servers, config, packages)
#   ./setup.sh --emacs-keys    same, with plain Emacs keys instead of Vim keys
#   ./setup.sh --minimal       Emacs + core tools + config only
#   ./setup.sh --dry-run       print what would run, change nothing
#   ./setup.sh --platform fedora   switch lisp/init-platform.el to Fedora (or: macos)
#   ./setup.sh --update        later: pull this repo + upgrade packages (with snapshot)
#   ./setup.sh --doctor        health report: what's installed, what's missing
#   ./setup.sh --help          all options
#
# Works on macOS (Homebrew), Ubuntu/Debian (apt), Fedora (dnf), Arch (pacman),
# openSUSE (zypper).  Safe to re-run: it skips what is already done.

set -euo pipefail

REPO_URL="https://github.com/EnsuretechInsuranceBrokers/emacs.git"
CLONE_DIR="${EMACS_CONFIG_DIR:-$HOME/src/emacs-config}"   # the repo; the config is its emacs/ folder
TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/emacs"
MIN_EMACS=29

# ---------------------------------------------------------------- options
DO_EMACS=1 DO_TOOLS=1 DO_FONT=1 DO_LSP=1 DO_PACKAGES=1
EMACS_KEYS=0 DAEMON=0 KEYBOARD=0 DRY=0 YES=0 MODE=install PLATFORM=""

usage() {
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
  cat <<'EOF'
Options:
  --emacs-keys    plain Emacs keys instead of Vim keys (evil is the default)
  --minimal       skip font and language servers
  --no-emacs      don't install Emacs (use the one you have)
  --no-tools      don't install ripgrep, fd, compilers, cmake...
  --no-font       don't install Iosevka
  --no-lsp        don't install language servers
  --no-packages   don't pre-download Emacs packages (Emacs does it on first start)
  --daemon        start Emacs as a background service at login (instant emacsclient)
  --keyboard      Caps Lock -> Ctrl and a fast key repeat rate (GNOME/macOS)
  --update        pull the config repo, snapshot + upgrade packages, update grammars
  --doctor        print a health report and exit
  --platform P    switch lisp/init-platform.el to P (macos or fedora) and exit.
                  A normal run does this by itself: macos on a Mac, fedora on Linux
  -y, --yes       don't ask before using sudo
  --dry-run       print the commands instead of running them
EOF
}

while [ $# -gt 0 ]; do
  arg="$1"; shift
  case "$arg" in
    --platform=*) MODE=platform PLATFORM="${arg#*=}" ;;
    --platform) MODE=platform PLATFORM="${1:-}"; [ $# -gt 0 ] && shift ;;
    --evil) : ;;               # default now; kept so old commands still work
    --emacs-keys) EMACS_KEYS=1 ;;
    --minimal) DO_FONT=0 DO_LSP=0 ;;
    --no-emacs) DO_EMACS=0 ;;
    --no-tools) DO_TOOLS=0 ;;
    --no-font) DO_FONT=0 ;;
    --no-lsp) DO_LSP=0 ;;
    --no-packages) DO_PACKAGES=0 ;;
    --daemon) DAEMON=1 ;;
    --keyboard) KEYBOARD=1 ;;
    --update) MODE=update ;;
    --doctor) MODE=doctor ;;
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

run() {
  if [ "$DRY" = 1 ]; then echo "  + $*"; else "$@"; fi
}
# Like run, but failure only warns: optional extras must never stop the setup.
try() {
  if [ "$DRY" = 1 ]; then echo "  + $*"; return 0; fi
  "$@" || { warn "failed (skipped): $*"; return 0; }
}

SUDO=""
if [ "$(id -u)" != 0 ] && have sudo; then SUDO="sudo"; fi
as_root() { if [ -n "$SUDO" ]; then run $SUDO "$@"; else run "$@"; fi; }

# ---------------------------------------------------------------- macOS / Fedora block
# lisp/init-platform.el has a MACOS block (active in git) and a FEDORA block
# (commented out).  set_platform comments one and uncomments the other.
set_platform() {   # set_platform CONFIG-DIR macos|fedora
  local f="$1/lisp/init-platform.el" on off
  [ -f "$f" ] || { warn "no $f"; return 0; }
  case "$2" in
    macos)  on=MACOS;  off=FEDORA ;;
    fedora) on=FEDORA; off=MACOS ;;
    *) die "unknown platform '$2' (use macos or fedora)" ;;
  esac
  if [ "$DRY" = 1 ]; then echo "  + switch $f to $2"; return 0; fi
  awk -v on="$on" -v off="$off" '
    index($0, ";;;; >>> " on " BEGIN") == 1  { mode = "on";  print; next }
    index($0, ";;;; >>> " off " BEGIN") == 1 { mode = "off"; print; next }
    index($0, ";;;; <<< " on " END") == 1 || index($0, ";;;; <<< " off " END") == 1 { mode = ""; print; next }
    mode == "on"  { sub(/^;; /, ""); print; next }
    mode == "off" { if ($0 != "" && $0 !~ /^;; /) $0 = ";; " $0; print; next }
                  { print }
  ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  rm -f "$1/lisp/init-platform.elc"   # recompiled on the next run / save
}
current_platform() {   # current_platform CONFIG-DIR -> macos | fedora
  if grep -q "^(setq my/platform 'fedora)" "$1/lisp/init-platform.el" 2>/dev/null; then echo fedora
  else echo macos; fi
}
this_platform() { if [ "$(uname -s)" = Darwin ]; then echo macos; else echo fedora; fi; }

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"
if [ "$MODE" = platform ]; then
  conf="$TARGET"; [ -f "$SELF_DIR/init.el" ] && conf="$SELF_DIR"
  set_platform "$conf" "$PLATFORM"
  ok "init-platform.el: $PLATFORM block active (restart Emacs)"
  exit 0
fi

# ---------------------------------------------------------------- update / doctor
batch_emacs() {   # batch_emacs ELISP: load the config headless and evaluate ELISP
  emacs --batch --init-directory "$TARGET" \
    -l "$TARGET/early-init.el" -l "$TARGET/init.el" --eval "$1"
}
if [ "$MODE" != install ]; then
  have emacs || die "emacs not found; run ./setup.sh first"
  [ -e "$TARGET/init.el" ] || die "$TARGET is not set up; run ./setup.sh first"
  if [ "$MODE" = doctor ]; then
    batch_emacs '(my/doctor)' 2>/dev/null
    exit 0
  fi
  step "Updating the config repo"
  repo="$(cd "$TARGET" && pwd -P)"
  if git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    # The Fedora block being active is the one local change we expect: put the
    # file back to the committed (macOS) state, pull, then switch back.
    plat="$(current_platform "$repo")"
    [ "$plat" = macos ] || set_platform "$repo" macos
    if git -C "$repo" diff --quiet && git -C "$repo" diff --cached --quiet; then
      run git -C "$repo" pull --ff-only || warn "git pull failed; continuing with the local version"
    else
      warn "you have local changes in $repo; not pulling (commit or stash them first)"
    fi
    [ "$plat" = macos ] || set_platform "$repo" "$plat"
  fi
  step "Upgrading packages (a snapshot is saved first; M-x my/rollback undoes it)"
  if [ "$DRY" = 1 ]; then echo "  + emacs --batch ... (my/upgrade)"
  else batch_emacs '(my/upgrade)' 2>&1 | grep -E "snapshot|Upgrad|Failed|Error|done" || true; fi
  ok "done. Restart Emacs. Check with: ./setup.sh --doctor"
  exit 0
fi

# ---------------------------------------------------------------- platform
OS="$(uname -s)"
PM=""
if [ "$OS" = Darwin ]; then
  PM=brew
elif have apt-get; then PM=apt
elif have dnf; then PM=dnf
elif have pacman; then PM=pacman
elif have zypper; then PM=zypper
fi
[ -n "$PM" ] || die "no supported package manager found (brew/apt/dnf/pacman/zypper)."

if [ "$PM" = brew ] && ! have brew; then
  step "Installing Homebrew"
  run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
fi

if [ -n "$SUDO" ] && [ "$YES" = 0 ] && [ "$PM" != brew ] && [ "$DRY" = 0 ]; then
  echo "This installs system packages with sudo ($PM). Continue? [Y/n] "
  read -r reply </dev/tty || reply=y
  case "$reply" in [nN]*) exit 1 ;; esac
fi

APT_UPDATED=0
pkg_install() {   # pkg_install name... (names already mapped for $PM)
  [ $# -gt 0 ] || return 0
  case "$PM" in
    brew)   try brew install "$@" ;;
    apt)    if [ "$APT_UPDATED" = 0 ]; then as_root apt-get update -qq; APT_UPDATED=1; fi
            as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$@" || warn "some of: $* failed" ;;
    dnf)    as_root dnf install -y -q "$@" || warn "some of: $* failed" ;;
    pacman) as_root pacman -S --needed --noconfirm "$@" || warn "some of: $* failed" ;;
    zypper) as_root zypper --non-interactive install "$@" || warn "some of: $* failed" ;;
  esac
}

emacs_major() { emacs --batch --eval '(princ emacs-major-version)' 2>/dev/null || echo 0; }

# ---------------------------------------------------------------- 1. Emacs
if [ "$DO_EMACS" = 1 ]; then
  step "Emacs $MIN_EMACS+"
  if have emacs && [ "$(emacs_major)" -ge "$MIN_EMACS" ]; then
    ok "Emacs $(emacs_major) already installed"
  else
    case "$PM" in
      brew)   # emacs-plus: the usual macOS build (native-comp, better macOS integration)
              if [ "$DRY" = 1 ] || brew tap d12frosted/emacs-plus >/dev/null 2>&1; then
                try brew install emacs-plus@30
              fi
              have emacs || try brew install --cask emacs ;;
      apt)
        pkg_install emacs
        if [ "$DRY" = 0 ] && [ "$(emacs_major)" -lt "$MIN_EMACS" ]; then
          if grep -qi ubuntu /etc/os-release 2>/dev/null; then
            warn "distro Emacs is too old; adding the ubuntuhandbook1/emacs PPA"
            pkg_install software-properties-common
            as_root add-apt-repository -y ppa:ubuntuhandbook1/emacs
            as_root apt-get update -qq
            pkg_install emacs emacs-common
          elif have snap; then
            warn "distro Emacs is too old; installing the snap"
            as_root snap install emacs --classic
          fi
        fi ;;
      dnf)    pkg_install emacs ;;
      pacman) pkg_install emacs ;;
      zypper) pkg_install emacs ;;
    esac
    if [ "$DRY" = 0 ]; then
      [ "$(emacs_major)" -ge "$MIN_EMACS" ] || die "could not get Emacs $MIN_EMACS+; install it manually and rerun with --no-emacs."
      ok "Emacs $(emacs_major)"
    fi
  fi
fi

# ---------------------------------------------------------------- 2. Tools
if [ "$DO_TOOLS" = 1 ]; then
  step "Core tools (git, ripgrep, fd, compilers, cmake for vterm)"
  case "$PM" in
    brew)   pkg_install git ripgrep fd cmake libtool coreutils direnv pandoc ;;
    apt)    pkg_install git ripgrep fd-find build-essential cmake libtool-bin libvterm-dev direnv curl unzip ;;
    dnf)    pkg_install git ripgrep fd-find gcc gcc-c++ make cmake libtool libvterm-devel direnv curl unzip plocate ;;
    pacman) pkg_install git ripgrep fd base-devel cmake libtool libvterm direnv curl unzip ;;
    zypper) pkg_install git ripgrep fd gcc gcc-c++ make cmake libtool libvterm-devel direnv curl unzip ;;
  esac
  # Debian/Ubuntu call fd "fdfind"; the config looks for "fd".
  if ! have fd && have fdfind; then
    run mkdir -p "$HOME/.local/bin"
    run ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    ok "linked fdfind -> ~/.local/bin/fd (make sure ~/.local/bin is on PATH)"
  fi
fi

# ---------------------------------------------------------------- 3. Font
if [ "$DO_FONT" = 1 ]; then
  step "Iosevka font"
  font_installed() {
    if have fc-list; then fc-list 2>/dev/null | grep -qi iosevka
    else
      for f in "$HOME"/Library/Fonts/*[Ii]osevka* /Library/Fonts/*[Ii]osevka*; do
        [ -e "$f" ] && return 0
      done
      return 1
    fi
  }
  if font_installed; then
    ok "already installed"
  else
    case "$PM" in
      brew)   try brew install --cask font-iosevka ;;
      pacman) pkg_install ttc-iosevka ;;
      *)
        # From the Iosevka GitHub releases into ~/.local/share/fonts.  Only the
        # 4 styles Emacs uses (unhinted: ~34 MB instead of ~640 MB for the full set).
        tag="$(curl -fsSL https://api.github.com/repos/be5invis/Iosevka/releases/latest 2>/dev/null \
               | sed -n 's/.*"tag_name": *"v\{0,1\}\([^"]*\)".*/\1/p' | head -1 || true)"
        if [ -z "$tag" ] && have git; then   # API blocked or rate-limited: ask git instead
          tag="$(git ls-remote --tags --refs https://github.com/be5invis/Iosevka.git 2>/dev/null \
                 | sed -n 's|.*refs/tags/v\([0-9][0-9.]*\)$|\1|p' | sort -V | tail -1 || true)"
        fi
        if [ -z "$tag" ]; then
          warn "couldn't reach GitHub; get Iosevka from https://github.com/be5invis/Iosevka/releases"
        else
          dir="$HOME/.local/share/fonts/iosevka"
          tmp="$(mktemp -d)"
          try curl -fsSL -o "$tmp/iosevka.zip" \
            "https://github.com/be5invis/Iosevka/releases/download/v$tag/PkgTTF-Unhinted-Iosevka-$tag.zip"
          if [ "$DRY" = 1 ] || [ -s "$tmp/iosevka.zip" ]; then
            run mkdir -p "$dir"
            try unzip -joq "$tmp/iosevka.zip" -d "$dir" \
              'Iosevka-Regular.ttf' 'Iosevka-Bold.ttf' 'Iosevka-Italic.ttf' 'Iosevka-BoldItalic.ttf'
            have fc-cache && try fc-cache -f "$dir"
            ok "Iosevka $tag (4 styles)"
          fi
          rm -rf "$tmp"
        fi ;;
    esac
  fi
fi

# ---------------------------------------------------------------- 4. Language servers
if [ "$DO_LSP" = 1 ]; then
  step "Language servers (only for languages whose toolchain you have)"
  case "$PM" in
    apt)    have clangd || pkg_install clangd ;;
    dnf)    have clangd || pkg_install clang-tools-extra ;;
    zypper) have clangd || pkg_install clang-tools ;;
    pacman) have clangd || pkg_install clang ;;
    brew)   have clangd || warn "clangd: comes with Xcode Command Line Tools (xcode-select --install)" ;;
  esac
  have clang-format || case "$PM" in
    apt) pkg_install clang-format ;; brew) pkg_install clang-format ;;
    dnf|zypper|pacman) : ;;   # shipped with clang/clang-tools-extra above
  esac

  if have go; then
    have gopls   || try go install golang.org/x/tools/gopls@latest
    have gofumpt || try go install mvdan.cc/gofumpt@latest
    ok "Go: gopls, gofumpt (in $(go env GOPATH 2>/dev/null || echo "$HOME/go")/bin)"
  else
    warn "Go not installed: skipping gopls"
  fi

  if have npm; then
    npm_global() {
      if [ -w "$(npm prefix -g 2>/dev/null)/lib" ] 2>/dev/null; then try npm install -g "$@"
      else try $SUDO npm install -g "$@"; fi
    }
    have intelephense || npm_global intelephense
    have typescript-language-server || npm_global typescript-language-server typescript
    have prettier || npm_global prettier
    ok "PHP: intelephense, JS/TS: typescript-language-server, prettier"
  else
    warn "npm not installed: skipping intelephense / typescript-language-server"
  fi

  if have pipx; then
    have basedpyright || try pipx install basedpyright
    have ruff || try pipx install ruff
    ok "Python: basedpyright, ruff"
  elif have python3; then
    warn "install pipx to get the Python server: pipx install basedpyright ruff"
  fi
fi

# ---------------------------------------------------------------- 5. Config
step "Config -> $TARGET"
SCRIPT_DIR="$SELF_DIR"
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/init.el" ] && [ -d "$SCRIPT_DIR/lisp" ]; then
  REPO="$SCRIPT_DIR"
else
  # Run without a checkout (e.g. curl | bash): clone it.
  if [ -d "$CLONE_DIR/.git" ]; then run git -C "$CLONE_DIR" pull --ff-only
  else run mkdir -p "$(dirname "$CLONE_DIR")"; run git clone "$REPO_URL" "$CLONE_DIR"; fi
  REPO="$CLONE_DIR/emacs"
fi
ok "repo: $REPO"

# Make lisp/init-platform.el match this machine (macOS block in git; Fedora on Linux).
want="$(this_platform)"
if [ "$(current_platform "$REPO")" != "$want" ]; then
  set_platform "$REPO" "$want"
  ok "init-platform.el: switched to the $want block (see the top of that file)"
else
  ok "init-platform.el: $want block already active"
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
backup() {
  local p="$1"
  if [ -L "$p" ] && [ "$(readlink "$p")" = "$REPO" ]; then return; fi
  if [ -e "$p" ] || [ -L "$p" ]; then
    run mv "$p" "$p.bak-$STAMP"
    warn "moved old $p -> $p.bak-$STAMP"
  fi
}
# ~/.emacs and ~/.emacs.d take priority over ~/.config/emacs, so move them aside.
backup "$HOME/.emacs"
backup "$HOME/.emacs.el"
backup "$HOME/.emacs.d"
if [ -L "$TARGET" ] && [ "$(readlink "$TARGET")" = "$REPO" ]; then
  ok "already linked"
else
  backup "$TARGET"
  run mkdir -p "$(dirname "$TARGET")"
  run ln -s "$REPO" "$TARGET"
  ok "linked"
fi

if [ ! -f "$REPO/personal.el" ]; then
  run cp "$REPO/personal.example.el" "$REPO/personal.el"
fi
if [ "$EMACS_KEYS" = 1 ] && ! grep -q '^(setq my/use-evil nil)' "$REPO/personal.el" 2>/dev/null; then
  if [ "$DRY" = 1 ]; then echo "  + echo '(setq my/use-evil nil)' >> $REPO/personal.el"
  else echo '(setq my/use-evil nil)' >> "$REPO/personal.el"; fi
  ok "plain Emacs keys set in personal.el (C-c v switches to Vim keys)"
fi

# ---------------------------------------------------------------- 6. Packages
if [ "$DO_PACKAGES" = 1 ]; then
  step "Downloading and compiling Emacs packages (first time: 1-3 min)"
  if [ "$DRY" = 1 ]; then
    echo "  + emacs --batch --init-directory $TARGET -l early-init.el -l init.el --eval (grammars, vterm)"
  elif have emacs; then
    log="$REPO/var/setup.log"
    mkdir -p "$REPO/var"
    if emacs --batch --init-directory "$TARGET" \
         -l "$TARGET/early-init.el" -l "$TARGET/init.el" \
         --eval '(progn
                   (when (fboundp (quote package-quickstart-refresh)) (package-quickstart-refresh))
                   ;; Tree-sitter grammars for every language treesit-auto knows (needs a C compiler).
                   (when (and (fboundp (quote treesit-auto-install-all)) (executable-find "cc"))
                     (let ((treesit-auto-install t))
                       (ignore-errors (treesit-auto-install-all))))
                   ;; Build the vterm module now, not on first M-x vterm.
                   (setq vterm-always-compile-module t)
                   (ignore-errors (require (quote vterm)))
                   ;; Byte-compile the config itself: faster startup.
                   (my/compile-config))' >"$log" 2>&1; then
      failed="$(grep -c 'Failed to install' "$log" 2>/dev/null || true)"
      if [ "${failed:-0}" = 0 ]; then ok "packages ready (log: $log)"
      else warn "$failed package(s) failed to install (network?). Emacs retries on next start. Log: $log"; fi
    else
      warn "package step had errors; see $log. Emacs will retry on first start."
    fi
    # Icon font for dired (nerd-icons): ~2 MB, only if it isn't there yet.
    icons_installed() {
      if have fc-list; then fc-list 2>/dev/null | grep -qi "Symbols Nerd Font"; return; fi
      for f in "$HOME"/Library/Fonts/*SymbolsNerdFont* /Library/Fonts/*SymbolsNerdFont*; do
        [ -e "$f" ] && return 0
      done
      return 1
    }
    if [ "$DO_FONT" = 1 ] && ! icons_installed; then
      if emacs --batch --init-directory "$TARGET" -l "$TARGET/early-init.el" -l "$TARGET/init.el" \
           --eval '(when (require (quote nerd-icons) nil t) (nerd-icons-install-fonts t))' >>"$log" 2>&1; then
        have fc-cache && fc-cache -f >/dev/null 2>&1
        ok "dired icon font (Symbols Nerd Font)"
      else
        warn "couldn't install the dired icon font; in Emacs: M-x nerd-icons-install-fonts"
      fi
    fi
  fi
fi

# ---------------------------------------------------------------- 7. Daemon
if [ "$DAEMON" = 1 ]; then
  step "Emacs daemon at login"
  if [ "$PM" = brew ]; then
    plist="$HOME/Library/LaunchAgents/gnu.emacs.daemon.plist"
    emacs_bin="$(command -v emacs)"
    if [ "$DRY" = 1 ]; then echo "  + write $plist"
    else
      mkdir -p "$(dirname "$plist")"
      cat >"$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>gnu.emacs.daemon</string>
  <key>ProgramArguments</key><array><string>$emacs_bin</string><string>--fg-daemon</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
</dict></plist>
EOF
      try launchctl load -w "$plist"
    fi
  elif have systemctl; then
    try systemctl --user enable --now emacs
  else
    warn "no systemd/launchd: add 'emacs --daemon' to your login script"
  fi
  ok "use: emacsclient -c -a ''   (alias e='emacsclient -c -a \"\"')"
fi

# ---------------------------------------------------------------- 8. Keyboard
if [ "$KEYBOARD" = 1 ]; then
  step "Keyboard: Caps Lock -> Ctrl, fast key repeat"
  if [ "$OS" = Darwin ]; then
    try defaults write -g InitialKeyRepeat -int 15   # 225 ms
    try defaults write -g KeyRepeat -int 2           # 30 ms
    try defaults write -g ApplePressAndHoldEnabled -bool false
    warn "Caps Lock -> Control: System Settings > Keyboard > Keyboard Shortcuts > Modifier Keys"
    warn "log out and back in for the repeat rate to apply"
  elif have gsettings && gsettings list-schemas 2>/dev/null | grep -q org.gnome.desktop.peripherals.keyboard; then
    try gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:nocaps']"
    try gsettings set org.gnome.desktop.peripherals.keyboard delay 200
    try gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 25
    ok "GNOME settings applied"
  elif have setxkbmap && [ -n "${DISPLAY:-}" ]; then
    try setxkbmap -option ctrl:nocaps
    have xset && try xset r rate 200 40
    warn "applied for this X session only; put those two commands in ~/.xprofile to keep them"
  else
    warn "unknown desktop: set Caps Lock -> Ctrl and repeat delay ~200ms / rate ~40/s in your keyboard settings"
  fi
fi

# ---------------------------------------------------------------- done
step "Done"
cat <<EOF
  Start Emacs:          emacs        (or: emacsclient -c -a '')
  Your settings:        $REPO/personal.el
  Learn the keys:       $REPO/README.md, section "Getting fast"
  Update packages:      M-x package-upgrade-all
EOF
have rg || warn "ripgrep missing: M-s r / project search won't work"
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) warn "add ~/.local/bin to PATH (fd lives there on Debian/Ubuntu)";; esac
if have go; then
  case ":$PATH:" in *":$(go env GOPATH)/bin:"*) ;; *) warn "add $(go env GOPATH)/bin to PATH so Emacs finds gopls";; esac
fi

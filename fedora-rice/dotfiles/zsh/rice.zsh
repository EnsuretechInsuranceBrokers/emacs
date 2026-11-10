# Sourced from ~/.zshrc (fedora-rice/rice.sh adds the line).  Edit freely.

# ---- History
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt share_history hist_ignore_all_dups hist_ignore_space hist_reduce_blanks
setopt auto_cd interactive_comments no_beep

# ---- Line editing: Emacs keys (C-a C-e C-k M-f M-b C-r), same as in Emacs
bindkey -e
autoload -Uz select-word-style && select-word-style bash
bindkey '^[[1;5C' forward-word   # Ctrl-Right
bindkey '^[[1;5D' backward-word  # Ctrl-Left

# ---- Completion
autoload -Uz compinit && compinit -d ~/.cache/zcompdump
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ---- Prompt:  ~/src/project main  (yellow dir, green git branch)
autoload -Uz vcs_info
zstyle ':vcs_info:git:*' formats ' %F{#73c936}%b%f'
zstyle ':vcs_info:git:*' actionformats ' %F{#73c936}%b%f %F{#f43841}(%a)%f'
precmd() { vcs_info }
setopt prompt_subst
PROMPT='%F{#ffdd33}%~%f${vcs_info_msg_0_} %(?.%F{#95a99f}.%F{#f43841})%#%f '

# ---- Editor: Emacs (the daemon makes it instant)
export EDITOR="emacsclient -t -a ''"
export VISUAL="$EDITOR"
alias e="emacsclient -c -n -a ''"     # GUI frame, return to the shell
alias et="emacsclient -t -a ''"       # in this terminal
alias magit="emacsclient -c -n -a '' -e '(magit-status)'"

# ---- Tools
if command -v eza >/dev/null; then
  alias ls='eza --group-directories-first'
  alias ll='eza -l --git --group-directories-first'
  alias la='eza -la --git --group-directories-first'
else
  alias ls='ls --color=auto --group-directories-first'
  alias ll='ls -lh'
  alias la='ls -lha'
fi
command -v bat >/dev/null && alias cat='bat -pp'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"   # z <part of a dir>

# fzf: C-t files, C-r history, M-c cd.  Gruber colours.
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git 2>/dev/null || find . -type f'
export FZF_DEFAULT_OPTS='--height 40% --reverse --color=bg+:#282828,fg:#e4e4ef,fg+:#ffdd33,hl:#96a6c8,hl+:#96a6c8,pointer:#ffdd33,prompt:#ffdd33,info:#95a99f'
for f in /usr/share/fzf/shell/key-bindings.zsh /usr/share/fzf/key-bindings.zsh; do
  [ -r "$f" ] && source "$f" && break
done

# Plugins from Fedora's repos (dnf install zsh-autosuggestions zsh-syntax-highlighting)
[ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] &&
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#52494e'
[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] &&
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

[ -d "$HOME/.local/bin" ] && path=("$HOME/.local/bin" $path)
[ -d "$HOME/go/bin" ] && path=("$HOME/go/bin" $path)

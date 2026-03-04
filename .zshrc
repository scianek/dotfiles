ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

load() {
    zinit ice silent wait"!0"
    zinit light "$1"
}

add_completion() {
    zinit ice silent as"completion"
    zinit snippet "$1"
}

add_to_path() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        PATH="${PATH:+"$PATH:"}$1"
    fi
}

HISTFILE=~/.zsh_history; HISTSIZE=10000; SAVEHIST=10000
setopt appendhistory sharehistory hist_ignore_space
setopt hist_ignore_all_dups hist_save_no_dups hist_find_no_dups

zinit ice silent
zinit light marlonrichert/zsh-autocomplete

eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/prompt.toml)"

eval "$(zoxide init zsh --cmd cd)"
load "zsh-users/zsh-syntax-highlighting"
load "zsh-users/zsh-autosuggestions"
# load "marlonrichert/zsh-autocomplete"
load "dominik-schwabe/zsh-fnm"

OMZ_plugins=(git history sudo docker-compose)
for plugin in "${OMZ_plugins[@]}"; do
    zinit snippet OMZP::$plugin
done

eval "$(dircolors)"
bindkey '^I' menu-complete
bindkey "$terminfo[kcbt]" reverse-menu-complete
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

add_completion "https://github.com/sharkdp/fd/blob/master/contrib/completion/_fd"
add_completion "https://github.com/docker/cli/blob/master/contrib/completion/zsh/_docker"
# add_completion "https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/ripgrep/_ripgrep"
add_completion "https://gist.githubusercontent.com/obeone/9313811fd61a7cbb843e0001a4434c58/raw/_ollama.zsh"

export PNPM_HOME="$HOME/.local/share/pnpm"
export EDITOR="nvim"
export MANPAGER="nvim +Man!"
export FZF_DEFAULT_COMMAND='fd --type f --follow'
export TERM=xterm-kitty
export MAMBA_ROOT_PREFIX="$HOME/miniforge3"
export CONDA_ROOT="$HOME/miniforge3"

add_to_path "$HOME/.cargo/bin"
add_to_path "$HOME/.local/bin"
add_to_path "$HOME/scripts"
add_to_path "$HOME/.ghcup/bin"
add_to_path "$PNPM_HOME"

alias ls="eza"
alias nv="nvim"
alias lg="lazygit"
alias ld="lazydocker"
alias p="pnpm"
alias pd="pnpm dlx"
alias y="yazi"
alias yd="yt-dlp -o '%(title)s.%(ext)s'"
alias imv="imv-dir"

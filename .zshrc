#zmodload zsh/zprof
ZSH_BASE="$HOME/.zsh"

DISABLE_UPDATE_PROMPT=true
DEFAULT_USER=p-himik

source $PS_SCRIPTS_DIR/ps-util-functions 2>&1 > /dev/null

# The following lines were added by compinstall

zstyle ':completion:*' completer _complete _ignored _approximate _prefix
zstyle ':completion:*' matcher-list '' 'm:{[:lower:]}={[:upper:]}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' max-errors 1
zstyle ':completion:*' prompt 'No completion found. Corrected results:'
zstyle :compinstall filename "$HOME/.zshrc"

# End of lines added by compinstall
# Lines configured by zsh-newuser-install
export HISTFILE=~/.histfile
export HISTSIZE=1000
export SAVEHIST=1000
export HIST_STAMPS="dd.mm.yyyy"
# End of lines configured by zsh-newuser-install

unsetopt autocd extendedglob sharehistory
setopt incappendhistory

source "$ZSH_BASE/zgen/zgen.zsh"

if ! zgen saved; then
    echo "Creating a zgen save"

    zgen oh-my-zsh
    zgen oh-my-zsh plugins/git
    zgen oh-my-zsh plugins/gitfast
    zgen oh-my-zsh plugins/svn
    zgen oh-my-zsh plugins/colored-man
    zgen oh-my-zsh plugins/jump
    zgen oh-my-zsh plugins/extract
    zgen oh-my-zsh plugins/sublime
    zgen oh-my-zsh plugins/mvn
    zgen oh-my-zsh plugins/virtualenv
    zgen oh-my-zsh plugins/zsh_reload
    zgen oh-my-zsh plugins/command-not-found

    zgen load khrt/svn-n-zsh-plugin
    zgen load zsh-users/zsh-syntax-highlighting
    zgen load zsh-users/zsh-history-substring-search
    zgen load rimraf/k

    zgen load $ZSH_BASE/themes/p-himik

    zgen save
fi

[ -s "$HOME/.scm_breeze/scm_breeze.sh" ] && source "$HOME/.scm_breeze/scm_breeze.sh"

source "$ZSH_BASE/vars.zsh"
source "$ZSH_BASE/aliases.zsh"
source "$ZSH_BASE/line_numbers.zsh"
source "$ZSH_BASE/git_functions.zsh"

#set -o vi
#bindkey -v

export HH_CONFIG=keywords,hicolor        # get more colors
# binding for viins
invoke-hh() { hh </dev/tty ; zle -I }
zle -N invoke-hh
bindkey -M viins "^Y" invoke-hh
# bind hh to Ctrl-r
bindkey -s "\C-r" "\eqhh\n"

# bind UP and DOWN arrow keys
zmodload zsh/terminfo
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down

# bind k and j for VI mode for history-substring-search
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

if [[ $1 == eval ]]
then
    "$@"
    set --
fi
#zprof


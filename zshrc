#!/usr/bin/zsh

#zmodload zsh/zprof
ZSH_BASE="$HOME/.zsh"

DISABLE_UPDATE_PROMPT=true
DEFAULT_USER=p-himik

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
#    zgen oh-my-zsh plugins/mvn
    zgen oh-my-zsh plugins/virtualenv
    zgen oh-my-zsh plugins/zsh_reload
    zgen oh-my-zsh plugins/command-not-found
    zgen oh-my-zsh plugins/vagrant

    zgen load khrt/svn-n-zsh-plugin
    zgen load zsh-users/zsh-syntax-highlighting
    zgen load zsh-users/zsh-history-substring-search
    zgen load rimraf/k
    zgen load arialdomartini/oh-my-git

    zgen load "$ZSH_BASE/themes/p-himik"
    zgen load "$ZSH_BASE/my_mvn.zsh"
    zgen load "$ZSH_BASE/vars.zsh"
    zgen load "$ZSH_BASE/aliases.zsh"
    zgen load "$ZSH_BASE/line_numbers.zsh"
    zgen load "$ZSH_BASE/git_functions.zsh"
    zgen load "$HOME/.scm_breeze/scm_breeze.sh"

    zgen save
fi

function omg-description() {
    for i in $(typeset + | grep "^omg_.*_symbol$"); do
        local s="${(P)i}"
        local color_var="${i}_color"
        local color="${(P)color_var}"
        local desc="$(echo $i | sed -r 's/^omg_(.*)_symbol$/\1/g' | tr '_' ' ')"
        print -P -- "${color} ${s} %k%b - ${desc}"
    done
}

source "$PS_SCRIPTS_DIR/ps-util-functions" 2>&1 > /dev/null

unsetopt extendedglob sharehistory
setopt incappendhistory autocd

compctl -K listMavenCompletions mvn2
compctl -K listMavenCompletions mvn3

#set -o vi
#bindkey -v

export HH_CONFIG=keywords,hicolor        # get more colors
# binding for viins
function invoke-hh() { hh </dev/tty ; zle -I }
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


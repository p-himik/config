#!zsh

alias ls='ls --color=auto --group-directories-first'

alias j=jump
alias rsync='rsync --progress -avh -e "ssh -ax -o ClearAllForwardings=yes"'
alias rsyncp='rsync -ah --info=progress2 -e "ssh -ax -o ClearAllForwardings=yes"'
alias less='less -i'
alias a='sudo aptitude'
alias af='apt-file find'
alias fd='env MESSAGELANG=C fd'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//  '\'')"'

alias tmux='tmux -2'

alias notify-info='notify-send -i /usr/share/icons/gnome/48x48/status/dialog-information.png'
alias notify-warn='notify-send -i /usr/share/icons/gnome/48x48/status/dialog-warning.png'
alias notify-error='notify-send -i /usr/share/icons/gnome/48x48/status/dialog-error.png'

alias m=xdg-open
alias e=extract

alias sa='conda activate'
alias sd='conda deactivate'

function _mvn_with_notify {
    local current_path="$(pwd | sed "s/$(echo $HOME | sed 's|/|\\/|g')/~/g")"
    mvn-color $@ && notify-info "Build Successful" "$current_path" || notify-error "Build Failed" "$current_path"
}

alias mvn='_mvn_with_notify mvn'

alias mvnci='mvn clean install'
alias mvni='mvn install'
alias mvnc='mvn clean'
alias mvnt='mvn test'

# overwriting `gunwip` from oh-my-zsh git plugin because its use of `git log -n 1` is incompatible with SCM Breeze
alias gunwip='git log -1 | grep -q -c "\-\-wip\-\-" && git reset HEAD~1'

# `dc` is "an arbitrary precision calculator"
alias dco='docker-compose'
alias dcb='docker-compose build'
alias dce='docker-compose exec'
alias dcps='docker-compose ps'
alias dcrestart='docker-compose restart'
alias dcrm='docker-compose rm'
alias dcr='docker-compose run'
alias dcstop='docker-compose stop'
alias dcup='docker-compose up'
alias dcdn='docker-compose down'
alias dcl='docker-compose logs'
alias dclf='docker-compose logs -f'
alias dcpull='docker-compose pull'

alias dm='docker-machine'

alias bt=bluetoothctl

alias gdo=ordered-git-diff

# The space at the front is needed to prevent this
# command itself from going into the history.
alias nohist=' export HISTFILE=/dev/null'

# The advice at https://unix.stackexchange.com/a/551163/290420
# doesn't really work for some reason - it returns the same list
# unless I run `echo $RANDOM` - then the seed is renewed.
alias -g LRF='<(find . -type f -exec realpath {} \; | shuf)'

# Not aliases but conceptually the same.
# Piping into `xargs` just to trim the output.
function ctof () { units "tempC($1)" tempF | xargs }
function ftoc () { units "tempF($1)" tempC | xargs }


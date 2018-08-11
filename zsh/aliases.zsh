#!zsh

alias j=jump
alias rsync='rsync --progress -avh -e "ssh -ax -o ClearAllForwardings=yes"'
alias less='less -i'
alias a='sudo aptitude'
alias af='apt-file find'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//  '\'')"'

alias tmux='tmux -2'

alias notify-info='notify-send -i /usr/share/icons/gnome/48x48/status/dialog-information.png'
alias notify-warn='notify-send -i /usr/share/icons/gnome/48x48/status/dialog-warning.png'
alias notify-error='notify-send -i /usr/share/icons/gnome/48x48/status/dialog-error.png'

alias m=mimeopen
alias e=extract
alias f='$(thefuck $(fc -ln -1))'

alias sa='source activate'
alias sd='source deactivate'

function _mvn_with_notify {
    local current_path="$(pwd | sed "s/$(echo $HOME | sed 's|/|\\/|g')/~/g")"
    mvn-color $@ && notify-info "Build Successful" "$current_path" || notify-error "Build Failed" "$current_path"
}

alias mvn='_mvn_with_notify mvn'
alias mvn2='_mvn_with_notify mvn2'
alias mvn3='_mvn_with_notify mvn3'

alias mvnci='mvn clean install'
alias mvni='mvn install'
alias mvnc='mvn clean'
alias mvnt='mvn test'

alias mvn2ci='mvn2 clean install'
alias mvn2i='mvn2 install'
alias mvn2c='mvn2 clean'
alias mvn2t='mvn2 test'

alias mvn3ci='mvn3 clean install'
alias mvn3i='mvn3 install'
alias mvn3c='mvn3 clean'
alias mvn3t='mvn3 test'

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

alias bt=bluetoothctl

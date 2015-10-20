#!zsh

alias vpn-c='ps-vpn check-connection'
alias j=jump
alias rsync='rsync --progress -avh'
alias less='less -i'
alias a='sudo aptitude'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//  '\'')"'

alias s=auto_ssh
function ss() {
    ssh $@ -t "cd /opt/CSCOlumos; bash"
}

alias tosvn=jump_to_svn_from_git

alias tmux='tmux -2'

alias notify-info='notify-send -i /usr/share/icons/gnome/48x48/status/dialog-information.png'
alias notify-warn='notify-send -i /usr/share/icons/gnome/48x48/status/dialog-warning.png'
alias notify-error='notify-send -i /usr/share/icons/gnome/48x48/status/dialog-error.png'

alias m=mimeopen
alias e=extract
alias f='$(thefuck $(fc -ln -1))'

alias mvn="mvn-color ps-mvn"
alias mvnci='mvn clean install'
alias mvni='mvn install'
alias mvnc='mvn clean'
alias mvnt='mvn test'

alias mvn2="mvn-color ps-mvn2"
alias mvn2ci='mvn2 clean install'
alias mvn2i='mvn2 install'
alias mvn2c='mvn2 clean'
alias mvn2t='mvn2 test'

alias mvn3='mvn-color "ps-mvn -m mvn3"'
alias mvn3ci='mvn3 clean install'
alias mvn3i='mvn3 install'
alias mvn3c='mvn3 clean'
alias mvn3t='mvn3 test'


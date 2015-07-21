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
alias ss='ssh -t "cd /opt/CSCOlumos; bash"'

alias tosvn=jump_to_svn_from_git

alias tmux='tmux -2'

alias m=mimeopen
alias e=extract
alias f='$(thefuck $(fc -ln -1))'

alias mvn3='mvn-color mvn3'
alias mvn3cie='mvn3 clean install eclipse:eclipse'
alias mvn3ci='mvn3 clean install'
alias mvn3cist='mvn3 clean install -DskipTests'
alias mvn3i='mvn3 install'
alias mvn3e='mvn3 eclipse:eclipse'
alias mvn3ce='mvn3 clean eclipse:clean eclipse:eclipse'
alias mvn3d='mvn3 deploy'
alias mvn3p='mvn3 package'
alias mvn3c='mvn3 clean'
alias mvn3com='mvn3 compile'
alias mvn3ct='mvn3 clean test'
alias mvn3t='mvn3 test'
alias mvn3ag='mvn3 archetype:generate'
alias mvn3-updates='mvn3 versions:display-dependency-updates'
alias mvn3tc7='mvn3 tomcat7:run'
alias mvn3tc='mvn3 tomcat:run'
alias mvn3jetty='mvn3 jetty:run'
alias mvn3dt='mvn3 dependency:tree'
alias mvn3s='mvn3 site'
alias mvn3src='mvn3 dependency:sources'
alias mvn3docs='mvn3 dependency:resolve -Dclassifier=javadoc'


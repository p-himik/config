#!/usr/bin/zsh
# This file should also be sourced in .xprofile
# That's why it's .sh and not .zsh

export JAVA7_HOME="/opt/jdk1.7.0_67"
export JAVA8_HOME="/opt/jdk1.8.0_91"
export JAVA_HOME="${JAVA8_HOME}"
export JDK_HOME="${JAVA_HOME}"
export IDEA_JDK="${JAVA8_HOME}"
export PYCHARM_JDK="${JAVA8_HOME}"
export HEROKU_HOME="/usr/local/heroku"
export ANACONDA3_HOME="$HOME/soft/anaconda3"
export PATH="$HOME/bin:$HOME/.local/bin:${JAVA_HOME}/bin:$PATH:${HEROKU_HOME}/bin:${ANACONDA3_HOME}/bin"
export GIT_ROOT="$HOME/dev/git"
export WINEARCH="win32"


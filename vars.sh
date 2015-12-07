#!/usr/bin/zsh

export JAVA6_HOME="/opt/jdk1.6.0_45"
export JAVA7_HOME="/opt/jdk1.7.0_67"
export JAVA8_HOME="/opt/jdk1.8.0_25"
export JAVA_HOME="${JAVA7_HOME}"
export JDK_HOME="${JAVA_HOME}"
export IDEA_JDK="${JAVA8_HOME}"
export PYCHARM_JDK="${JAVA8_HOME}"
export PS_SCRIPTS_DIR="$HOME/dev/ps-tools/scripts"
export JD_GUI_HOME="$HOME/soft/jd-gui"
export PATH="$HOME/bin:${JAVA_HOME}/bin:${PS_SCRIPTS_DIR}:${JD_GUI_HOME}:$PATH"
export GIT_ROOT="$HOME/dev/git"
export WINEARCH="win32"


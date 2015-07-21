#!zsh

# Modified version from lib/git
parse_git_dirty() {
  local STATUS=''
  local FLAGS
  FLAGS=('--porcelain')
  if [[ "$(command git config --get oh-my-zsh.hide-dirty)" != "1" ]]; then
    if [[ $POST_1_7_2_GIT -gt 0 ]]; then
      FLAGS+='--ignore-submodules=dirty'
    fi
    if [[ "$DISABLE_UNTRACKED_FILES_DIRTY" == "true" ]]; then
      FLAGS+='--untracked-files=no'
    fi
    STATUS=$(command git status ${FLAGS} 2> /dev/null | tail -n1)
  fi
  if [[ -n $STATUS ]]; then
    echo -n "$ZSH_THEME_GIT_PROMPT_DIRTY"
    if echo "$STATUS" | grep "^?? " -q; then
      echo -n "$ZSH_THEME_GIT_PROMPT_DIRTY_UNTRACKED"
    fi
  else
    echo -n "$ZSH_THEME_GIT_PROMPT_CLEAN"
  fi
}

# Modified version from git-fast
function git_prompt_info() {
  dirty="$(parse_git_dirty)"
  branch="$(git-get-current-branch-name 2>/dev/null)"
  desc="$(git-get-branch-description "$branch" 2>/dev/null)"
  if [[ -n "$desc" ]]; then
    desc=" \"$desc\""
  fi
  __git_ps1 "${ZSH_THEME_GIT_PROMPT_PREFIX//\%/%%}%s${dirty//\%/%%}${ZSH_THEME_GIT_PROMPT_DESCRIPTION_PREFIX//\%/%%}${desc//\%/%%}${ZSH_THEME_GIT_PROMPT_SUFFIX//\%/%%}"
}


alias gdm='git diff master'
alias gdmn='git diff master --name-only'
alias gdmnt='git diff master --name-only | tee'
alias gup='git up'
alias gdtm='git difftool -d master'
alias grbim='git rebase -i master'
alias gmm='git merge master'

function git-get-current-branch-name() {
    local ref=$(command git symbolic-ref HEAD)
    echo ${ref#refs/heads/}
}

function git-get-branch-description() {
    git config branch."$1".description
}

function git-change-branch-description() {
    git config branch."$1".description "$2"
}

function git-create-branch-with-description() {
    git checkout -b "$1"
    git-change-branch-description $1 $2
}
alias gcobd=git-create-branch-with-description

function git-change-current-branch-description() {
    git config branch."$(git-get-current-branch-name)".description "$1"
}
alias gccbd=git-change-current-branch-description

function git-commit-with-description() {
    local desc="$(git config branch."$(git-get-current-branch-name)".description)"
    if [[ -z $desc ]]; then
        echo "No description for current branch"
        return
    fi
    local flag=$1
    git commit $flag -m "$desc"
}
alias gcd=git-commit-with-description
alias gcad="git-commit-with-description -a"

function git-list-current-branches() {
    local r=
    local ref=
    local color=
    pushd
    for r in $GIT_ROOT/*; do
        echo $r;
        echo -n "    ";
        cd $r
        print -P $(git_prompt_info)
    done
    popd
}
alias glcb=git-list-current-branches

function git-list-branches-with-descriptions() {
    branches=("${(@f)$(command git branch | sed 's/[* ]//g')}")
    for branch in "${branches[@]}"; do
        description=$(git-get-branch-description "$branch")
        echo $branch $description
    done
}
alias glbd=git-list-branches-with-descriptions

alias gbcd=~/soft/git-branch-desc.sh


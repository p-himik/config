#!zsh

function fill-query-and-params {
    local query; query=()
    local params; params=()
    for a in $@; do
        if [[ "$a" =~ "^-" ]]; then
            params+=($a)
        else
            query+=($a)
        fi
    done
    export CMD_QUERY="$query"
    export CMD_PARAMS="$params"
}

function print-with-aliases {
    local query="$1"
    local total=$#INPUT_FILES_LIST
    local width=$((${#total} + 2))
    local -R $width i
    local c=1
    for (( j=1; j<=$gs_max_changes; j++ )); do unset $git_env_char$j; done
    for f in $INPUT_FILES_LIST; do
        if [[ $c -lt $gs_max_changes ]]; then
            export $git_env_char$c="$(readlink -f $f)"
            i="[$((c++))]"
        else
            i="[]"
        fi
        echo "$fg_bold[yellow]${i}$reset_color\t$f" | grep --color=always -i "$query"
    done
}

function find-with-alias {
    fill-query-and-params $@
    local INPUT_FILES_LIST
    INPUT_FILES_LIST=("${(f)$(find . $CMD_PARAMS -iname "*$CMD_QUERY*")}")
    print-with-aliases "$CMD_QUERY"
}
alias fn=find-with-alias

function locate-with-alias() {
    fill-query-and-params $@
    local INPUT_FILES_LIST
    if [[ -n "$CMD_QUERY" ]]; then
        INPUT_FILES_LIST=($(locate "$CMD_QUERY" $CMD_PARAMS))
        print-with-aliases "$CMD_QUERY"
    fi
}
alias lt=locate-with-alias


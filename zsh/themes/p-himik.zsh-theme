# https://github.com/blinks zsh theme

function codepoints() {
    printf 'U+%04x\n' ${@/#/\'}
}

function register_symbols() {
    local black_on_white="%K{white}%F{black}"
    local bold_black_on_white="%K{white}$fg_bold[black]"
    local black_on_red="%K{red}%F{black}"
    local bold_black_on_red="%K{red}$fg_bold[black]"
    local black_on_yellow="%K{yellow}%F{black}"

    local yellow_on_white="%K{white}%F{yellow}"
    local yellow_on_red="%K{red}%F{yellow}"
    local yellow_on_black="%K{black}%F{yellow}"
    local bold_yellow_on_black="%K{black}$fg_bold[yellow]"

    local red_on_white="%K{white}%F{red}"
    local red_on_black="%K{black}%F{red}"

    local white_on_red="%K{red}%F{white}"
    local white_on_black="%K{black}%F{white}"
    local white_on_magenta="%K{magenta}%F{white}"
    local white_on_blue="%K{blue}%F{white}"
    local bold_white_on_blue="%K{blue}$fg_bold[white]"

    local bold_blue_on_black="%K{black}$fg_bold[blue]"

    : ${omg_default_color_on:="${yellow_on_black}"}
    : ${omg_second_line:=' %#'}
    : ${omg_second_line_color:="${yellow_on_black}"}
    : ${omg_is_a_git_repo_symbol:='Ω'}
    : ${omg_is_a_git_repo_symbol_color:="${black_on_white}"}
    : ${omg_has_untracked_files_symbol:=''}
    : ${omg_has_untracked_files_symbol_color:="${black_on_red}"}
    : ${omg_has_adds_symbol:=''}
    : ${omg_has_adds_symbol_color:="${black_on_yellow}"}
    : ${omg_has_deletions_symbol:=''}
    : ${omg_has_deletions_symbol_color:="${black_on_red}"}
    : ${omg_has_cached_deletions_symbol:=''}
    : ${omg_has_cached_deletions_symbol_color:="${black_on_yellow}"}
    : ${omg_has_modifications_symbol:=''}
    : ${omg_has_modifications_symbol_color:="${black_on_red}"}
    : ${omg_has_cached_modifications_symbol:=''}
    : ${omg_has_cached_modifications_symbol_color:="${black_on_yellow}"}
    : ${omg_ready_to_commit_symbol:='→'}            #   →
    : ${omg_ready_to_commit_symbol_color:="${white_on_blue}"}
    : ${omg_is_on_a_tag_symbol:='⛿'}                #   
    : ${omg_is_on_a_tag_symbol_color:="${bold_white_on_blue}"}
    : ${omg_needs_to_merge_symbol:='≷'}
    : ${omg_needs_to_merge_symbol_color:="${white_on_magenta}"}
    : ${omg_detached_symbol:=''}
    : ${omg_detached_symbol_color:="${yellow_on_black}"}
    : ${omg_can_fast_forward_symbol:=''}
    : ${omg_can_fast_forward_symbol_color:="${white_on_magenta}"}
    : ${omg_has_diverged_symbol:=''}               #   
    : ${omg_has_diverged_symbol_color:="${white_on_magenta}"}
    : ${omg_not_tracked_branch_symbol:='≚'}
    : ${omg_not_tracked_branch_symbol_color:="${white_on_magenta}"}
    : ${omg_rebase_tracking_branch_symbol:=''}     #   
    : ${omg_rebase_tracking_branch_symbol_color:="${white_on_magenta}"}
    : ${omg_merge_tracking_branch_symbol:=''}      #  
    : ${omg_merge_tracking_branch_symbol_color:="${white_on_magenta}"}
    : ${omg_should_push_symbol:=''}
    : ${omg_should_push_symbol_color:="${white_on_magenta}"}
    : ${omg_in_sync_symbol:=' '}
    : ${omg_in_sync_symbol_color:="${white_on_magenta}"}
    : ${omg_has_stashes_symbol:='S'}
    : ${omg_has_stashes_symbol_color:="${white_on_magenta}"}
    : ${omg_has_action_in_progress_symbol:=''}
    : ${omg_has_action_in_progress_symbol_color:="${white_on_red}"}
    : ${omg_current_branch_color:="${bold_white_on_blue}"}
    : ${omg_branch_description_color:="${white_on_black}"}
}

register_symbols

autoload -U colors && colors

function get_current_action () {
    local info="$(git rev-parse --git-dir 2>/dev/null)"
    if [[ -n $info ]]; then
        local action
        if [[ -f $info/rebase-merge/interactive ]]; then
            action="rebase -i"
        elif [[ -d $info/rebase-merge ]]; then
            action="rebase -m"
        elif [[ -d $info/rebase-apply ]]; then
            if [[ -f $info/rebase-apply/rebasing ]]; then
                action="rebase"
            elif [[ -f $info/rebase-apply/applying ]]; then
                action="applying mailbox patches"
            else
                action="rebasing mailbox patches"
            fi
        elif [[ -f $info/MERGE_HEAD ]]; then
            action="merge"
        elif [[ -f $info/CHERRY_PICK_HEAD ]]; then
            action="cherry-pick"
        elif [[ -f $info/BISECT_LOG ]]; then
            action="bisect"
        fi

        echo -n $action
    fi
}

function ssh_connection() {
    if [[ -n ${SSH_CONNECTION} ]]; then
        echo "%{$fg_bold[red]%}($(hostname))"
    fi
}

function build_env_prompt() {
    local env_prompt
    if [[ -n ${CONTAINERS_GRAPHROOT} && -n ${CONTAINERS_RUNROOT} ]]; then
        env_prompt+="[podman unshare]"
    fi
    if [[ -n ${VIRTUAL_ENV} ]]; then
        env_prompt+="[`basename ${VIRTUAL_ENV}`]"
    fi
    if [[ -n ${CONDA_DEFAULT_ENV} ]]; then
        env_prompt+="($CONDA_DEFAULT_ENV)"
    fi
    if [[ -n ${env_prompt} ]]; then
        echo -n "%k%{$fg_bold[red]%}${env_prompt}%b${omg_default_color_on}"
    fi
}

function build_git_prompt {
    local current_commit_hash=$(git rev-parse HEAD 2> /dev/null)
    if [[ -n $current_commit_hash ]]; then
        local current_branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
        [[ $current_branch == 'HEAD' ]] && local detached=true

        local upstream=$(git rev-parse --symbolic-full-name --abbrev-ref @{upstream} 2> /dev/null)
        [[ -n "${upstream}" && "${upstream}" != "@{upstream}" ]] && local has_upstream=true

        local git_status="$(git status --porcelain 2> /dev/null)"
        [[ $git_status =~ ($'\n'|^).M ]] && local has_modifications=true
        [[ $git_status =~ ($'\n'|^)M ]] && local has_modifications_cached=true
        [[ $git_status =~ ($'\n'|^)A ]] && local has_adds=true
        [[ $git_status =~ ($'\n'|^).D ]] && local has_deletions=true
        [[ $git_status =~ ($'\n'|^)D ]] && local has_deletions_cached=true
        [[ $git_status =~ ($'\n'|^)[MAD] && ! $git_status =~ ($'\n'|^).[MAD\?] ]] && local ready_to_commit=true
        (\grep -q "^??" <<< "${git_status}") && local has_untracked_files=true

        [[ "$(git rev-list --walk-reflogs -n1 --count refs/stash 2> /dev/null)" -gt 0 ]] && local has_stashes=true

        local prompt="${omg_is_a_git_repo_symbol_color} ${omg_is_a_git_repo_symbol} "

        [[ -n $has_stashes ]] && prompt+="${omg_has_stashes_symbol_color} ${omg_has_stashes_symbol} "
        [[ -n $has_untracked_files ]] && prompt+="${omg_has_untracked_files_symbol_color} ${omg_has_untracked_files_symbol} "
        [[ -n $has_modifications ]] && prompt+="${omg_has_modifications_symbol_color} ${omg_has_modifications_symbol} "
        [[ -n $has_deletions ]] && prompt+="${omg_has_deletions_symbol_color} ${omg_has_deletions_symbol} "
        [[ -n $has_adds ]] && prompt+="${omg_has_adds_symbol_color} ${omg_has_adds_symbol} "
        [[ -n $has_modifications_cached ]] && prompt+="${omg_has_cached_modifications_symbol_color} ${omg_has_cached_modifications_symbol} "
        [[ -n $has_deletions_cached ]] && prompt+="${omg_has_cached_deletions_symbol_color} ${omg_has_cached_deletions_symbol} "
        local action="$(get_current_action)"
        [[ -n $action ]] && prompt+="${omg_has_action_in_progress_symbol_color}[ ${omg_has_action_in_progress_symbol} $action ]"
        [[ -n $ready_to_commit ]] && prompt+="${omg_ready_to_commit_symbol_color}[ ${omg_ready_to_commit_symbol} ]"

        if [[ -n $detached ]]; then
            prompt+="${omg_detached_symbol_color})[ ${omg_detached_symbol} (${current_commit_hash:0:7}) ]"
        else
            if [[ -n $has_upstream ]]; then
                local type_of_upstream
                local will_rebase=$(git config --get branch.${current_branch}.rebase 2> /dev/null)
                if [[ ${will_rebase} == true ]]; then
                    type_of_upstream=${omg_rebase_tracking_branch_symbol}
                else
                    type_of_upstream=${omg_merge_tracking_branch_symbol}
                fi

                local commits_ahead=0 commits_behind=0
                read -r commits_ahead commits_behind <<<$(git rev-list --left-right --count ${current_commit_hash}...${upstream} 2> /dev/null)

                if [[ $commits_ahead -gt 0 && $commits_behind -gt 0 ]]; then
                    prompt+="${omg_has_diverged_symbol_color}[ -${commits_behind} ${omg_has_diverged_symbol} +${commits_ahead} ]"
                else
                    if [[ ${commits_behind} -gt 0 ]]; then
                        prompt+="${omg_can_fast_forward_symbol_color}[ -${commits_behind} %F{white}${omg_can_fast_forward_symbol}%F{black} -- ]"
                    fi
                    if [[ ${commits_ahead} -gt 0 ]]; then
                        prompt+="${omg_should_push_symbol_color}[ -- %F{white}${omg_should_push_symbol}%F{black}  +${commits_ahead}%f ]"
                    fi
                    if [[ ${commits_ahead} == 0 && ${commits_behind} == 0 ]]; then
                         prompt+="${omg_in_sync_symbol_color}[ -- ${omg_in_sync_symbol} -- ]"
                    fi
                fi
                prompt+="${omg_current_branch_color}[ ${current_branch} ${type_of_upstream} ${upstream//\/$current_branch/} ]"
            else
                prompt+="${omg_not_tracked_branch_symbol_color}[ -- ${omg_not_tracked_branch_symbol} -- (${current_branch}) ]"
            fi
            local branch_description="$(git config "branch.${current_branch}.description")"
            [[ -n $branch_description ]] && prompt+="${omg_branch_description_color}[$(echo "${branch_description}" | sed 's/%/%%/g')]"
        fi

        local tag_at_current_commit=$(git describe --exact-match --tags $current_commit_hash 2> /dev/null)
        [[ -n $tag_at_current_commit ]] && prompt+="${omg_is_on_a_tag_symbol_color}[ ${omg_is_on_a_tag_symbol} ${tag_at_current_commit} ]"

        echo "${prompt}${omg_default_color_on}%E%b%k\n"
    fi
}

function build_prompt {
    local current_path="%~"
    local git_prompt="$(build_git_prompt)"
    if [[ -n $git_prompt ]]; then
        # Adding the status on a line above the main prompt.
        echo "$git_prompt"
    fi
    echo "$(build_env_prompt)${omg_default_color_on} ${current_path} $(ssh_connection)%E%b%k
${omg_second_line_color}${omg_second_line}%k%b "
}

function git-prompt-help() {
    for i in $(typeset + | grep "^omg_.*_symbol$"); do
        local s="${(P)i}"
        local color_var="${i}_color"
        local color="${(P)color_var}"
        local desc="$(echo $i | sed -r 's/^omg_(.*)_symbol$/\1/g' | tr '_' ' ')"
        print -P -- "${color} ${s} %f%k%b - ${desc}"
    done
}

PROMPT='$(build_prompt)'
RPROMPT='%* %D{%F} !%!%{%f%k%b%}'

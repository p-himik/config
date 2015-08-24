# https://github.com/blinks zsh theme

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
    : ${omg_ungit_prompt:=$PS1}
    : ${omg_second_line:=' %#'}
    : ${omg_second_line_color:="${yellow_on_black}"}
    : ${omg_is_a_git_repo_symbol:='Ω'}
    : ${omg_is_a_git_repo_symbol_color:="${black_on_white}"}
    : ${omg_has_untracked_files_symbol:=''}        #                ?    
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
    : ${omg_ready_to_commit_symbol:=''}            #   →
    : ${omg_ready_to_commit_symbol_color:="${white_on_blue}"}
    : ${omg_is_on_a_tag_symbol:='⛿'}                #   
    : ${omg_is_on_a_tag_symbol_color:="${bold_white_on_blue}"}
    : ${omg_needs_to_merge_symbol:='≷'}
    : ${omg_needs_to_merge_symbol_color:="${white_on_magenta}"}
    : ${omg_detached_symbol:='⊄'}
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
    : ${omg_should_push_symbol:=''}                #    
    : ${omg_should_push_symbol_color:="${white_on_magenta}"}
    : ${omg_in_sync_symbol:=' '}
    : ${omg_in_sync_symbol_color:="${white_on_magenta}"}
    : ${omg_has_stashes_symbol:='S'}
    : ${omg_has_stashes_symbol_color:="${white_on_magenta}"}
    : ${omg_has_action_in_progress_symbol:=''}     #                  
    : ${omg_has_action_in_progress_symbol_color:="${white_on_red}"}
    : ${omg_current_branch_color:="${bold_white_on_blue}"}
    : ${omg_branch_description_color:="${white_on_black}"}
}

register_symbols

autoload -U colors && colors

PROMPT='$(build_prompt)'
RPROMPT='%* %D{%F} !%!%{%f%k%b%}'

function enrich_append {
    local flag=$1
    local symbol=$2
    local color=${3:-$omg_default_color_on}
    if [[ ${flag} == false ]]; then
        symbol=''
        color=${omg_default_color_on}
    fi

    echo -n "${color}${symbol}%b${omg_default_color_on}"
}

function ssh_connection() {
    if [[ -n ${SSH_CONNECTION} ]]; then
        echo "%{$fg_bold[red]%}($(hostname)) %b"
    fi
}

function custom_build_prompt() {
    local enabled=${1}
    local current_commit_hash=${2}
    local is_a_git_repo=${3}
    local current_branch=$4
    local detached=${5}
    local just_init=${6}
    local has_upstream=${7}
    local has_modifications=${8}
    local has_modifications_cached=${9}
    local has_adds=${10}
    local has_deletions=${11}
    local has_deletions_cached=${12}
    local has_untracked_files=${13}
    local ready_to_commit=${14}
    local tag_at_current_commit=${15}
    local is_on_a_tag=${16}
    local has_upstream=${17}
    local commits_ahead=${18}
    local commits_behind=${19}
    local has_diverged=${20}
    local should_push=${21}
    local will_rebase=${22}
    local has_stashes=${23}
    local action=${24}

    local prompt=""
    if [[ ${is_a_git_repo} == true ]]; then
        # on filesystem
        prompt+=$(enrich_append ${is_a_git_repo} " ${omg_is_a_git_repo_symbol} " ${omg_is_a_git_repo_symbol_color})
        prompt+=$(enrich_append ${has_stashes} " ${omg_has_stashes_symbol} " ${omg_has_stashes_symbol_color})

        prompt+=$(enrich_append ${has_untracked_files} " ${omg_has_untracked_files_symbol} " ${omg_has_untracked_files_symbol_color})
        prompt+=$(enrich_append ${has_modifications} " ${omg_has_modifications_symbol} " ${omg_has_modifications_symbol_color})
        prompt+=$(enrich_append ${has_deletions} " ${omg_has_deletions_symbol} " ${omg_has_deletions_symbol_color})

        # ready
        prompt+=$(enrich_append ${has_adds} " ${omg_has_adds_symbol} " ${omg_has_adds_symbol_color})
        prompt+=$(enrich_append ${has_modifications_cached} " ${omg_has_cached_modifications_symbol} " ${omg_has_cached_modifications_symbol_color})
        prompt+=$(enrich_append ${has_deletions_cached} " ${omg_has_cached_deletions_symbol} " ${omg_has_cached_deletions_symbol_color})

        # next operation
        prompt+=$(enrich_append ${action} "[ ${omg_has_action_in_progress_symbol} $action ]" "${omg_has_action_in_progress_symbol_color}")
        prompt+=$(enrich_append ${ready_to_commit} "[ ${omg_ready_to_commit_symbol} ]" ${omg_ready_to_commit_symbol_color})

        # where
        if [[ ${detached} == true ]]; then
            prompt+=$(enrich_append ${detached} "[ ${omg_detached_symbol} (${current_commit_hash:0:7}) ]" ${omg_detached_symbol_color})
        else
            if [[ ${has_upstream} == false ]]; then
                prompt+=$(enrich_append true "[ -- ${omg_not_tracked_branch_symbol} -- (${current_branch}) ]" "${omg_not_tracked_branch_symbol_color}")
            else
                local type_of_upstream
                if [[ ${will_rebase} == true ]]; then
                    type_of_upstream=${omg_rebase_tracking_branch_symbol}
                else
                    type_of_upstream=${omg_merge_tracking_branch_symbol}
                fi

                if [[ ${has_diverged} == true ]]; then
                    prompt+=$(enrich_append true "[ -${commits_behind} ${omg_has_diverged_symbol} +${commits_ahead} ]" "${omg_has_diverged_symbol_color}")
                else
                    if [[ ${commits_behind} -gt 0 ]]; then
                        prompt+=$(enrich_append true "[ -${commits_behind} %F{white}${omg_can_fast_forward_symbol}%F{black} -- ]" "${omg_can_fast_forward_symbol_color}")
                    fi
                    if [[ ${commits_ahead} -gt 0 ]]; then
                        prompt+=$(enrich_append true "[ -- %F{white}${omg_should_push_symbol}%F{black}  +${commits_ahead}%f ]" "${omg_should_push_symbol_color}")
                    fi
                    if [[ ${commits_ahead} == 0 && ${commits_behind} == 0 ]]; then
                         prompt+=$(enrich_append true "[ -- ${omg_in_sync_symbol} -- ]" "${omg_in_sync_symbol_color}")
                    fi
                fi
                prompt+=$(enrich_append true "[ ${current_branch} ${type_of_upstream} ${upstream//\/$current_branch/} ]" "${omg_current_branch_color}")
            fi
            local branch_description="$(git config "branch.${current_branch}.description")"
            if [[ -n "$branch_description" ]]; then
                prompt+=$(enrich_append true "[${branch_description}]" "${omg_branch_description_color}")
            fi
        fi
        prompt+=$(enrich_append ${is_on_a_tag} "[ ${omg_is_on_a_tag_symbol} ${tag_at_current_commit} ]" "${omg_is_on_a_tag_symbol_color}")
        prompt+="%E%b%k
"
    fi
    local current_path="%~"
    prompt+="${omg_default_color_on} ${current_path} $(ssh_connection)%E%b%k
${omg_second_line_color}${omg_second_line}%k%b "

    echo "${prompt}"
}

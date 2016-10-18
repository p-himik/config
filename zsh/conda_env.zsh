if [[ ! $DISABLE_VENV_CD -eq 1 ]]; then
    if (( $+commands[conda] && $+commands[activate] && $+commands[deactivate] )); then
        # everything appears to be Ok
    else
        print "[conda_env] conda/activate/deactivate not in PATH" >&2
        return
    fi

    # Automatically activate Git projects or other customized projects with .conda_env file
    function workon_cwd {
        if [[ -z "$WORKON_CWD" ]]; then
            local WORKON_CWD=1
            # Check if this is a Git repo
            local GIT_REPO_ROOT=""
            local GIT_TOPLEVEL="$(git rev-parse --show-toplevel 2> /dev/null)"
            if [[ $? == 0 ]]; then
                GIT_REPO_ROOT="$GIT_TOPLEVEL"
            fi
            # Get absolute path, resolving symlinks
            local PROJECT_ROOT="${PWD:A}"
            while [[ "$PROJECT_ROOT" != "/" && ! -e "$PROJECT_ROOT/.conda_env" \
                   && ! -d "$PROJECT_ROOT/.git"  && "$PROJECT_ROOT" != "$GIT_REPO_ROOT" ]]; do
                PROJECT_ROOT="${PROJECT_ROOT:h}"
            done
            if [[ "$PROJECT_ROOT" == "/" ]]; then
                PROJECT_ROOT="."
            fi
            # Check for virtualenv name override
            if [[ -f "$PROJECT_ROOT/.conda_env" ]]; then
                ENV_NAME="$(cat "$PROJECT_ROOT/.conda_env")"
            else
                ENV_NAME=""
            fi
            if [[ "$ENV_NAME" != "" ]]; then
                # Activate the environment only if it is not already active
                if [[ "$CONDA_DEFAULT_ENV" != "$ENV_NAME" ]]; then
                    source activate "$ENV_NAME" && export CD_VIRTUAL_ENV="$ENV_NAME"
                fi
            elif [[ -n "$CD_VIRTUAL_ENV" && -n "$CONDA_DEFAULT_ENV" ]]; then
                # We've just left the repo, deactivate the environment
                # Note: this only happens if the virtualenv was activated automatically
                source deactivate && unset CD_VIRTUAL_ENV
            fi
        fi
    }

    # Append workon_cwd to the chpwd_functions array, so it will be called on cd
    # http://zsh.sourceforge.net/Doc/Release/Functions.html
    if ! (( $chpwd_functions[(I)workon_cwd] )); then
        chpwd_functions+=(workon_cwd)
    fi
fi

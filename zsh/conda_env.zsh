if [[ ! $DISABLE_VENV_CD -eq 1 ]]; then
    if ! type conda > /dev/null; then
        print "[conda_env] conda/activate/deactivate not in PATH" >&2
        return
    fi

    # Automatically activate venv specified in .conda_env file
    function workon_cwd {
        if [[ -z "$WORKON_CWD" ]]; then
            local WORKON_CWD=1
            # Get absolute path, resolving symlinks
            local PROJECT_ROOT="${PWD:A}"
            while [[ "$PROJECT_ROOT" != "/" && ! -e "$PROJECT_ROOT/.conda_env" ]]; do
                PROJECT_ROOT="${PROJECT_ROOT:h}"
            done
            if [[ "$PROJECT_ROOT" == "/" ]]; then
                PROJECT_ROOT="."
            fi
            # Check for virtualenv name override
            ENV_NAME="$(cat "$PROJECT_ROOT/.conda_env" 2>/dev/null)"
            if [[ "$ENV_NAME" != "" ]]; then
                # Activate the environment only if it is not already active
                if [[ "$CONDA_DEFAULT_ENV" != "$ENV_NAME" ]]; then
                    conda activate "$ENV_NAME" && export CD_VIRTUAL_ENV="$ENV_NAME"
                fi
            elif [[ -n "$CD_VIRTUAL_ENV" && -n "$CONDA_DEFAULT_ENV" ]]; then
                # We've just left the repo, deactivate the environment
                # Note: this only happens if the virtualenv was activated automatically
                conda deactivate && unset CD_VIRTUAL_ENV
            fi
        fi
    }

    # Append workon_cwd to the chpwd_functions array, so it will be called on cd
    # http://zsh.sourceforge.net/Doc/Release/Functions.html
    if ! (( $chpwd_functions[(I)workon_cwd] )); then
        chpwd_functions+=(workon_cwd)
    fi
fi

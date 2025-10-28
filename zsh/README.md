Add `source "$HOME/.common_env"` to both `~/.zshenv` and `~/.profile`
to make sure that the common environment is loaded in any shell.

A skeleton of `~/.common_env`:

```shell
if [[ -z "$COMMON_ENV_HAS_BEEN_SET" ]]; then
    export COMMON_ENV_HAS_BEEN_SET='true'

    export PATH="$HOME/bin:$HOME/.local/bin"
fi
```

Put any machine-specific or sensitive environment variables in `~/.common_env`.

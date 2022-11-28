# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login exists.

prepend_path() {
    if [ -d "$1" ]; then
        PATH="$1:$PATH"
    fi
}

export EDITOR=/usr/bin/vim
export VISUAL=/usr/bin/vim

### Add to PATH ###

export VOLTA_HOME="$HOME/.volta"
prepend_path "$VOLTA_HOME/bin"

prepend_path "$HOME/go/bin"
prepend_path "$HOME/.deno"
prepend_path "$HOME/.local/bin"
prepend_path "$HOME/bin"

### Source scripts ###

if [ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi

if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

# vim: expandtab shiftwidth=4

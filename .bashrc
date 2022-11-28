# ~/.bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

shopt -s globstar # Expand "**" to 0 or more directories/subdirectories/files
shopt -s histappend # Append to the history file, don't overwrite it

HISTCONTROL=ignoreboth # Don't save duplicate lines or lines starting with space
HISTSIZE=1000 # The number of lines to remember in each bash session
HISTFILESIZE=2000 # The number of lines to store in the history file
FUNCNEST=100 # Limit recursive function nesting

## Use the up and down arrow keys for finding a command in history
## (you can write some initial letters of the command first).
bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'

# Load dircolors
if [[ -f ~/.dircolors ]]; then
    eval "$(dircolors -b ~/.dircolors)"
else
    eval "$(dircolors -b)"
fi


### Configure prompt using __git_ps1 ###

# Load __git_ps1 function if not already defined
if [[ "$(type -t  __git_ps1)" != 'function' ]]; then
    if [[ -f /usr/share/git/git-prompt.sh ]]; then
        . /usr/share/git/git-prompt.sh
    elif [[ -f /usr/lib/git-core/git-sh-prompt ]]; then
        . /usr/lib/git-core/git-sh-prompt
    else
        echo 'Error: Definition for __git_ps1 could not be found'
    fi
fi

# Configure __git_ps1 behavior
GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWSTASHSTATE=1
GIT_PS1_SHOWUNTRACKEDFILES=1
# GIT_PS1_SHOWUPSTREAM
GIT_PS1_STATESEPARATOR=''
# GIT_PS1_COMPRESSSPARSESTATE
# GIT_PS1_OMITSPARSESTATE
GIT_PS1_SHOWCONFLICTSTATE=yes
# GIT_PS1_DESCRIBE_STYLE
GIT_PS1_SHOWCOLORHINTS=1 # This requires using PROMPT_COMMAND instead of PS1
# GIT_PS1_HIDE_IF_PWD_IGNORED

# Define PROMPT_COMMAND, which will set PS1 on the fly
__prompt_info() {
    local BOLD_GREEN="\[\e[1;32m\]"
    local BOLD_BLUE="\[\e[1;34m\]"
    local RESET="\[\e[0m\]"

    # Format: ${USER}@${HOST}:${PWD}
    echo "${BOLD_GREEN}\u@\h${RESET}:${BOLD_BLUE}\w${RESET}"

    # To explicitly set the XTerm window title, comment out the echo command
    # above and uncomment these two lines:
    # local SET_XTERM_TITLE='\[\e]0;\u@\h: \w\a\]'
    # echo "${SET_XTERM_TITLE}${BOLD_GREEN}\u@\h${RESET}:${BOLD_BLUE}\w${RESET}"
}
if [[ "$(type -t __git_ps1)" == 'function' ]]; then
    PROMPT_COMMAND="__git_ps1 '$(__prompt_info)' '\\$ ' '(%s)'"
else
    export PS1="$(__prompt_info)$ "
fi
unset __prompt_info


### Aliases and functions ###

# Set default flags
alias ls='ls --color=auto --group-directories-first'
alias grep='grep --color=auto'
alias tree='tree --dirsfirst'
alias cp='cp -i' # Prompt before overwriting
alias bc='bc --quiet --mathlib'
alias gpg='gpg --verbose' # Not set in config, so only verbose when interactive
alias ffmpeg='ffmpeg -hide_banner'
alias ffplay='ffplay -hide_banner'
alias ffprobe='ffprobe -hide_banner'

alias ll='ls -lA'
alias la='ls -A'
alias o='xdg-open'
alias terminal='xfce4-terminal'
alias memuse='ps -o pid,user,%mem,command -ax --sort=-%mem | less -S'

# Open all git-tracked text files in [g]vim, even with spaces in filepaths
# The unescaped ex command run inside vim:
#     :argadd `git grep --recurse-submodules -Il ''` | rewind
alias vvim='vim -c "argadd \`git grep --recurse-submodules -Il '"''"'\`" -c "rewind"'
alias ggvim='vvim -g'

clock() {
  while true; do
    printf "\r$(date -uIseconds)" # Print UTC date in ISO format
    sleep 0.01
  done
}

# Allow for additional local bashrc, not tracked in dotfiles repo
[[ -f ~/.bashrc.local ]] && . ~/.bashrc.local

# vim: expandtab shiftwidth=4

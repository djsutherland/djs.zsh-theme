autoload -Uz add-zsh-hook
autoload -Uz colors && colors

_filename=${(%):-%x} # https://stackoverflow.com/a/28336473
_dirname=$_filename:a:h  # a = absolute, h = dirname (???)

if [[ "$TERM" = "screen" ]]; then  # emoji act weird inside tmux/screen
    function emoji_or_backup { echo $2; }
else
    function emoji_or_backup { echo "$1"; }
fi

function christmas-tree {
    d=$(date '+%m %d' | sed 's/^ *//; s/^0//; s/ /./'); # eg '12.01' or '01.03'
    if [[ $d -ge 12.10 && $d -le 12.25 ]]; then
        emoji_or_backup '\U0001F384' '$'
    else
        echo '$'
    fi
}

if (( $+commands[scutil] )); then
    host=$(scutil --get LocalHostName)
else
    host=$(hostname || echo "%m")
fi

if [[ -z "$EXPECTED_USER" || $USER != $EXPECTED_USER ]]; then
	userhost="%(!.%{$fg_bold[red]%}.%{$fg_bold[green]%})%n@$host"
else
	userhost="%{$fg_bold[green]%}$host"
fi

if [[ -n "$SHOW_BATTERY" ]]; then
    # TODO: color the hostname instead of the time?
    function battery_color {
        # argument: battery percent, 0 to 100
        # spit out the appropriate color
        # not sure why $fg doesn't work here...
        if [ $1 -ge 60 ]; then
            echo '%{[32m%}' # green
        elif [ $1 -ge 30 ]; then
            echo '%{[1;33m%}' # yellow
        else
            echo '%{[31m%}' # red
        fi
    }

    if [[ $OSTYPE == darwin* ]]; then
    	function battery_charge {
    		# get the relevant numbers
    		res=$(ioreg -rc AppleSmartBattery | egrep '"(Max|Current)Capacity"')
    		max=$(echo $res | grep Max | egrep -o '[[:digit:]]+')
    		curr=$(echo $res | grep Current | egrep -o '[[:digit:]]+')

    		# divide
    		portion=`echo "100 * $curr / $max" | bc` # no -l, so int division

            battery_color $portion
    	}
    else
        function battery_charge {
            res=$(acpi | grep -Po '\d+(?=%)')
            battery_color $res
        }
    fi

    time_color='$(battery_charge)'
else
    time_color='%{$fg[magenta]%}'
fi

time_str='%D{%K:%M}'


# Use standard vcs_info, but in a zsh-async wrapper,
# if zsh version is at least 5.1; it seems to break in 5.0.2 anyway.
# Assumes zsh-async is sourced already; https://github.com/mafredri/zsh-async
# Have to (I think?) call separate git-info script, unfortunately...
autoload is-at-least
if is-at-least 5.1 $ZSH_VERSION; then
    vcs_info_msg_0_=""
    function git_callback {
        vcs_info_msg_0_=$3
        zle && zle reset-prompt
    }
    function launch_async_vcs_info {
        vcs_info_msg_0_=""  # avoid leaving old info...
        if ! async_job git_prompt_worker "$_dirname/git-script" "$PWD"; then
            # not sure why worker dies like this...
            async_start_worker git_prompt_worker
            async_job git_prompt_worker "$_dirname/git-script" "$PWD"
        fi
    }

    async_init
    async_start_worker git_prompt_worker
    async_register_callback git_prompt_worker git_callback
    add-zsh-hook precmd launch_async_vcs_info
else;  # synchronous git prompt
    source "$_dirname/git-format"
    add-zsh-hook precmd vcs_info
fi

# Show return code if last command failed; based on dieter.zsh-theme
retcode_enabled="%(?.. %{$fg_bold[red]%}%?)"
retcode_disabled=''
retcode=$retcode_enabled

function accept-line-or-clear-warning () {
	if [[ -z $BUFFER ]]; then
		retcode=$retcode_disabled
	else
		retcode=$retcode_enabled
	fi
	zle accept-line
}
zle -N accept-line-or-clear-warning
bindkey '^M' accept-line-or-clear-warning

function anaconda_prompt_info() {
    if [[ -n $CONDA_DEFAULT_ENV ]]; then
        echo -n "%{$fg[cyan]%}$CONDA_DEFAULT_ENV"
        if [[ $CONDA_SHLVL -gt 1 ]]; then
            local _extra
            (( _extra = $CONDA_SHLVL - 1 ))
            echo "%{$fg[red]%}(+${_extra}) "
        else
            echo " "
        fi
    fi
}


PROMPT=$userhost'%{$reset_color%}:%{$fg_bold[blue]%}%~%(!.%{$fg[red]%}#%{$reset_color%}.%{$reset_color%}$(christmas-tree)) '
RPROMPT='[$vcs_info_msg_0_$(anaconda_prompt_info)'$time_color$time_str'${retcode}%{$reset_color%}]'

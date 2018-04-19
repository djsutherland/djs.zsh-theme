function christmas-tree () {
    d=$(date '+%m %d' | sed 's/^ *//; s/^0//; s/ /./'); # eg '12.01' or '01.03'
    if [[ $d -ge 12.10 && $d -le 12.25 ]]; then
        echo "%2{"$'\U0001F384 '"%}"
    else
        echo -e '$'
    fi
}

if (( $+commands[scutil] )); then
    host=$(scutil --get LocalHostName)
else
    host="%m"
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
    		res=$(ioreg -rc AppleSmartBattery | egrep '(MaxCapacity|CurrentCapacity)')
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

    local time_color='$(battery_charge)'
else
    local time_color='%{$fg[magenta]%}'
fi

local time_str='%D{%K:%M}'


autoload -Uz add-zsh-hook
autoload -Uz vcs_info
autoload -Uz colors && colors
add-zsh-hook precmd vcs_info

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:git*' formats "%{$fg[yellow]%}%b%{$reset_color%}%m%u%c%{$reset_color%} "
zstyle ':vcs_info:git*' actions "%{$fg[yellow]%}%b%{$reset_color%}%m%u%c%{$reset_color%} (%a) "

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
        echo "%{$fg[cyan]%}$CONDA_DEFAULT_ENV "
    fi
}


PROMPT='%{$fg_bold[blue]%}%~%(!.%{$fg[red]%}#%{$reset_color%}.%{$reset_color%}$(christmas-tree)) '
RPROMPT='[$vcs_info_msg_0_$(anaconda_prompt_info)'$userhost' '$time_color$time_str'${retcode}%{$reset_color%}]'

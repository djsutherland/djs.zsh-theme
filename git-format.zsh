autoload -Uz add-zsh-hook
autoload -Uz vcs_info
autoload -Uz colors && colors

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:git*' formats "%{$fg[yellow]%}%b%{$reset_color%}%m%u%c%{$reset_color%} "
zstyle ':vcs_info:git*' actions "%{$fg[yellow]%}%b%{$reset_color%}%m%u%c%{$reset_color%} (%a) "

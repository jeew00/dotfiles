## gitstatus thanks to romkatv/gitstatus
source ~/gitstatus/gitstatus.prompt.zsh

## colors
autoload -U colors && colors
export LSCOLORS='gxfxcxdxbxegedabagacad'
export LS_COLORS='di=36:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'

## options
# case insensitive globbing
setopt NO_CASE_GLOB
# automatic cd aka change dir without cd
setopt AUTO_CD
# autocomplete
autoload -Uz compinit && compinit
# case insensitive path-completion 
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*'
# tab completion highlight
zstyle ':completion:*' menu select
zmodload zsh/complist
LS_COLORS='no=00;37:fi=00:di=00;33:ln=04;36:pi=40;33:so=01;35:bd=40;33;01:'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# use the vi navigation keys in menu completion
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

## prompt (double quote is buggy with vcs_info btw)
PROMPT='%F{120}%n@%m%F{white}:%F{219}%~ %F{white}%# '
RPROMPT='$GITSTATUS_PROMPT'

## alias
alias vim='nvim'
alias ls='ls -Gp'

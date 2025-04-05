# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#export JAVA_HOME=$(/usr/libexec/java_home -v22)

alias ls='ls -aG'
alias ll='ls -aGlh'

source <(fzf --zsh)

source $(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme
source $(brew --prefix)/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

(( ${+FAST_HIGHLIGHT_STYLES} )) || typeset -A FAST_HIGHLIGHT_STYLES
FAST_HIGHLIGHT_STYLES[path]="fg=magenta"
FAST_HIGHLIGHT_STYLES[path-to-dir]="fg=magenta"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

#!/usr/bin/env bash

###########################################
# Search with ripgrep
# Toggle fzf functionality for fuzzy match
# Toggle back to make a different query
# Ref: https://github.com/junegunn/fzf/blob/master/ADVANCED.md#using-fzf-as-interative-ripgrep-launcher
###########################################

# Use env variable to setup an editor or default to nvim
editor="${PREFERED_EDITOR:-nvim}"

# Switch between Ripgrep launcher mode (CTRL-R) and fzf filtering mode (CTRL-F)
RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case --no-ignore --glob '!{.git,node_modules}' --hidden "
INITIAL_QUERY="${*:-}"
IFS=: read -ra selected < <(
  FZF_DEFAULT_COMMAND="$RG_PREFIX $(printf %q "$INITIAL_QUERY")" \
  fzf --ansi \
      --color "hl:-1:underline,hl+:-1:underline:reverse" \
      --disabled --query "$INITIAL_QUERY" \
      --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
      --bind "ctrl-f:unbind(change,ctrl-f)+change-prompt(2. fzf> )+enable-search+clear-query+rebind(ctrl-r)" \
      --bind "ctrl-r:unbind(ctrl-r)+change-prompt(1. ripgrep> )+disable-search+reload($RG_PREFIX {q} || true)+rebind(change,ctrl-f)" \
      --bind "ctrl-/:change-preview-window(right|hidden|),alt-up:preview-page-up,alt-down:preview-page-down,ctrl-s:toggle-sort" \
      --prompt '1. Ripgrep> ' \
      --delimiter : \
      --header '╱ CTRL-R (Ripgrep mode) ╱ CTRL-F (fzf mode) ╱' \
      --preview 'bat --color=always {1} --highlight-line {2}' \
      --preview-window 'up,60%,border-bottom,+{2}+3/3,~3'
)
[ -n "${selected[0]}" ] && "$editor" "${selected[0]}" "+${selected[1]}"

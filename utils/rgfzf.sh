#!/usr/bin/env bash

###########################################
# Search with ripgrep
# Toggle fzf functionality for fuzzy match
# Toggle back to make a different query
# Ref: https://github.com/junegunn/fzf/blob/master/ADVANCED.md#using-fzf-as-interative-ripgrep-launcher
# Ref: https://junegunn.github.io/fzf/tips/ripgrep-integration/
###########################################

# Old implementation
# # Use env variable to setup an editor or default to nvim
# editor="${PREFERRED_EDITOR:-nvim}"

# # Switch between Ripgrep launcher mode (CTRL-R) and fzf filtering mode (CTRL-F)
# RG_PREFIX="${RFV_PREFIX_COMMAND:-rg --column --line-number --no-heading --color=always --smart-case --no-ignore --glob '!{.git,node_modules}' --hidden} "
# INITIAL_QUERY="${*:-}"
# IFS=: read -ra selected < <(
#   FZF_DEFAULT_COMMAND="$RG_PREFIX $(printf %q "$INITIAL_QUERY")" \
#   fzf --ansi \
#       --color "hl:-1:underline,hl+:-1:underline:reverse" \
#       --disabled --query "$INITIAL_QUERY" \
#       --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
#       --bind "ctrl-f:unbind(change,ctrl-f)+change-prompt(2. fzf> )+enable-search+clear-query+rebind(ctrl-r)" \
#       --bind "ctrl-r:unbind(ctrl-r)+change-prompt(1. ripgrep> )+disable-search+reload($RG_PREFIX {q} || true)+rebind(change,ctrl-f)" \
#       --bind "ctrl-/:change-preview-window(right|hidden|),alt-up:preview-page-up,alt-down:preview-page-down,ctrl-s:toggle-sort" \
#       --prompt '1. Ripgrep> ' \
#       --delimiter : \
#       --header '╱ CTRL-R (Ripgrep mode) ╱ CTRL-F (fzf mode) ╱' \
#       --preview 'bat --color=always {1} --highlight-line {2}' \
#       --preview-window 'up,60%,border-bottom,+{2}+3/3,~3'
# )
# [ -n "${selected[0]}" ] && "$editor" "${selected[0]}" "+${selected[1]}"

# New implementation has support for multiple selection
# and will list the files on quickfix list

editor="${PREFERRED_EDITOR:-${EDITOR:-vim}}"
RG_PREFIX="${RFV_PREFIX_COMMAND:-rg --column --line-number --no-heading --color=always --smart-case --no-ignore --glob '!.git' --glob '!node_modules' --hidden} "
RELOAD="reload:$RG_PREFIX {q} || :"

editorOptions="${EDITOR_OPTS:-}"

open_vim () {
  local -n selections=$1
  
  if [ "${#selections[@]}" = 1 ]; then
    args="$(awk -F: '{ printf "'\''%s'\'' +%s", $1, $2}' <<< "${selections[0]}")"
    eval "$editor $editorOptions $args"
  else
    temp_qf="$(mktemp)"
    trap "rm -rf '$temp_qf' &>/dev/null" EXIT
    printf '%s\n' "${selections[@]}" > "$temp_qf"
    eval "$editor $editorOptions +cw -q $temp_qf"
  fi
}

open_vscode () {
  local -n selections=$1

  # HACK to check to see if we're running under Visual Studio Code.
  # If so, reuse Visual Studio Code currently open windows:
  [[ -v VSCODE_PID ]] && editorOptions="$editorOptions --reuse-window"

  for selection in "${selections[@]}"; do
    args="$(awk -F: '{ printf "--goto '\''%s:%s'\''", $1, $2 }' <<< "$selection")"
    eval "$editor $editorOptions $args"
  done
}

open_nano () {
  local -n selections=$1

  if [ "${#selections[@]}" = 1 ]; then
    args="$(awk -F: '{ printf "+%s '\''%s'\''", $2, $1 }' <<< "${selections[0]}")"
    eval "$editor $editorOptions $args"
  else
    mapfile -t args < <(
      printf '%s\n' "${selections[@]}" |
        awk -F: '{ printf "'\''%s'\''", $1 }'
    )
    eval "$editor $editorOptions ${args[*]}"
  fi
}

open_generic () {
  local -n selections=$1

  mapfile -t args < <(
    printf '%s\n' "${selections[@]}" |
      awk -F: '{ printf "'\''%s'\''", $1 }'
  )
  eval "$editor $editorOptions ${args[*]}"
}

mapfile -t selected < <(
  fzf \
    --header '╱ CTRL-R (Ripgrep mode) ╱ CTRL-F (fzf mode) ╱' \
    --disabled --ansi --multi \
    --cycle \
    --input-border \
    --bind 'alt-up:preview-page-up,alt-down:preview-page-down' \
    --bind 'ctrl-s:toggle-sort' \
    --bind 'alt-f:first' \
    --bind 'alt-l:last' \
    --bind 'alt-c:clear-query' \
    --bind 'alt-a:select-all' \
    --bind 'alt-d:deselect-all' \
    --bind "ctrl-^:toggle-preview" \
    --bind "ctrl-l:toggle-preview" \
    --bind 'ctrl-/:toggle-preview' \
    --bind "start:$RELOAD" \
    --bind "change:$RELOAD" \
    --bind "ctrl-r:unbind(ctrl-r)+change-prompt(1. 🔎 ripgrep> )+disable-search+reload($RG_PREFIX {q} || :)+rebind(change,ctrl-f)" \
    --bind "ctrl-f:unbind(change,ctrl-f)+change-prompt(2. ✅ fzf> )+enable-search+clear-query+rebind(ctrl-r)" \
    --prompt '1. 🔎 ripgrep> ' \
    --delimiter : \
    --preview 'bat --style=full --color=always --highlight-line {2} {1}' \
    --preview-window '~4,+{2}+4/3,<80(up),wrap' \
    --query "$*"
)

if [ "${#selected[@]}" = 0 ]; then
  exit
elif [[ $editor =~ .*vim? ]]; then
  open_vim selected
elif [ "$editor" = 'code' ] || [ "$editor" = 'code-insiders' ] || [ "$editor" = 'codium' ]; then
  open_vscode selected
elif [ "$editor" = 'nano' ]; then
  open_nano selected
else
  open_generic selected
fi


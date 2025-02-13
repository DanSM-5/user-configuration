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

editor="${PREFERRED_EDITOR:-nvim}"
RG_PREFIX="${RFV_PREFIX_COMMAND:-rg --column --line-number --no-heading --color=always --smart-case --no-ignore --glob '!.git' --glob '!node_modules' --hidden} "
RELOAD="reload:$RG_PREFIX {q} || :"
TEMP_FILE='{+f}'

case "$(uname -a)" in
  MINGW*|MSYS*|CYGWIN*|*NT*)
    # NOTE: On windows the temporary file template needs quotations
    TEMP_FILE='"{+f}"'
    ;;
esac

if [[ "$editor" =~ .*vim? ]]; then
  OPENER="if [[ \$FZF_SELECT_COUNT -eq 0 ]]; then
            $editor {1} +{2}     # No selection. Open the current line in Vim.
          else
            # nvim {+f}  # Build quickfix list for the selected items.
            $editor +cw -q $TEMP_FILE  # Build quickfix list for the selected items.
          fi"
else
  # Handle non vim editors
  OPENER="if [[ \$FZF_SELECT_COUNT -eq 0 ]]; then
            $editor {1}
          else
            code \$(awk -F: '{print \$1}' $TEMP_FILE | tr '\\\\' '/')
          fi"
fi

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
  --bind "enter:become:$OPENER" \
  --bind "ctrl-o:execute:$OPENER" \
  --bind "ctrl-r:unbind(ctrl-r)+change-prompt(1. 🔎 ripgrep> )+disable-search+reload($RG_PREFIX {q} || :)+rebind(change,ctrl-f)" \
  --bind "ctrl-f:unbind(change,ctrl-f)+change-prompt(2. ✅ fzf> )+enable-search+clear-query+rebind(ctrl-r)" \
  --prompt '1. 🔎 ripgrep> ' \
  --delimiter : \
  --preview 'bat --style=full --color=always --highlight-line {2} {1}' \
  --preview-window '~4,+{2}+4/3,<80(up),wrap' \
  --query "$*"


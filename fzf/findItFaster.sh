#!/usr/bin/env bash

# Configuration location
export user_conf_path="${user_conf_path:-"$HOME/.usr_conf"}"
# Scripts location
export user_scripts_path="${user_scripts_path:-"$HOME/user-scripts"}"
# Project specific files location
export prj="${prj:-"$HOME/prj"}"
# Cache files location
export user_config_cache="${user_config_cache:-"$HOME/.cache/.user_config_cache"}"

if [ "$IS_GITBASH" = true ]; then
  # Replace all backslash '\' into forward slash '/'
  SHOME="${USERPROFILE//\\//}"
  SCONF="${user_conf_path//\\//}"
  # SCRIP="${user_scripts_path//\\//}"
else
  SHOME="$HOME"
  SCONF="$user_conf_path"
  # SCRIP="$user_scripts_path"
fi

# fzf history location
export FZF_HIST_DIR="$SHOME/.cache/fzf-history"
export COLORTERM='truecolor'
# export TERM="${TERM:-xterm-256color}"
export BAT_THEME='OneHalfDark'


# Find clipboard utility
copy='true'
if [ "$OS" = 'Windows_NT' ]; then
  # Gitbash
  copy="cat.exe '{+f}' | clip.exe"
elif [ "$OSTYPE" = 'darwin' ]; then
  copy="cat {+f} | pbcopy"
# Assume linux if above didn't match
elif [ -n "$WAYLAND_DISPLAY" ] && command -v 'wl-copy' &>/dev/null; then
  copy="cat {+f} | wl-copy --foreground --type text/plain"
elif [ -n "$DISPLAY" ] && command -v 'xsel' &>/dev/null; then
  copy="cat {+f} | xsel -i -b"
elif [ -n "$DISPLAY" ] && command -v 'xclip' &>/dev/null; then
  copy="cat {+f} | xclip -i -selection clipboard"
fi

# export FIND_FILES_PREVIEW_ENABLED=0
# export FIND_FILES_PREVIEW_COMMAND='bat --decorations=always --color=always --plain {}'
export FIND_FILES_PREVIEW_WINDOW_CONFIG='right:50%:wrap:border-left'
export FIND_WITHIN_FILES_PREVIEW_WINDOW_CONFIG='right:wrap:border-left:50%:+{2}+3/3:~3'
# export HAS_SELECTION=0
# export SELECTION_FILE=""

export FZF_DEFAULT_OPTS_FILE="$SCONF/fzf/fzf-default-opts"
export FZF_DEFAULT_OPTS="
  --history="$FZF_HIST_DIR/fzf-findItFaster"
  --input-border
  --bind 'alt-a:select-all'
  --bind 'alt-d:deselect-all'
  --bind 'alt-f:first'
  --bind 'alt-l:last'
  --bind 'alt-c:clear-query'
  --bind 'ctrl-^:toggle-preview'
  --bind 'ctrl-]:toggle-preview'
  --bind 'ctrl-/:change-preview-window(down,100,border-rounded|hidden|)'
  --bind 'alt-up:preview-page-up,alt-down:preview-page-down'
  --bind 'ctrl-s:toggle-sort'
  --bind 'ctrl-y:execute-silent($copy)+bell'
  --preview-window 'right,50%,wrap,border-left'
  --color header:italic
  --ansi --cycle
  --height '100%'
  --prompt 'Find> '
  --bind 'ctrl-t:unbind(change,ctrl-t)+change-prompt(Filter> )+enable-search+clear-query+rebind(ctrl-r)'
  --bind 'ctrl-r:unbind(ctrl-r)+change-prompt(Find> )+disable-search+rebind(change,ctrl-t)'
"

[ ! -d "$FZF_HIST_DIR" ] && mkdir -p "$FZF_HIST_DIR"

# Unset helper variables
unset copy
unset SHOME
unset SCONF
# unset SCRIP

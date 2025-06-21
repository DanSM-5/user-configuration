#!/usr/bin/env pwsh

# Configuration location
$user_conf_path = if ($env:user_conf_path) { $env:user_conf_path } else { "${HOME}${dirsep}.usr_conf" }
# Scripts location
$user_scripts_path = if ($env:user_scripts_path) { $env:user_scripts_path } else { "${HOME}${dirsep}user-scripts" }
# Project specific files location
$prj = if ($env:prj) { $env:prj } else { "${HOME}${dirsep}prj" }
# Cache files location
$user_config_cache = if ($env:user_config_cache) { $env:user_config_cache } else { "${HOME}${dirsep}.cache${dirsep}.user_config_cache" }

$SHOME = $HOME.Replace('\', '/')
$SCONF = $user_conf_path.Replace('\', '/')
# $SCRIP = $user_scripts_path.Replace('\', '/')

# fzf history location
$env:FZF_HIST_DIR = "$SHOME/.cache/fzf-history" 
$env:COLORTERM = 'truecolor'
# $env:TERM = if ($env:TERM) { $env:TERM } else { "xterm-256color" }
$env:BAT_THEME = 'OneHalfDark'

$copy = 'Get-Content {+f} | Set-Clipboard'

# $env:FIND_FILES_PREVIEW_ENABLED = 0
# $env:FIND_FILES_PREVIEW_COMMAND = 'bat --decorations=always --color=always --plain {}'
$env:FIND_FILES_PREVIEW_WINDOW_CONFIG = 'right:50%:wrap:border-left'
$env:FIND_WITHIN_FILES_PREVIEW_WINDOW_CONFIG = 'right:wrap:border-left:50%:+{2}+3/3:~3'
# $env:HAS_SELECTION = 0
# $env:SELECTION_FILE = ""

$env:FZF_DEFAULT_OPTS_FILE = "$SCONF/fzf/fzf-default-opts"
$env:FZF_DEFAULT_OPTS = "
  --history=$env:FZF_HIST_DIR/fzf-findItFaster
  --input-border
  --bind 'alt-a:select-all'
  --bind 'alt-d:deselect-all'
  --bind 'alt-f:first'
  --bind 'alt-l:last'
  --bind 'alt-c:clear-query'
  --bind 'ctrl-^:toggle-preview'
  --bind 'ctrl-]:toggle-preview'
  --bind 'ctrl-/:change-preview-window(down,border-rounded|hidden|)'
  --bind 'alt-up:preview-page-up,alt-down:preview-page-down'
  --bind 'ctrl-s:toggle-sort'
  --bind 'ctrl-y:execute-silent($copy)+bell'
  --preview-window 'right,50%,wrap,border-left'
  --color 'header:italic'
  --ansi '--cycle'
  --height '99%'
  --with-shell 'pwsh --NoLogo -NonInteractive -NoProfile -Command'
  --prompt 'Find> '
  --bind 'ctrl-t:unbind(change,ctrl-t)+change-prompt(Filter> )+enable-search+clear-query+rebind(ctrl-r)'
  --bind 'ctrl-r:unbind(ctrl-r)+change-prompt(Find> )+disable-search+rebind(change,ctrl-t)'
"

if (!(Test-Path -PathType Container -Path $env:FZF_HIST_DIR -ErrorAction SilentlyContinue)) {
  New-Item -Path $env:FZF_HIST_DIR -ItemType Directory -ErrorAction SilentlyContinue
}

# Unset helper variables
Remove-Variable copy
Remove-Variable SHOME
Remove-Variable SCONF
# Remove-Variable SCRIP

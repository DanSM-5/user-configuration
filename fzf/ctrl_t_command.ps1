#!/usr/bin/env pwsh

$user_conf_path = if ($env:user_conf_path) { $env:user_conf_path } else { "$HOME/.usr_conf" }

$fd_exclude_file = "$user_conf_path/fzf/fd_exclude"
$fd_options_file = "$user_conf_path/fzf/fd_options"

# $fd_exclude = Get-Content $fd_exclude_file
$fd_options = Get-Content $fd_options_file

# Write-Output "Arguments read from fd_exclude_file: $fd_exclude"
# Write-Output "Arguments read from fd_options_file: $fd_options"

& fd $fd_options --ignore-file $fd_exclude_file --color=always @args


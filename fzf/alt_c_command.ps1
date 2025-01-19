#!/usr/bin/env pwsh

$user_conf_path = if ($env:user_conf_path) { $env:user_conf_path } else { "$HOME/.usr_conf" }

$fd_exclude_file = "$user_conf_path/fzf/fd_exclude"
$fd_show_file = "$user_conf_path/fzf/fd_show"

$fd_exclude = Get-Content $fd_exclude_file
$fd_show = Get-Content $fd_show_file

# Write-Output "Arguments read from fd_exclude_file: $fd_exclude"
# Write-Output "Arguments read from fd_show_file: $fd_show"

& fd --type directory $fd_show $fd_exclude --color=always @args


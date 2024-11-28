#!/usr/bin/env pwsh

$fd_exclude_file = "$user_conf_path/fzf/fd_exclude"
$fd_show_file = "$user_conf_path/fzf/fd_show"

$fd_exclude = Get-Content $fd_exclude_file
$fd_show = Get-Content $fd_show_file

# Write-Output "Arguments read from fd_exclude_file: $fd_exclude"
# Write-Output "Arguments read from fd_show_file: $fd_show"

& fd $fd_show $fd_exclude --color=always @args


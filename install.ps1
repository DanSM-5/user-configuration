#!/usr/bin/env pwsh

$env:dirsep = if ($IsWindows) { '\' } else { '/' }
# Set if not already
$env:user_conf_path = if ($env:user_conf_path) { $env:user_conf_path } else { "$HOME${env:dirsep}.usr_conf" }
$config_dir = [System.IO.Path]::GetFileName($env:user_conf_path)
# Do not expand HOME variable
$config_path = "`$HOME${env:dirsep}$config_dir"

$conf_string = @"
################################
#       LOAD USER CONFIG       #
################################

if (Test-Path -Path "$config_path${env:dirsep}load_conf.ps1" -PathType Leaf -ErrorAction SilentlyContinue) {
  . "$config_path${env:dirsep}load_conf.ps1"
}
"@

$conf_string >> $PROFILE

Write-Output "Installation completed!"


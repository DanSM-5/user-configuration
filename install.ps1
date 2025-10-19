#!/usr/bin/env pwsh

$env:dirsep = if ($IsWindows) { '\' } else { '/' }
# Set if not already
$user_conf_path = if ($env:user_conf_path) { $env:user_conf_path } else { "$HOME${env:dirsep}.usr_conf" }
$env:user_conf_path = $user_conf_path
$config_dir = $user_conf_path
$config_dir = if ($config_dir.StartsWith("$HOME")) { $config_dir.Replace("$HOME", '$HOME') } else { $config_dir }
# Do not expand HOME variable
$config_path = "$config_dir${env:dirsep}load_conf.ps1"

$conf_string = @"
################################
#       LOAD USER CONFIG       #
################################

if (Test-Path -Path "$config_path" -PathType Leaf -ErrorAction SilentlyContinue) {
  . "$config_path"
}
"@

$conf_string >> $PROFILE

Write-Output "Installation completed!"


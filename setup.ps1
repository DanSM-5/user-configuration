#!/usr/bin/env pwsh

# This script is intended to be used for first time installation calling other setup scripts
# Download with Invoke-RequestMethod and pipe into Invoke-Expression
# irm -Uri https://raw.githubusercontent.com/DanSM-5/user-configuration/master/setup.ps1 | iex

$SHOME = $HOME.Replace('\', '/')
$dirsep = if ($IsWindows) { '\' } else { '/' }
$env:dirsep = $dirsep

# Config repo + default location
$env:user_conf_path = if ($env:user_conf_path) { $env:user_conf_path } else { "$HOME${env:dirsep}.usr_conf" }
$config_repo = "git@github-personal:DanSM-5/user-configuration"

# Start from HOME
Set-Location $HOME

# Only clone if dir doesn't exist already
if (Test-Path -Path $env:user_conf_path -PathType Container -ErrorAction SilentlyContinue) {
  Write-Output "Config repository already exist. Skipping..."
} else {
  git clone "$config_repo" "$env:user_conf_path"
}

# Change location to config path
Set-Location "$user_conf_path"

$scripts_to_run = @(
  "$env:user_conf_path/install.ps1"
  "$env:user_conf_path/setupenv.ps1"
  # Currently no plugins install script
  # "$env:user_conf_path/install_plugins.ps1"
)

foreach ($script in $scripts_to_run) {
  Write-Output "Executing $script"
  if (!$IsWindows) {
    # Set executable permissions in case they are not downloaded with the repo
    # MacOs and Linux only
    chmod +x "$script"
  }
  # Run script
  & "$script"
}

Write-Output "Setup completed. Please run"
Write-Output ". $user_conf_path/load_conf.sh"
Write-Output "or open a new terminal window to load the configuration"


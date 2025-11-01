#!/usr/bin/env pwsh

# This script is intended to be used for first time installation calling other setup scripts
# Download with Invoke-RequestMethod and pipe into Invoke-Expression
# irm -Uri https://raw.githubusercontent.com/DanSM-5/user-configuration/master/setup.ps1 | iex

# Environment variables
# - user_conf_path: Path for the user-configuration repository
# - SETUP_TERMINAL: Setup terminal configuration Windows Terminal or Kitty
# - USE_SSH_REMOTE: Use ssh key from config
# - SETUP_VIM_CONFIG: Run install script in vim-config

# Platform specific
$dirsep = if ($IsWindows) { '\' } else { '/' }
$env:dirsep = $dirsep
# Config repo + default location
$user_conf_path = if ($env:user_conf_path) { $env:user_conf_path } else { "$HOME${env:dirsep}.usr_conf" }
$env:user_conf_path = $user_conf_path
$env:SETUP_TERMINAL = if ($env:SETUP_TERMINAL) { $env:SETUP_TERMINAL } else { 'true' }
$env:USE_SSH_REMOTE = if ($env:USE_SSH_REMOTE) { $env:USE_SSH_REMOTE } else { 'true' }
$config_repo = if ($env:USE_SSH_REMOTE -eq 'true') { 'git@github-personal:DanSM-5/user-configuration' } else { 'https://github.com/DanSM-5/user-configuration' }
$env:SETUP_VIM_CONFIG = if ($env:SETUP_VIM_CONFIG) { $env:SETUP_VIM_CONFIG } else { 'true' }

if (!(($env:USE_SSH_REMOTE -eq 'true') -and (Get-Command -Name 'ssh' -All -ErrorAction SilentlyContinue))) {
  Write-Error 'SSH config not found. Set USE_SSH_REMOTE=false and run again to continue.'
  exit 1
}

# Start from HOME
Set-Location $HOME

# Only clone if dir doesn't exist already
if (Test-Path -Path $env:user_conf_path -PathType Container -ErrorAction SilentlyContinue) {
  Write-Output "Config repository already exist. Skipping..."
} else {
  git clone "$config_repo" "$env:user_conf_path"
}

# Change location to config path
Set-Location "$env:user_conf_path"

$scripts_to_run = @(
  "$env:user_conf_path${env:dirsep}install.ps1"
  "$env:user_conf_path${env:dirsep}setupenv.ps1"
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
Write-Output ". $env:user_conf_path${env:dirsep}load_conf.sh"
Write-Output "or open a new terminal window to load the configuration"


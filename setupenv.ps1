#!/usr/bin/env pwsh

# Use forward slash '/' in all paths
# for consistency
$SHOME = $HOME.Replace('\', '/')
$mpv_location = "$SHOME/.config/mpv"

try {
  New-Item -Path "$SHOME/.config" -ItemType Directory -ErrorAction SilentlyContinue
} catch {}

# Required repos
$repos = @{
  "$SHOME/user-scripts" = "git@github-personal:DanSM-5/user-scripts";
  "$SHOME/.SpaceVim.d" = "git@github-personal:DanSM-5/space-vim-config";
  "$SHOME/.config/vscode-nvim" = "git@github-personal:DanSM-5/vscode-nvim";
  "$SHOME/omp-theme" = "git@github-personal:DanSM-5/omp-theme";
  "$mpv_location" = "git@github-personal:DanSM-5/mpv-conf";
}

# Repos that should be clonned within $HOME/user-scripts
$user_scripts = @{
  "$SHOME/user-scripts/ff2mpv" = "git@github-personal:DanSM-5/ff2mpv";
}

# Repos that should be clonned within mpv/scripts
$mpv_plugins = @{
  "$mpv_location/scripts/mpv_sponsorblock" = "git@github-personal:DanSM-5/mpv_sponsorblock";
  "$mpv_location/scripts/mpv-gif-generator" = "git@github-personal:DanSM-5/mpv-gif-generator";
  "$mpv_location/scripts/file-browser" = "https://github.com/CogentRedTester/mpv-file-browser";
}

function try_clone ([string] $location, [string] $repo) {

  # Only clone if dir doesn't exist already
  if (Test-Path -Path $location -PathType Container -ErrorAction SilentlyContinue) {
    Write-Output "Repo: $repo already exist in $location"
  } else {
    git clone "$repo" "$location"
  }
}

function process_list ([HashTable] $array) {
  foreach ($location in $array.Keys) {
    $repo = $array[$location]
    try_clone $location $repo
  }
}

process_list $repos
process_list $user_scripts
process_list $mpv_plugins

if ($IsWindows) {
  # Windows mpv reads from AppData/Roaming
  New-Item -ItemType SymbolicLink -Target "$mpv_location" -Path "$SHOME/AppData/Roaming/mpv"
  # Scoop mpv reads from portable_config
  New-Item -ItemType SymbolicLink -Target "$mpv_location" -Path "$SHOME/scoop/persist/mpv/portable_config"
}


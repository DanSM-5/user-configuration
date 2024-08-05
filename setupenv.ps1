#!/usr/bin/env pwsh

# Use forward slash '/' in all paths
# for consistency
$SHOME = $HOME.Replace('\', '/')
$mpv_location = "$SHOME/.config/mpv"
$env:SETUP_TERMINAL = if ($env:SETUP_TERMINAL) { $env:SETUP_TERMINAL } else { 'false' }
$env:USE_SSH_REMOTE = if ($env:USE_SSH_REMOTE) { $env:USE_SSH_REMOTE } else { 'true' }
$env:SETUP_VIM_CONFIG = if ($env:SETUP_VIM_CONFIG) { $env:SETUP_VIM_CONFIG } else { 'true' }
$setup_terminal = $env:SETUP_TERMINAL -eq 'true'
$remote_url = if ($env:USE_SSH_REMOTE -eq 'true') { 'git@github-personal:DanSM-5' } else { 'https://github.com/DanSM-5' }
$setup_vim_config = $env:SETUP_VIM_CONFIG -eq 'true'

try {
  New-Item -Path "$SHOME/.config" -ItemType Directory -ErrorAction SilentlyContinue
} catch {}

# Required repos
$repos = @{
  "$SHOME/user-scripts" = "$remote_url/user-scripts";
  # "$SHOME/.SpaceVim.d" = "$remote_url/space-vim-config";
  "$SHOME/vim-config" = "$remote_url/vim-config";
  "$SHOME/.config/vscode-nvim" = "$remote_url/vscode-nvim";
  "$SHOME/omp-theme" = "$remote_url/omp-theme";
  "$mpv_location" = "$remote_url/mpv-conf";
}

# Repos that should be clonned within $HOME/user-scripts
$user_scripts = @{
  "$SHOME/user-scripts/ff2mpv" = "$remote_url/ff2mpv";
}

# Repos that should be clonned within mpv/scripts
$mpv_plugins = @{
  "$mpv_location/scripts/mpv_sponsorblock" = "$remote_url/mpv_sponsorblock";
  "$mpv_location/scripts/mpv-gif-generator" = "$remote_url/mpv-gif-generator";
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

  # Set Windows Terminal config
  if ($setup_terminal -and (Test-Path -Path "$SHOME/user-scripts/windows-terminal/settings.json" -PathType Leaf -ErrorAction SilentlyContinue)) {
    $terminal_paths = @(
      # MS Store
      "$env:LOCALAPPDATA/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settins.json"
      "$env:LOCALAPPDATA/Packages/Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe/LocalState/settins.json"
      # Binary installer
      "$env:LOCALAPPDATA/Microsoft/Windows Terminal/settings.json"
      "$env:APPDATA/Microsoft/Windows Terminal/settings.json"
    )

    foreach ($tp in $terminal_paths) {
      # Skip if file does not exist
      $settings_location = [System.IO.Path]::GetDirectoryName($tp)
      if (!(Test-Path -Path $settings_location -PathType Leaf -ErrorAction SilentlyContinue)) {
        New-Item $settings_location -ItemType Directory -ErrorAction 0
      }

      if (Test-Path -Path $tp -PathType Leaf -ErrorAction SilentlyContinue) {
        Remove-Item -Path $tp -Force -ErrorAction SilentlyContinue *> $null
      }

      Copy-Item -Path "$HOME/user-scripts/windows-terminal/settings.json" -Destination $tp

      # Check if it is symlink
      # if ((Get-Item $tp).Attributes -Band [IO.FileAttributes]::ReparsePoint) {
      #   continue
      # }
      # New-Item -ItemType SymbolicLink -Target "$HOME/user-scripts/windows-terminal/settings.json" -Path $tp
    }
  }
} else {
  if ($setup_terminal -and $env:KITTY_WINDOW_ID -and (!((Get-Item "$SHOME/.config/kitty").Attributes -Band [IO.FileAttributes]::ReparsePoint))) {
    New-Item -ItemType SymbolicLink -Target "$user_scripts_path/kitty" -Path "$SHOME/.config/kitty"
    Push-Location "$SHOME/.config/kitty"
    git clone 'https://github.com/yurikhan/kitty_grab.git'
    Pop-Location
}

if ($setup_vim_config) {
  Push-Location "$HOME/vim-config" *> $null

  # TODO: Add a ps1 install script in vim-config
  $gitbash = "$(where.exe env | Select-String 'Git\\usr\\bin\\env')"
  # Install the config
  & $gitbash ./install.sh

  # Uncomment below to install plugins from the command line

  # # vim
  # vim -es -u vimrc -i NONE -c "PlugInstall" -c "qa"

  # # neovim
  # nvim -es -u init.vim -i NONE -c "PlugInstall" -c "qa"

  Pop-Location *> $null
}


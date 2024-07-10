#!/usr/bin/env bash

# Detection to handle correct paths per platform
mpv_location=''
windows=false

mkdir -p "$HOME/.config"

if [[ "$(uname)" =~ MSYS.+|MINGW.+|CYGWIN.+|.+NT.+ ]]; then
  windows=true
fi

mpv_location="$HOME/.config/mpv"

# Required repos
declare -A repos=(
  ["$HOME/user-scripts"]="git@github-personal:DanSM-5/user-scripts"
  ["$HOME/.SpaceVim.d"]="git@github-personal:DanSM-5/space-vim-config"
  ["$HOME/.config/vscode-nvim"]="git@github-personal:DanSM-5/vscode-nvim"
  ["$HOME/omp-theme"]="git@github-personal:DanSM-5/omp-theme"
  ["$mpv_location"]="git@github-personal:DanSM-5/mpv-conf"
)

# Repos that should be clonned within $HOME/user-scripts
declare -A user_scripts=(
  ["$HOME/user-scripts/ff2mpv"]="git@github-personal:DanSM-5/ff2mpv"
)

# Repos that should be clonned within mpv/scripts
declare -A mpv_plugins=(
  ["$mpv_location/scripts/mpv_sponsorblock"]="git@github-personal:DanSM-5/mpv_sponsorblock"
  ["$mpv_location/scripts/mpv-gif-generator"]="git@github-personal:DanSM-5/mpv-gif-generator"
  ["$mpv_location/scripts/file-browser"]="https://github.com/CogentRedTester/mpv-file-browser"
)

try_clone () {
  local location="$1"
  local repo="$2"

  # Only clone if dir doesn't exist already
  if ! [ -d "$location" ]; then
    git clone "$repo" "$location"
  else
    printf '%s\n' "Repo: $repo already exist in $location"
  fi
}

process_list () {
  local -n array=$1
  local repo=''

  for location in "${!array[@]}"; do
    repo="${array["$location"]}"
    if [ -n "$location" ] && [ -n "$repo" ]; then
      try_clone "$location" "$repo"
    fi
  done
}

process_list repos
process_list user_scripts
process_list mpv_plugins


if [ "$windows" = true ]; then
  # Windows mpv reads from AppData/Roaming
  ln -s "$mpv_location" "$HOME/AppData/Roaming/mpv"
  # Scoop mpv reads from portable_config
  ln -s "$mpv_location" "$HOME/scoop/persist/mpv/portable_config"
fi

if command -v termux-setup-storage &> /dev/null; then
  export user_conf_path="${user_conf_path:-$HOME/.usr_conf}"
  mkdir -p "$HOME/.termux"
  cp -r "$user_conf_path/.termux"/* "$HOME/.termux"
fi


#!/usr/bin/env bash

# Detection to handle correct paths per platform
mpv_location=''
windows=false
remote_url="https://github.com/DanSM-5"
SETUP_TERMINAL="${SETUP_TERMINAL:-false}"
USE_SSH_REMOTE="${USE_SSH_REMOTE:-true}"
SETUP_VIM_CONFIG="${SETUP_VIM_CONFIG:-true}"

mkdir -p "$HOME/.config"

if [[ "$(uname)" =~ MSYS.+|MINGW.+|CYGWIN.+|.+NT.+ ]]; then
  windows=true
fi

if [ "$USE_SSH_REMOTE" = 'true' ]; then
  remote_url="git@github-personal:DanSM-5"
else
  # Force all submodules to be cloned by https
  git config --global --replace-all url."https://github.com/".insteadOf 'git@github.com:'
  git config --global --add url."https://github.com/".insteadOf 'git@github-personal:'
fi

mpv_location="$HOME/.config/mpv"

# Required repos
declare -A repos=(
  ["$HOME/user-scripts"]="$remote_url/user-scripts"
  # ["$HOME/.SpaceVim.d"]="$remote_url/space-vim-config"
  ["$HOME/vim-config"]="$remote_url/vim-config"
  ["$HOME/.config/vscode-nvim"]="$remote_url/vscode-nvim"
  ["$HOME/omp-theme"]="$remote_url/omp-theme"
  ["$mpv_location"]="$remote_url/mpv-conf"
)

# INFO: external scripts have been changed into submodules
# Repos that should be clonned within $HOME/user-scripts
# declare -A user_scripts=(
#   ["$HOME/user-scripts/ff2mpv"]="$remote_url/ff2mpv"
# )

# INFO: plugins have been changed into submodules
# Repos that should be clonned within mpv/scripts
# declare -A mpv_plugins=(
#   ["$mpv_location/scripts/mpv_sponsorblock"]="$remote_url/mpv_sponsorblock"
#   ["$mpv_location/scripts/mpv-gif-generator"]="$remote_url/mpv-gif-generator"
#   ["$mpv_location/scripts/file-browser"]="https://github.com/CogentRedTester/mpv-file-browser"
# )

try_clone () {
  local location="$1"
  local repo="$2"

  # Only clone if dir doesn't exist already
  if ! [ -d "$location" ]; then
    git clone --recurse-submodules "$repo" "$location"
    git submodule update --init --recurse
  else
    printf '%s\n' "Repo: $repo already exist in $location"
  fi
}

configure_repo () {
  local repo="$1"

  # Set user and email on repo
  git -C "$repo" config user.email dan@config.com
  git -C "$repo" config user.user dan
}

process_list () {
  local -n array=$1
  local repo=''

  for location in "${!array[@]}"; do
    repo="${array["$location"]}"
    if [ -n "$location" ] && [ -n "$repo" ]; then
      try_clone "$location" "$repo"
      configure_repo "$location"
    fi
  done
}

process_list repos
# process_list user_scripts
# process_list mpv_plugins


if [ "$windows" = true ]; then
  # Windows mpv reads from AppData/Roaming
  ln -s "$mpv_location" "$HOME/AppData/Roaming/mpv"
  # Scoop mpv reads from portable_config
  ln -s "$mpv_location" "$HOME/scoop/persist/mpv/portable_config"

  if [ "$SETUP_TERMINAL" = 'true' ] && [ -f "$HOME/user-scripts/windows-terminal/settings.json" ]; then
    terminal_paths=(
      # MS Store
      "$LOCALAPPDATA/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settins.json"
      "$LOCALAPPDATA/Packages/Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe/LocalState/settins.json"
      # Binary installer
      "$LOCALAPPDATA/Microsoft/Windows Terminal/settings.json"
      "$APPDATA/Microsoft/Windows Terminal/settings.json"
    )

    for tp in "${terminal_paths[@]}"; do
      # Skip if file does not exist
      settings_location="${tp%/*}"
      if ! [ -d "$settings_location" ]; then
        mkdir -p "$settings_location"
      fi

      if [ -f "$tp" ]; then
        rm -f "$tp" 2>/dev/null
      fi

      cp "$HOME/user-scripts/windows-terminal/settings.json" "$tp"
    done
  fi
fi

if [ "$SETUP_TERMINAL" = 'true' ] && [[ -v KITTY_WINDOW_ID ]]; then
  if ! [ -L "$HOME/.config/kitty" ]; then
    ln -s "$user_scripts_path/kitty" "$HOME/.config/kitty"
    pushd "$HOME/.config/kitty"
    git clone https://github.com/yurikhan/kitty_grab.git
    popd
  fi
fi

if command -v termux-setup-storage &> /dev/null; then
  export user_conf_path="${user_conf_path:-$HOME/.usr_conf}"
  mkdir -p "$HOME/.termux"
  cp -r "$user_conf_path/.termux"/* "$HOME/.termux"
fi

if [ "$SETUP_VIM_CONFIG" = 'true' ]; then
  pushd "$HOME/vim-config" &> /dev/null

  # Install the config
  ./install.sh

  # Uncomment below to install plugins from the command line

  # # vim
  # vim -es -u vimrc -i NONE -c "PlugInstall" -c "qa"

  # # neovim
  # VimPlug
  # nvim -es -u init.vim -i NONE -c "PlugInstall" -c "qa"
  # hvim +PlugUpdate +sleep1000m +exit
  # Lazy.vim
  nvim --headless "+Lazy! sync" +qa

  popd 2> /dev/null
fi


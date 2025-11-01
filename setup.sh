#!/usr/bin/env bash

# This script is intended to be used for first time installation calling other setup scripts
# Download with curl and pipe into bash
# curl -sSLf https://raw.githubusercontent.com/DanSM-5/user-configuration/master/setup.sh | bash

# Environment variables
# - user_conf_path: Path for the user-configuration repository
# - SETUP_TERMINAL: Setup terminal configuration Windows Terminal or Kitty
# - USE_SSH_REMOTE: Use ssh key from config
# - SETUP_VIM_CONFIG: Run install script in vim-config

# Config repo + default location
export user_conf_path="${user_conf_path:-$HOME/.usr_conf}"
config_repo="https://github.com/DanSM-5/user-configuration"
export SETUP_TERMINAL="${SETUP_TERMINAL:-true}"
export USE_SSH_REMOTE="${USE_SSH_REMOTE:-true}"
export SETUP_VIM_CONFIG="${SETUP_VIM_CONFIG:-true}"


if [ "$USE_SSH_REMOTE" = 'true' ] && command -v 'ssh' &> /dev/null; then
  :
else
  printf '%s\n' 'SSH config not found. Set USE_SSH_REMOTE=false and run again to continue.'
  # export USE_SSH_REMOTE='false'
  exit 1
fi

if [ "$USE_SSH_REMOTE" = 'true' ]; then
  config_repo="git@github-personal:DanSM-5/user-configuration"
fi

# Start from HOME
cd "$HOME" || exit

if [ -d "$user_conf_path" ]; then
  echo "Config repository already exist. Skipping..."
else
  git clone "$config_repo" "$user_conf_path"
fi

# Change location to config path
cd "$user_conf_path" || exit

scripts_to_run=(
  "$user_conf_path/install.sh"
  "$user_conf_path/setupenv.sh"
  "$user_conf_path/install_plugins.sh"
)

for script in "${scripts_to_run[@]}"; do
  echo "Executing $script"
  # Set executable permissions in case they are not downloaded with the repo
  chmod +x "$script"
  # Run script
  "$script"
done

echo "Setup completed. Please run"
echo "exec zsh"
echo "or"
echo ". $user_conf_path/load_conf.sh"
echo "or open a new terminal window to load the configuration"


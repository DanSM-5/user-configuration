#!/usr/bin/env bash

# Enable ssh remote
USE_SSH_REMOTE="${USE_SSH_REMOTE:-true}"
remote_url="https://github.com/DanSM-5"
if [ "$USE_SSH_REMOTE" = 'true' ]; then
  remote_url="git@github-personal:DanSM-5"
fi

# Add more plugins here
repos=(
  https://github.com/zsh-users/zsh-autosuggestions
  # https://github.com/zsh-users/zsh-syntax-highlighting
  "$remote_url/zsh-nvm"
  https://github.com/lincheney/fzf-tab-completion
  # https://github.com/RobSis/zsh-completion-generator.git
  https://github.com/zsh-users/zsh-completions.git
  https://github.com/scop/bash-completion
  https://github.com/zdharma-continuum/fast-syntax-highlighting
)

# Get script location
# SOURCE=${BASH_SOURCE[0]}
# while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
#   DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
#   SOURCE=$(readlink "$SOURCE")
#   [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
# done
# DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )

export user_conf_path="${user_conf_path:-"$HOME/.usr_conf"}"
user_config_cache="$HOME/.cache/.user_config_cache"
export user_config_cache
plugins="$user_config_cache/plugins"
completions="$user_config_cache/completions"
zsh="$completions/zsh"
bash="$completions/bash"

mkdir -p "$plugins"
mkdir -p "$completions"
mkdir -p "$zsh"
mkdir -p "$bash"

pushd "$plugins" || exit
for repo in "${repos[@]}"; do
  dir="${repo##*/}"
  dir_location="$plugins/${dir%.*}"
  if ! [ -d "$dir_location" ]; then
    git clone --depth=1 "$repo"
  fi
done
popd || exit

# Copy completions
command cp -fr "$user_conf_path/completions" "$user_config_cache"

# Git completion for zsh in gitbash
if [ -f /mingw64/share/git/completion/git-completion.zsh ]; then
  command cp /mingw64/share/git/completion/git-completion.zsh "$zsh/_git"
fi

if command -v zsh &>/dev/null && [[ -v user_conf_path ]]; then
  "$user_conf_path"/compile_plugins.zsh
fi


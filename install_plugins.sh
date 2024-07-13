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

cache_dir="$HOME/.cache/.user_config_cache"
plugins="$cache_dir/plugins"
completions="$cache_dir/completions"
zsh="$completions/zsh"
bash="$completions/bash"

mkdir -p "$plugins"
mkdir -p "$completions"
mkdir -p "$zsh"
mkdir -p "$bash"

pushd "$plugins"
for repo in "${repos[@]}"; do
  dir="${repo##*/}"
  dir_location="$plugins/${dir%.*}"
  if ! [ -d "$dir_location" ]; then
    git clone "$repo"
  fi
done
popd

# Copy completions
command cp -fr "$HOME/.usr_conf/completions" "$cache_dir"

# Git completion for zsh in gitbash
if [ -f /mingw64/share/git/completion/git-completion.zsh ]; then
  command cp /mingw64/share/git/completion/git-completion.zsh "$zsh/_git"
fi


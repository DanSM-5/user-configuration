#!/usr/bin/env bash

# Add more plugins here
repos=(
  https://github.com/zsh-users/zsh-autosuggestions
  https://github.com/zsh-users/zsh-syntax-highlighting
  ssh://github-personal/DanSM-5/zsh-nvm
  https://github.com/lincheney/fzf-tab-completion
  # https://github.com/RobSis/zsh-completion-generator.git
  https://github.com/zsh-users/zsh-completions.git
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

mkdir -p "$plugins"
mkdir -p "$completions"

pushd "$plugins"
for repo in "${repos[@]}"; do
  dir="${repo##*/}"
  dir_location="$plugins/${dir%.*}"
  if ! [ -d "$dir_location" ]; then
    git clone "$repo"
  fi
done
popd

if [ -f /mingw64/share/git/completion/git-completion.zsh ] && [ ! -f "$plugins/_git"  ]; then
  \cp /mingw64/share/git/completion/git-completion.zsh "$completions/_git"
fi

cp "$HOME/.usr_conf"/zsh/* "$completions"


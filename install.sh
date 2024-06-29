#!/usr/bin/env bash

# Set if not already
user_conf_path="${user_conf_path:-$HOME/.usr_conf}"
config_dir="${user_conf_path##*/}"
# Do not expand HOME variable
config_path="\$HOME/$config_dir"

backup () {
  local file="$1"
  mv "$file" "$file.old"
  echo "Creating backup of $file. Backup: $file.old"
}

install () {
  local bashrc="$HOME/.bashrc"
  local zshrc="$HOME/.zshrc"
  local dotfiles="$HOME/.dotfilesrc"

  [ -f "$bashrc" ] && backup "$bashrc"
  [ -f "$zshrc" ] && backup "$zshrc"

  touch "$dotfiles"

  # Using .dotfilesrc for both .zshrc and .bashrc
printf "
################################
#       LOAD USER CONFIG       #
################################

[ -f \"$config_path/load_conf.sh\" ] && \. \"$config_path/load_conf.sh\"
" >> "$HOME/.dotfilesrc"

  ln -s "$dotfiles" "$bashrc"
  ln -s "$dotfiles" "$zshrc"
}

install

echo "Installation completed!"


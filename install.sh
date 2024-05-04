#!/usr/bin/env bash

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

[ -f \"\$HOME/.usr_conf/load_conf.sh\" ] && \. \"\$HOME/.usr_conf/load_conf.sh\"
" >> "$HOME/.dotfilesrc"

  ln -s "$dotfiles" "$bashrc"
  ln -s "$dotfiles" "$zshrc"
}

install

echo "Installation completed!"


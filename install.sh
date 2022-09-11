#!/usr/bin/env bash

shell_name=$1

backup () {
  local file="$1"
  mv "$file" "$file.old"
  echo "Creating backup of $file. Backup: $file.old"
}

set_destination_bash () {
  if test -f "$HOME/.profile"; then
    destination="$HOME/.profile"
    backup "$destination"
  elif test -f "$HOME/.bashrc"; then
    destination="$HOME/.bashrc"
    backup "$destination"
  elif test -f "$HOME/.bash_profile"; then
    destination="$HOME/.bash_profile"
    backup "$destination"
  else
    echo "No file found to add configuration for bash"
    # echo "Creating ~/.profile..."
    # touch "$HOME/.profile"
    destination="$HOME/.profile"
  fi
}

set_destination_zsh () {
  if test -f "$HOME/.zshrc"; then
    destination="$HOME/.zshrc"
    backup "$destination"
  else
    echo "No file ~/.zshrc found"
    destination="$HOME/.zshrc"
  fi
}

install () {
  \mkdir -p "$HOME/prj"
printf "
# Source Configuration
test -f \"$HOME/.usr_conf/load_conf.sh\" && \. \"$HOME/.usr_conf/load_conf.sh\"
" >> "$HOME/.dotfilesrc"

  ln -s "$HOME/.dotfilesrc" $destination
}

request () {
  echo >&2 "Plese enter your prefer shell (bash, zsh)."
  printf "shell: " && read -r shell_name
  case $shell_name in
    bash) set_destination_bash;;
    zsh) set_destination_zsh;;
    *) request "$@";;
  esac
}

case $shell_name in
  bash) set_destination_bash;;
  zsh) set_destination_zsh;;
  *) request "$@";;
esac

install
echo "Complete!!!"

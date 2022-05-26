#!/usr/bin/env bash

shell_name=$1

set_destination_bash () {
  if test -f "$HOME/.profile"; then
    destination="$HOME/.profile"
  elif test -f "$HOME/.bashrc"; then
    destination="$HOME/.bashrc"
  elif test -f "$HOME/.bash_profile"; then
    destination="$HOME/.bash_profile"
  else
    echo "No file found to add configuration for bash"
    echo "Creating ~/.profile..."
    touch "$HOME/.profile"
    destination="$HOME/.profile"
  fi
}

set_destination_zsh () {
  if test -f "$HOME/.zshrc"; then
    destination="$HOME/.zshrc"
  else
    echo "No file ~/.zshrc found"
    echo "Creating ~/.zshrc..."
    touch "$HOME/.zshrc"
    destination="$HOME/.zshrc"
  fi
}

install () {
  \mkdir -p "$HOME/prj"
printf "
# Source Configuration
test -f \"$HOME/.usr_conf/load_conf.sh\" && \. \"$HOME/.usr_conf/load_conf.sh\"
" >> $destination
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

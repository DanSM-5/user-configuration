#!/usr/bin/env bash

install_dep () {
  comm=$1
  if command -v "$comm" &> /dev/null; then
    echo "Utility $comm is alredy installed" 
  else
    sudo apt-get install "$comm" -y
  fi
}

install_utility () {
  sudo apt-get install $1
}

echo "Installing apt dependencies..."

sudo apt-get update && \
  sudo apt-get upgrade -y && \
  sudo apt-get install -y $(cat app_list_apt)

echo "Done"

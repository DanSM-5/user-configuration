#!/usr/bin/env bash

echo "> installing homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo "> loading homebrew..."
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

echo "Installing brew apps..."
brew install $(cat app_list_brew)
echo "Done"


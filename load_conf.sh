#!/usr/bin/env bash

# Identify commands existance
command_exists () {
	command -v "$1" &> /dev/null
}

# Default values for device detection
export IS_WSL=false
export IS_TERMUX=false
export IS_LINUX=false
export IS_MAC=false
export IS_GITBASH=false

# Detect if running WSL
if command_exists /mnt/c/Windows/System32/cmd.exe; then
  export IS_WSL=true 
elif command_exists termux-setup-storage; then
  export IS_TERMUX=true
elif command_exists /c/Windows/System32/cmd.exe; then
  export IS_GITBASH=true
fi

# Detect System
case "$(uname)" in
  Linux*) export IS_LINUX=true;;
  Darwin*) export IS_MAC=true;;
esac

# Source User Scripts
test -f "$HOME/.usr_conf/.uconfgrc" && \. "$HOME/.usr_conf/.uconfgrc"
test -f "$HOME/.usr_conf/.ualiasgrc" && \. "$HOME/.usr_conf/.ualiasgrc"
test -f "$HOME/.usr_conf/.uconfrc" && \. "$HOME/.usr_conf/.uconfrc"
test -f "$HOME/.usr_conf/.ualiasrc" && \. "$HOME/.usr_conf/.ualiasrc"
  

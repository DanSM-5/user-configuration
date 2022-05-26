#!/usr/bin/env bash

# Detect if running WSL
# if command -v /mnt/c/Windows/System32/cmd.exe &> /dev/null; then
#   export IS_WSL=true 
# fi

# Source User Scripts
test -f "$HOME/.usr_conf/.uconfgrc" && \. "$HOME/.usr_conf/.uconfgrc"
test -f "$HOME/.usr_conf/.ualiasgrc" && \. "$HOME/.usr_conf/.ualiasgrc"
test -f "$HOME/.usr_conf/.uconfrc" && \. "$HOME/.usr_conf/.uconfrc"
test -f "$HOME/.usr_conf/.ualiasrc" && \. "$HOME/.usr_conf/.ualiasrc"
  

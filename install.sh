#!/usr/bin/env bash

# Default destination
destination="$HOME/.profile"

if test -f "$HOME/.profile"; then
  destination="$HOME/.profile"
elif test -f "$HOME/.bashrc"; then
  destination="$HOME/.bashrc"
elif test -f "$HOME/.bash_profile"; then
  destination="$HOME/.bash_profile"
fi

printf "
# Source User Scripts
test -f \"$HOME/.usr_conf/.uconfrc\" && . \"$HOME/.usr_conf/.uconfrc\"
test -f \"$HOME/.usr_conf/.uconfgrc\" && . \"$HOME/.usr_conf/.uconfgrc\"
test -f \"$HOME/.usr_conf/.ualiasrc\" && . \"$HOME/.usr_conf/.ualiasrc\"
test -f \"$HOME/.usr_conf/.ualiasgrc\" && . \"$HOME/.usr_conf/.ualiasgrc\"
" >> $destination

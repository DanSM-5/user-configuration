#!/usr/bin/env bash

export user_conf_path="${user_conf_path:-"$HOME/.usr_conf"}"
export user_scripts_path="${user_scripts_path:-"$HOME/user-scripts"}"
export prj="${prj:-"$HOME/prj"}"
export user_config_cache="${user_config_cache:-"$HOME/.cache/.user_config_cache"}"

if [ -n "$ZSH_VERSION" ]; then
  export IS_ZSH=true
  export IS_BASH=false
  export SHELL_NAME=zsh
  # source "$user_conf_path/.zsh_conf"
elif [ -n "$BASH_VERSION" ]; then
  export IS_ZSH=false
  export IS_BASH=true
  export SHELL_NAME=bash
  # source "$user_conf_path/.bash_conf"
else
  echo "[WARNING]: NO VALID CONFIGURATION DETECTED!"
  export IS_ZSH=false
  export IS_BAHS=false
  export SHELL_NAME=unknown
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
# [ -s "$brew_nvm/etc/bash_completion.d/nvm" ] && \. "$brew_nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion from brew


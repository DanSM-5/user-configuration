#!/usr/bin/env bash

# Identify commands existance
command_exists () {
	command -v "$1" 2>&1 >/dev/null
}

# Default values for device detection
export IS_WSL=false
export IS_WSL1=false
export IS_WSL2=false
export IS_TERMUX=false
export IS_LINUX=false
export IS_MAC=false
export IS_WINDOWS=false # PLATFORM IS WINDOWS
export IS_GITBASH=false
export IS_WINSHELL=false # PWSH, GITBASH or CMD
export IS_CMD=false
export IS_ZSH=false # Will change in global config
export IS_BAHS=false # Will change in global config
export IS_POWERSHELL=false
export IS_NIXONDROID="${IS_NIXONDROID:-false}" # Can only be true if set from home-manager
export IS_FROM_CONTAINER="${IS_FROM_CONTAINER:-false}" # Can only be true if running inside a container

# Other posible case
# case "$(bat /proc/version 2> /dev/null)" in
#   *WSL2*)
#     echo 'yes'
#     ;;
#   [mM]icrosoft)
#     echo 'WSL'
#     ;;
# esac

# Detect if running WSL
# NOTE: No &> redirection in sh
# if [ -f /mnt/c/Windows/System32/cmd.exe ]; then
if cat /proc/version 2>&1 | grep '[Mm]icrosoft' 2>&1 >/dev/null; then
  export IS_WINDOWS=true
  export IS_WSL=true
  export IS_LINUX=true

  case "$(uname -a)" in
    *WSL2*)
      export IS_WSL2=true
      ;;
    *)
      export IS_WSL1=true
      ;;
  esac

  # if [[ $(uname -a) =~ "WSL2" ]]; then
  #   export IS_WSL2=true
  # else
  #   export IS_WSL1=true
  # fi

elif command_exists termux-setup-storage; then
  export IS_TERMUX=true
  export IS_LINUX=true
elif [ -f /c/Windows/System32/cmd.exe ]; then
  export IS_WINDOWS=true
  export IS_GITBASH=true
  export IS_WINSHELL=true
else
  # Detect System
  case "$(uname)" in
    Linux*) export IS_LINUX=true;;
    Darwin*) export IS_MAC=true;;
  esac
fi

# If loading from vscode config, we only care about the environment variables above
if [ "$VSCODE_NVIM" = true ]; then
  return 0
fi

if [ "$VSCODE_DEBUG" = true ]; then
  source "$HOME/.usr_conf/utils/vscode_debug_conf.sh"
  return 0
fi

# Handle Find it faster vscode extension
if [ "$FIND_IT_FASTER_ACTIVE" = 1 ]; then
  printf "No need to source from here"
  return 0
fi

# Store the path as it comes before modifying it
export userconf_initial_path="${userconf_initial_path:-"$PATH"}"
export PATH="${userconf_initial_path:-"$PATH"}"

# Source User Scripts
test -f "$HOME/.usr_conf/.uconfgrc" && \. "$HOME/.usr_conf/.uconfgrc" || true
test -f "$HOME/.usr_conf/.ualiasgrc" && \. "$HOME/.usr_conf/.ualiasgrc" || true
test -f "$HOME/.usr_conf/.uconfrc" && \. "$HOME/.usr_conf/.uconfrc" || true
test -f "$HOME/.usr_conf/.ualiasrc" && \. "$HOME/.usr_conf/.ualiasrc" || true


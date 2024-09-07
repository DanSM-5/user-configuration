#!/usr/bin/env zsh

# Enable debug
[[ -v debug ]] && set -x

# Logic taken from
# https://github.com/romkatv/zsh-bench/blob/master/configs/diy%2B%2B/skel/.zshrc

# Compile to workcode plugins for faster startup time
# NOTE: for debugging you'll need to use an uncompile version of the plugin

user_config_cache="${user_config_cache:-$HOME/.cache/.user_config_cache}"
plugins="$user_config_cache/plugins"
function zcompile-many() {
  local f
  for f; do zcompile -R -- "$f".zwc "$f"; done
}

# "$plugins/fast-syntax-highlighting"
# "$plugins/fzf-tab-completion"
# "$plugins/zsh-autosuggestions"
# "$plugins/zsh-completions"
# "$plugins/zsh-nvm"
# "$plugins/zsh-syntax-highlighting"

# Autosuggestions
zcompile-many "$plugins"/zsh-autosuggestions/{zsh-autosuggestions.zsh,src/**/*.zsh}

# Syntax highlighting
# zcompile-many "$plugins"/zsh-syntax-highlighting/{zsh-syntax-highlighting.zsh,highlighters/*/*.zsh}
zcompile-many "$plugins"/fast-syntax-highlighting/**/*.zsh

# completions
zcompile-many "$plugins"/zsh-completions/**/*.zsh

# fzf completions
zcompile-many "$plugins"/fzf-tab-completion/zsh/fzf-zsh-completion.sh

# nvm
zcompile-many "$plugins"/zsh-nvm/**/*.zsh


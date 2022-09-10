#!/usr/bin/env bash
# GIT heart FZF
# -------------

# Ref: https://gist.github.com/junegunn/8b572b8d4b5eddd8b85e5f4d40f17236

is_in_git_repo() {
  git rev-parse HEAD > /dev/null 2>&1
}

fzf-down() {
  fzf --height 50% --min-height 20 --border --bind ctrl-/:toggle-preview "$@"
}

fgf() {
  is_in_git_repo || return
  local INITIAL_QUERY="${*:-}"
  git -c color.status=always status --short |
  fzf-down -m --ansi --nth 2..,.. \
    --query "$INITIAL_QUERY" \
    --preview 'if [ -f {-1} ]; then git diff --color=always -- {-1} | sed 1,4d | bat -p --color=always; bat --color=always {-1}; else ls -aF --color=always {-1}; fi' |
  cut -c4- | sed 's/.* -> //'
  # --preview '(git diff --color=always -- {-1} | sed 1,4d | bat -p --color=always; cat {-1})' |
}

fgb() {
  is_in_git_repo || return
  local INITIAL_QUERY="${*:-}"
  git branch -a --color=always | grep -v '/HEAD\s' | sort |
  fzf-down --ansi --multi --tac --preview-window right:70% \
    --query "$INITIAL_QUERY" \
    --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1)' |
  sed 's/^..//' | cut -d' ' -f1 |
  sed 's#^remotes/##'
}

fgt() {
  is_in_git_repo || return
  local INITIAL_QUERY="${*:-}"
  git tag --sort -version:refname |
  fzf-down --multi --preview-window right:70% \
    --query "$INITIAL_QUERY" \
    --preview 'git show --color=always {} | bat --color=always'
    # --preview 'git show --color=always {}'
}

fgh() {
  is_in_git_repo || return
  local INITIAL_QUERY="${*:-}"
  git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=always |
  fzf-down --ansi --no-sort --reverse --multi --bind 'ctrl-s:toggle-sort' \
    --query "$INITIAL_QUERY" \
    --header 'Press CTRL-S to toggle sort' \
    --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | xargs git show --color=always | bat -p --color=always' |
  grep -o "[a-f0-9]\{7,\}"
  # --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | xargs git show --color=always' |
}

fgha() {
  is_in_git_repo || return
  local INITIAL_QUERY="${*:-}"
  git log --all --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=always |
  fzf-down --ansi --no-sort --reverse --multi --bind 'ctrl-s:toggle-sort' \
    --query "$INITIAL_QUERY" \
    --header 'Press CTRL-S to toggle sort' \
    --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | xargs git show --color=always | bat -p --color=always' |
  grep -o "[a-f0-9]\{7,\}"
}

fgr() {
  is_in_git_repo || return
  local INITIAL_QUERY="${*:-}"
  git remote -v | awk '{print $1 "\t" $2}' | uniq |
  fzf-down --tac \
    --query "$INITIAL_QUERY" \
    --preview 'git log --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" {1}' |
  cut -d$'\t' -f1
}

fgs() {
  is_in_git_repo || return
  local INITIAL_QUERY="${*:-}"
  git stash list | fzf-down --reverse -d: --preview 'git show --color=always {1} | bat -p --color=always' \
    --query "$INITIAL_QUERY" |
  cut -d: -f1
  # git stash list | fzf-down --reverse -d: --preview 'git show --color=always {1}' |
}

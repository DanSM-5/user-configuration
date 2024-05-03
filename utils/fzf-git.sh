#!/usr/bin/env bash
# GIT heart FZF
# -------------

# Ref: https://gist.github.com/junegunn/8b572b8d4b5eddd8b85e5f4d40f17236

is_in_git_repo() {
  git rev-parse HEAD > /dev/null 2>&1
}

fzf-down() {
  fzf --height 50% \
    --min-height 20 \
    --bind "ctrl-/:change-preview-window(down|hidden|),alt-up:preview-page-up,alt-down:preview-page-down,ctrl-s:toggle-sort" \
    --border "$@"
}

if [ -n "$__git_pager__" ]; then
  __page_command__=" | $__git_pager__"
else
  __page_command__=""
fi

fgf () {
  is_in_git_repo || return
  local INITIAL_QUERY="${*:-}"
  git -c color.status=always status --short |
  fzf-down -m --ansi --nth 2..,.. \
    --query "$INITIAL_QUERY" \
    --preview 'if [ -f {-1} ]; then
        git diff --color=always -- {-1}'"$__page_command__"' |
          sed 1,4d |
          bat -p --color=always
        printf "\n"
        bat --color=always --style="numbers,header,changes" {-1}
      else
        if command -v erd &>/dev/null; then
          erd --layout inverted --color force --level 3 -I --suppress-size -- {-1}
        else ls -AF --color=always {-1}; fi
      fi' |
  cut -c4- | sed 's/.* -> //'
  # --preview '(git diff --color=always -- {-1} | sed 1,4d | bat -p --color=always; cat {-1})' |
}

fgb () {
  is_in_git_repo || return
  local INITIAL_QUERY="${*:-}"
  git branch -a --color=always | grep -v '/HEAD\s' | sort |
  fzf-down --ansi --multi --tac \
    --preview-window right:70% \
    --query "$INITIAL_QUERY" \
    --preview '
      git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1)' |
  sed 's/^..//' | cut -d' ' -f1 |
  sed 's#^remotes/##'
}

fgt () {
  is_in_git_repo || return
  local INITIAL_QUERY="${*:-}"
  git tag --sort -version:refname |
  fzf-down --multi --preview-window right:70% \
    --query "$INITIAL_QUERY" \
    --preview '
      git show --color=always {}'"$__page_command__"' |
      bat --color=always'
    # --preview 'git show --color=always {}'
}

fgh () {
  is_in_git_repo || return
  local INITIAL_QUERY="${*:-}"
  git log --date=short \
    --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" \
    --graph --color=always |
  fzf-down --ansi --no-sort --reverse --multi \
    --query "$INITIAL_QUERY" \
    --header 'Press CTRL-S to toggle sort' \
    --preview '
      grep -o "[a-f0-9]\{7,\}" <<< {} |
        xargs git show --color=always'"$__page_command__"' |
        bat -p --color=always' |
  grep -o "[a-f0-9]\{7,\}"
  # --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | xargs git show --color=always' |
}

fgha () {
  is_in_git_repo || return
  local INITIAL_QUERY="${*:-}"
  git log --all --date=short \
    --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" \
    --graph --color=always |
  fzf-down --ansi --no-sort --reverse --multi \
    --query "$INITIAL_QUERY" \
    --header 'Press CTRL-S to toggle sort' \
    --preview '
      grep -o "[a-f0-9]\{7,\}" <<< {} |
        xargs git show --color=always'"$__page_command__"' |
        bat -p --color=always' |
  grep -o "[a-f0-9]\{7,\}"
}

fgr () {
  is_in_git_repo || return
  local INITIAL_QUERY="${*:-}"
  git remote -v | awk '{print $1 "\t" $2}' | uniq |
  fzf-down --tac \
    --query "$INITIAL_QUERY" \
    --preview '
      git log --color=always --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" {1}' |
  cut -d$'\t' -f1
}

fgs () {
  is_in_git_repo || return
  local INITIAL_QUERY="${*:-}"
  git stash list |
    fzf-down --reverse -d: \
      --preview '
        git show --color=always {1}'"$__page_command__"' |
          bat -p --color=always' \
    --query "$INITIAL_QUERY" |
  cut -d: -f1
  # git stash list | fzf-down --reverse -d: --preview 'git show --color=always {1}' |
}

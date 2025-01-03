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
    --info=inline \
    --cycle \
    --layout=reverse \
    --multi \
    --bind 'alt-f:first' \
    --bind 'alt-l:last' \
    --bind 'alt-c:clear-query' \
    --bind 'ctrl-a:select-all' \
    --bind 'ctrl-d:deselect-all' \
    --bind 'ctrl-/:change-preview-window(down|hidden|)' \
    --bind 'ctrl-^:toggle-preview' \
    --bind 'alt-up:preview-page-up' \
    --bind 'alt-down:preview-page-down' \
    --bind 'ctrl-s:toggle-sort' \
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
  local path_preview_script="$user_conf_path/utils/fzf-preview.sh"
  git -c color.status=always status --short |
  fzf-down --ansi --nth 2..,.. \
    --query "$INITIAL_QUERY" \
    "--history=$FZF_HIST_DIR/fzf-git_file" \
    --preview-window '60%' \
    --preview "selected=\$(printf '%s' {2..} | sed 's/^\"//' | sed 's/\"$//') ;
      if [ -f \"\$selected\" ]; then
        git diff --color=always -- \"\$selected\"""$__page_command__"' |
          sed 1,4d |
          bat -p --color=always
        printf "\n" ;
      fi
      '"$path_preview_script"' "$selected"' |
  cut -c4- | sed 's/.* -> //'
  # --preview '(git diff --color=always -- {-1} | sed 1,4d | bat -p --color=always; cat {-1})' |
}

fgb () {
  is_in_git_repo || return
  local INITIAL_QUERY="${*:-}"
  git branch -a --color=always | grep -v '/HEAD\s' | sort |
  fzf-down --ansi --tac \
    --preview-window right:70% \
    --query "$INITIAL_QUERY" \
    "--history=$FZF_HIST_DIR/fzf-git_branch" \
    --preview '
      git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1)' |
  sed 's/^..//' | cut -d' ' -f1 |
  sed 's#^remotes/##'
}

fgt () {
  is_in_git_repo || return
  local INITIAL_QUERY="${*:-}"
  git tag --sort -version:refname |
  fzf-down --preview-window right:70% \
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
  fzf-down --ansi --no-sort --reverse \
    --query "$INITIAL_QUERY" \
    "--history=$FZF_HIST_DIR/fzf-git_hash" \
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
  fzf-down --ansi --no-sort --reverse \
    --query "$INITIAL_QUERY" \
    "--history=$FZF_HIST_DIR/fzf-git_hash-all" \
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
    "--history=$FZF_HIST_DIR/fzf-git_remote" \
    --preview '
      git log --color=always --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" {1}' |
  cut -d$'\t' -f1
}

fgs () {
  is_in_git_repo || return
  local INITIAL_QUERY="${*:-}"
  git stash list |
    fzf-down --reverse -d: \
      "--history=$FZF_HIST_DIR/fzf-git_stash" \
      --preview '
        git show --color=always {1}'"$__page_command__"' |
          bat -p --color=always' \
    --query "$INITIAL_QUERY" |
  cut -d: -f1
  # git stash list | fzf-down --reverse -d: --preview 'git show --color=always {1}' |
}


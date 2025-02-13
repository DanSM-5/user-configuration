#!/usr/bin/env bash
# GIT heart FZF
# -------------

# Ref: https://gist.github.com/junegunn/8b572b8d4b5eddd8b85e5f4d40f17236

is_in_git_repo () {
  git rev-parse HEAD > /dev/null 2>&1
}

fzf-down () {
  fzf --height 80% \
    --min-height 20 \
    --input-border \
    --cycle \
    --layout=reverse \
    --multi \
    --preview-window 'right,50%,wrap' \
    --bind 'alt-f:first' \
    --bind 'alt-l:last' \
    --bind 'alt-c:clear-query' \
    --bind 'alt-a:select-all' \
    --bind 'alt-d:deselect-all' \
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
  local path_preview_script="${user_conf_path:-"$HOME/.usr_conf"}/utils/fzf-preview.sh"
  git -c color.status=always status --short |
  fzf-down --ansi --nth 2..,.. \
    --query "$INITIAL_QUERY" \
    "--history=$FZF_HIST_DIR/fzf-git_file" \
    --preview-window '60%,wrap' \
    --prompt 'Files> ' \
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
    --preview-window 'right,70%,wrap' \
    --prompt 'Branches> ' \
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
  fzf-down --preview-window 'right,70%,wrap' \
    --prompt 'Tags> ' \
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
    --prompt 'Hashes> ' \
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
    --prompt 'All Hashes> ' \
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
    --prompt 'Remotes> ' \
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
      --prompt 'Stashes> ' \
      "--history=$FZF_HIST_DIR/fzf-git_stash" \
      --preview '
        git show --color=always {1}'"$__page_command__"' |
          bat -p --color=always' \
    --query "$INITIAL_QUERY" |
  cut -d: -f1
  # git stash list | fzf-down --reverse -d: --preview 'git show --color=always {1}' |
}

# fshow - git commit browser (enter for show, ctrl-d for diff, ` toggles sort)
fshow () {
  git rev-parse HEAD > /dev/null 2>&1 || return

  local def_pager="less -R"
  local pager=""
  if [ -n "$__git_pager__" ]; then
    # if set pager is delta
    pager="$__git_pager__ --paging=always"
    preview_pager='| delta'
  else
    pager="$def_pager"
    preview_pager=''
  fi
  local out shas sha q k
  local preview="
    grep -o \"[a-f0-9]\{7,\}\" <<< {} |
      LS_COLORS= xargs git show --color=always $preview_pager |
        bat -p --color=always
  "

  git_base_cmd="git log --graph --color=always --format='%C(auto)%h%d %s %C(black)%C(bold)%cr'"
  git_current_cmd="$git_base_cmd $*"
  git_all_cmd="$git_base_cmd --all $*"

  # Find clipboard utility
  local copy='true'
  # NOTE: Will probably will never run on windows but
  # better safe than sorry
  if [ "$OS" = 'Windows_NT' ]; then
    # Gitbash
    copy="awk '{ print \$2 }' '{+f}' | pbcopy.exe"
  elif [ "$OSTYPE" = 'darwin' ] || command -v 'pbcopy' &>/dev/null; then
    copy="awk '{ print \$2 }' {+f} | pbcopy"
  # Assume linux if above didn't match
  elif [ -n "$WAYLAND_DISPLAY" ] && command -v 'wl-copy' &>/dev/null; then
    copy="awk '{ print \$2 }' {+f} | wl-copy --foreground --type text/plain"
  elif [ -n "$DISPLAY" ] && command -v 'xsel' &>/dev/null; then
    copy="awk '{ print \$2 }' {+f} | xsel -i -b"
  elif [ -n "$DISPLAY" ] && command -v 'xclip' &>/dev/null; then
    copy="awk '{ print \$2 }' {+f} | xclip -i -selection clipboard"
  fi

  while out=$(
      fzf-down --ansi --no-sort --reverse --query="$q" \
          --preview "$preview" \
	  --preview-window 'right,50%,wrap' \
          --bind "start:reload:$git_current_cmd" \
          --bind "ctrl-f:reload:$git_current_cmd" \
          --bind "ctrl-a:reload:$git_all_cmd" \
          --bind "ctrl-y:execute-silent($copy)+bell" \
          --header 'ctrl-d: Diff | ctrl-a: All | ctrl-f: HEAD | ctrl-y: Copy' \
          --prompt 'Commits> ' \
          "--history=$FZF_HIST_DIR/fzf-git_show" \
          --print-query --expect=ctrl-d \
      ); do
    q=$(head -1 <<< "$out")
    k=$(head -2 <<< "$out" | tail -1)
    # shas=($(sed '1,2d;s/^[^a-z0-9]*//;/^$/d' <<< "$out" | awk '{print $1}'))

    shas=()
    while IFS='' read -r new_sha; do
      shas+=("$new_sha")
    done < <(sed '1,2d;s/^[^a-z0-9]*//;/^$/d' <<< "$out" | awk '{print $1}')

    # shellcheck disable=SC2128
    [ -z "$shas" ] && continue
    if [ "$k" = ctrl-d ]; then
      bash -c "git diff --color=always ${shas[*]} | $pager"
    else
      for sha in "${shas[@]}"; do
        bash -c "git show --color=always $sha | $pager"
      done
    fi
  done
}


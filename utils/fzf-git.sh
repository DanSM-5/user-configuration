#!/usr/bin/env bash
# GIT heart FZF
# -------------

# shellcheck disable=SC2039
[[ $0 == - ]] && return

# Ref: https://gist.github.com/junegunn/8b572b8d4b5eddd8b85e5f4d40f17236

# Fallback trick: Bash uses BASH_SOURCE, Zsh uses %x expansion
SCRIPT_PATH="${BASH_SOURCE[0]:-${(%):-%x}}"
# SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_PATH" )" && pwd )"

__fzfgit-parse-env () {
  local input="${1:-}"
  local character next_character current='' quote=''
  local -i index=0 length=${#input}
  local started=0
  __fzfgit_parsed_args=()

  while (( index < length )); do
    character="${input:$index:1}"

    if [[ -n $quote ]]; then
      if [[ $character == "$quote" ]]; then
        quote=''
        started=1
      elif [[ $quote == '"' && $character == \\ ]]; then
        if (( index + 1 < length )); then
          next_character="${input:$((index + 1)):1}"
          case "$next_character" in
            [[:space:]]|"'"|'"'|\\)
              current+="$next_character"
              (( index++ ))
              ;;
            *) current+="$character" ;;
          esac
        else
          current+="$character"
        fi
        started=1
      else
        current+="$character"
        started=1
      fi
    else
      case "$character" in
        "'"|'"')
          quote="$character"
          started=1
          ;;
        \\)
          if (( index + 1 < length )); then
            next_character="${input:$((index + 1)):1}"
            case "$next_character" in
              [[:space:]]|"'"|'"'|\\)
                current+="$next_character"
                (( index++ ))
                ;;
              *) current+="$character" ;;
            esac
          else
            current+="$character"
          fi
          started=1
          ;;
        [[:space:]])
          if (( started )); then
            __fzfgit_parsed_args+=("$current")
            current=''
            started=0
          fi
          ;;
        *)
          current+="$character"
          started=1
          ;;
      esac
    fi

    (( index++ ))
  done

  if [[ -n $quote ]]; then
    printf 'fzf-git: unmatched %s quote in Git option environment variable\n' "$quote" >&2
    return 2
  fi

  if (( started )); then
    __fzfgit_parsed_args+=("$current")
  fi
}

__fzfgit-shell-join () {
  local argument
  for argument in "$@"; do
    printf ' %q' "$argument"
  done
}

__git-refs () {
  __fzfgit-parse-env "${FZFGIT_GIT_FOR_EACH_REF:-}" || return
  local -a git_for_each_ref_args=("${__fzfgit_parsed_args[@]}")

  git for-each-ref \
    --sort=-creatordate --sort=-HEAD --color=always \
    --format='%(if:equals=refs/remotes)%(refname:rstrip=-2)%(then)%(color:magenta)remote-branch%(else)%(if:equals=refs/heads)%(refname:rstrip=-2)%(then)%(color:brightgreen)branch%(else)%(if:equals=refs/tags)%(refname:rstrip=-2)%(then)%(color:brightcyan)tag%(else)%(if:equals=refs/stash)%(refname:rstrip=-2)%(then)%(color:brightred)stash%(else)%(color:white)%(refname:rstrip=-2)%(end)%(end)%(end)%(end)%(color:reset)%09%(color:yellow)%(refname:short)%(color:reset)%09%(color:green)(%(creatordate:relative))%(color:reset)%09%(color:blue)%(subject)%(color:reset)' \
    "${git_for_each_ref_args[@]}" "$@"
}

__git-status-path () {
  local file_status="${1:0:2}"
  local file_path="${1:3}"
  case "$file_status" in
    *R*|*C*) file_path="${file_path##* -> }" ;;
  esac

  if [[ $file_path == \"*\" ]]; then
    file_path="${file_path#\"}"
    file_path="${file_path%\"}"
    printf '%b' "$file_path"
  else
    printf '%s' "$file_path"
  fi
}

__git-files () {
  local mode="${1:-status}"
  local plain colored file_path root
  local status_paths=''
  local -a pathspec=()
  local -a tracked_pathspec=()
  local -a git_status_args=()
  local -a git_ls_files_args=()

  __fzfgit-parse-env "${FZFGIT_GIT_STATUS:-}" || return
  git_status_args=("${__fzfgit_parsed_args[@]}")

  case "$mode" in
    status)
      ;;
    all)
      root=$(git rev-parse --show-toplevel) || return
      tracked_pathspec=(-- "$root")
      ;;
    cwd)
      pathspec=(-- .)
      tracked_pathspec=(-- .)
      ;;
    *)
      return 2
      ;;
  esac

  exec 3< <(
    git -c core.quotePath=false -c status.relativePaths=true \
      -c color.status=always status \
      --short --no-branch --untracked-files=all \
      "${git_status_args[@]}" "${pathspec[@]}"
  )
  while IFS= read -r plain; do
    if ! IFS= read -r colored <&3; then
      colored="$plain"
    fi
    file_path=$(__git-status-path "$plain")
    status_paths+="$file_path"$'\n'
    printf '%s\t%s\n' "$colored" "$file_path"
  done < <(
    git -c core.quotePath=false -c status.relativePaths=true \
      -c color.status=never status \
      --short --no-branch --untracked-files=all \
      "${git_status_args[@]}" "${pathspec[@]}"
  )
  exec 3<&-

  [[ $mode == status ]] && return

  __fzfgit-parse-env "${FZFGIT_GIT_LS_FILES:-}" || return
  git_ls_files_args=("${__fzfgit_parsed_args[@]}")

  git -c core.quotePath=false ls-files \
    "${git_ls_files_args[@]}" "${tracked_pathspec[@]}" |
    grep -vxFf <(printf '%s' "$status_paths") |
    while IFS= read -r file_path; do
      printf '   %s\t%s\n' "$file_path" "$file_path"
    done
}

case "${1:-}" in
  --refs)
    shift
    __git-refs "$@"
    ;;
  --files)
    shift
    __git-files "$@"
    ;;
esac

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
    --preview-window 'right,50%,wrap-word' \
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
  local path_preview_script="${user_conf_path:-"$HOME/.usr_conf"}/utils/fzf-preview.sh"
  local repo_prefix header git_diff_options
  local reload_base="bash \"$SCRIPT_PATH\" --files status"
  local reload_all="bash \"$SCRIPT_PATH\" --files all"
  local reload_cwd="bash \"$SCRIPT_PATH\" --files cwd"
  local -a directory_options=()
  local -a git_diff_args=()

  __fzfgit-parse-env "${FZFGIT_GIT_DIFF:-}" || return
  git_diff_args=("${__fzfgit_parsed_args[@]}")
  git_diff_options=$(__fzfgit-shell-join "${git_diff_args[@]}")

  repo_prefix=$(git rev-parse --show-prefix) || return
  header='CTRL-F: All repository files | CTRL-R: Changed files'
  if [[ -n $repo_prefix ]]; then
    header+=' | CTRL-D: Current directory files'
    directory_options=(
      --bind "ctrl-d:change-prompt(Dir Files> )+transform-border-label(pwd)+reload:$reload_cwd"
    )
  fi

  __git-files status |
  fzf-down --ansi \
    --delimiter=$'\t' \
    --with-nth 1 \
    --accept-nth 2 \
    "--history=$FZF_HIST_DIR/fzf-git_file" \
    --preview-window '60%,wrap-word' \
    --prompt 'Files> ' \
    --header "$header" \
    --bind "ctrl-f:change-prompt(All Files> )+change-border-label()+reload:$reload_all" \
    --bind "ctrl-r:change-prompt(Files> )+change-border-label()+reload:$reload_base" \
    "${directory_options[@]}" \
    --preview "if [ -f {2} ]; then
        git diff --color=always$git_diff_options -- {2}$__page_command__ |
          sed 1,4d |
          bat -p --color=always
        printf \"\\n\" ;
      fi
      \"$path_preview_script\" {2}" \
    "$@"
}

fgb () {
  is_in_git_repo || return
  local branch_format='%(if)%(symref)%(then)%(else)%(if)%(HEAD)%(then)%(color:green)%(else)%(if:equals=refs/remotes)%(refname:rstrip=-2)%(then)%(color:red)%(end)%(end)%(HEAD) %(if:equals=refs/remotes)%(refname:rstrip=-2)%(then)remotes/%(refname:short)%(else)%(refname:short)%(end)%(color:reset)%09%(refname:short)%(end)'
  local git_log_options
  local -a git_branch_args=()
  local -a git_log_args=()

  __fzfgit-parse-env "${FZFGIT_GIT_BRANCH:-}" || return
  git_branch_args=("${__fzfgit_parsed_args[@]}")
  __fzfgit-parse-env "${FZFGIT_GIT_LOG:-}" || return
  git_log_args=("${__fzfgit_parsed_args[@]}")
  git_log_options=$(__fzfgit-shell-join "${git_log_args[@]}")

  git branch -a --color=always --omit-empty --sort=refname \
    "--format=$branch_format" "${git_branch_args[@]}" |
  fzf-down --ansi --tac \
    --delimiter=$'\t' \
    --with-nth 1 \
    --accept-nth 2 \
    --preview-window 'right,70%,wrap-word' \
    --prompt 'Branches> ' \
    "--history=$FZF_HIST_DIR/fzf-git_branch" \
    --preview "
      git log --oneline --graph --date=short --color=always --pretty='format:%C(auto)%cd %h%d %s'$git_log_options {2}" \
    "$@"
}

fgt () {
  is_in_git_repo || return
  local git_show_options
  local -a git_tag_args=()
  local -a git_show_args=()

  __fzfgit-parse-env "${FZFGIT_GIT_TAG:-}" || return
  git_tag_args=("${__fzfgit_parsed_args[@]}")
  __fzfgit-parse-env "${FZFGIT_GIT_SHOW:-}" || return
  git_show_args=("${__fzfgit_parsed_args[@]}")
  git_show_options=$(__fzfgit-shell-join "${git_show_args[@]}")

  git tag --sort -version:refname "${git_tag_args[@]}" |
  fzf-down --preview-window 'right,70%,wrap-word' \
    --prompt 'Tags> ' \
    --preview "
      git show --color=always$git_show_options {}$__page_command__ |
      bat --color=always" \
    "$@"
    # --preview 'git show --color=always {}'
}

fgh () {
  is_in_git_repo || return
  local git_show_options
  local -a git_log_args=()
  local -a git_show_args=()

  __fzfgit-parse-env "${FZFGIT_GIT_LOG:-}" || return
  git_log_args=("${__fzfgit_parsed_args[@]}")
  __fzfgit-parse-env "${FZFGIT_GIT_SHOW:-}" || return
  git_show_args=("${__fzfgit_parsed_args[@]}")
  git_show_options=$(__fzfgit-shell-join "${git_show_args[@]}")

  git log --date=short \
    --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)%C(reset)%x09%h" \
    --graph --color=always "${git_log_args[@]}" |
  fzf-down --ansi --no-sort --reverse \
    --delimiter=$'\t' \
    --with-nth 1 \
    --accept-nth 2 \
    --prompt 'Hashes> ' \
    "--history=$FZF_HIST_DIR/fzf-git_hash" \
    --header 'Press CTRL-S to toggle sort' \
    --preview "
      git show --color=always$git_show_options {2}$__page_command__ |
        bat -p --color=always" \
    "$@"
}

fgha () {
  is_in_git_repo || return
  local git_show_options
  local -a git_log_args=()
  local -a git_show_args=()

  __fzfgit-parse-env "${FZFGIT_GIT_LOG:-}" || return
  git_log_args=("${__fzfgit_parsed_args[@]}")
  __fzfgit-parse-env "${FZFGIT_GIT_SHOW:-}" || return
  git_show_args=("${__fzfgit_parsed_args[@]}")
  git_show_options=$(__fzfgit-shell-join "${git_show_args[@]}")

  git log --all --date=short \
    --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)%C(reset)%x09%h" \
    --graph --color=always "${git_log_args[@]}" |
  fzf-down --ansi --no-sort --reverse \
    --delimiter=$'\t' \
    --with-nth 1 \
    --accept-nth 2 \
    --prompt 'All Hashes> ' \
    "--history=$FZF_HIST_DIR/fzf-git_hash-all" \
    --header 'Press CTRL-S to toggle sort' \
    --preview "
      git show --color=always$git_show_options {2}$__page_command__ |
        bat -p --color=always" \
    "$@"
}

fgr () {
  is_in_git_repo || return
  local git_log_options
  local -a git_remote_args=()
  local -a git_log_args=()

  __fzfgit-parse-env "${FZFGIT_GIT_REMOTE:-}" || return
  git_remote_args=("${__fzfgit_parsed_args[@]}")
  __fzfgit-parse-env "${FZFGIT_GIT_LOG:-}" || return
  git_log_args=("${__fzfgit_parsed_args[@]}")
  git_log_options=$(__fzfgit-shell-join "${git_log_args[@]}")

  git remote -v "${git_remote_args[@]}" | awk '{print $1 "\t" $2}' | uniq |
  fzf-down --tac \
    --delimiter=$'\t' \
    --accept-nth 1 \
    --prompt 'Remotes> ' \
    "--history=$FZF_HIST_DIR/fzf-git_remote" \
    --preview "
      git log --color=always --oneline --graph --date=short --pretty='format:%C(auto)%cd %h%d %s'$git_log_options {1}" \
    "$@"
}

fgs () {
  is_in_git_repo || return
  local git_show_options
  local -a git_stash_args=()
  local -a git_show_args=()

  __fzfgit-parse-env "${FZFGIT_GIT_STASH:-}" || return
  git_stash_args=("${__fzfgit_parsed_args[@]}")
  __fzfgit-parse-env "${FZFGIT_GIT_SHOW:-}" || return
  git_show_args=("${__fzfgit_parsed_args[@]}")
  git_show_options=$(__fzfgit-shell-join "${git_show_args[@]}")

  git stash list "${git_stash_args[@]}" |
    fzf-down --reverse -d: \
      --prompt 'Stashes> ' \
      "--history=$FZF_HIST_DIR/fzf-git_stash" \
      --preview "
        git show --color=always$git_show_options {1}$__page_command__ |
          bat -p --color=always" \
      --accept-nth '1' \
      "$@"
  # git stash list | fzf-down --reverse -d: --preview 'git show --color=always {1}' |
}

# fshow - git commit browser (enter for show, ctrl-d for diff, ` toggles sort)
fshow () {
  git rev-parse HEAD > /dev/null 2>&1 || return

  local git_log_options git_show_options git_diff_options
  local -a git_log_args=()
  local -a git_show_args=()
  local -a git_diff_args=()

  __fzfgit-parse-env "${FZFGIT_GIT_LOG:-}" || return
  git_log_args=("${__fzfgit_parsed_args[@]}")
  git_log_options=$(__fzfgit-shell-join "${git_log_args[@]}")
  __fzfgit-parse-env "${FZFGIT_GIT_SHOW:-}" || return
  git_show_args=("${__fzfgit_parsed_args[@]}")
  git_show_options=$(__fzfgit-shell-join "${git_show_args[@]}")
  __fzfgit-parse-env "${FZFGIT_GIT_DIFF:-}" || return
  git_diff_args=("${__fzfgit_parsed_args[@]}")
  git_diff_options=$(__fzfgit-shell-join "${git_diff_args[@]}")

  local def_pager="less -R"
  local pager=""
  local preview_pager
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
    git show --color=always$git_show_options {2} $preview_pager |
      bat -p --color=always
  "

  local git_base_cmd="git log --graph --color=always --format='%C(auto)%h%d %s %C(black)%C(bold)%cr%C(reset)%x09%h'"
  local git_current_cmd="$git_base_cmd$git_log_options"
  local git_all_cmd="$git_base_cmd --all$git_log_options"

  # Find clipboard utility
  local copy='true'
  # NOTE: Will probably will never run on windows but
  # better safe than sorry
  if [ "$OS" = 'Windows_NT' ]; then
    # Gitbash
    copy="cat {+f2} | pbcopy.exe"
  elif [ "$OSTYPE" = 'darwin' ] || command -v 'pbcopy' &>/dev/null; then
    copy="cat {+f2} | pbcopy"
  # Assume linux if above didn't match
  elif [ -n "$WAYLAND_DISPLAY" ] && command -v 'wl-copy' &>/dev/null; then
    copy="cat {+f2} | wl-copy --foreground --type text/plain"
  elif [ -n "$DISPLAY" ] && command -v 'xsel' &>/dev/null; then
    copy="cat {+f2} | xsel -i -b"
  elif [ -n "$DISPLAY" ] && command -v 'xclip' &>/dev/null; then
    copy="cat {+f2} | xclip -i -selection clipboard"
  fi

  while out=$(
      fzf-down --ansi --no-sort --reverse --query="$q" \
          --delimiter=$'\t' \
          --with-nth 1 \
          --accept-nth 2 \
          --preview "$preview" \
	  --preview-window 'right,50%,wrap-word' \
          --bind "start:reload:$git_current_cmd" \
          --bind "ctrl-f:reload:$git_current_cmd" \
          --bind "ctrl-a:reload:$git_all_cmd" \
          --bind "ctrl-y:execute-silent($copy)+bell" \
          --header 'ctrl-d: Diff | ctrl-a: All | ctrl-f: HEAD | ctrl-y: Copy' \
          --prompt 'Commits> ' \
          "--history=$FZF_HIST_DIR/fzf-git_show" \
          --print-query --expect=ctrl-d \
          "$@"
      ); do
    q=$(head -1 <<< "$out")
    k=$(head -2 <<< "$out" | tail -1)
    shas=()
    while IFS='' read -r new_sha; do
      shas+=("$new_sha")
    done < <(sed '1,2d;/^$/d' <<< "$out")

    # shellcheck disable=SC2128
    [ -z "$shas" ] && continue
    if [ "$k" = ctrl-d ]; then
      bash -c "git diff --color=always$git_diff_options ${shas[*]} | $pager"
    else
      for sha in "${shas[@]}"; do
        bash -c "git show --color=always$git_show_options $sha | $pager"
      done
    fi
  done
}

fgl () {
  local git_show_options
  local -a git_reflog_args=()
  local -a git_show_args=()

  __fzfgit-parse-env "${FZFGIT_GIT_REFLOG:-}" || return
  git_reflog_args=("${__fzfgit_parsed_args[@]}")
  __fzfgit-parse-env "${FZFGIT_GIT_SHOW:-}" || return
  git_show_args=("${__fzfgit_parsed_args[@]}")
  git_show_options=$(__fzfgit-shell-join "${git_show_args[@]}")

  git reflog --color=always \
    --format="%C(blue)%gD %C(yellow)%h%C(auto)%d %gs" \
    "${git_reflog_args[@]}" |
  fzf-down --ansi \
    --prompt 'Reflogs> ' \
    --bind 'alt-r:toggle-raw' \
    --preview "git show --color=always$git_show_options {1} | delta" \
    --accept-nth '1' "$@"
}

fgw () {
  local git_worktree_options git_status_options git_log_options
  local -a git_worktree_args=()
  local -a git_status_args=()
  local -a git_log_args=()

  __fzfgit-parse-env "${FZFGIT_GIT_WORKTREE:-}" || return
  git_worktree_args=("${__fzfgit_parsed_args[@]}")
  git_worktree_options=$(__fzfgit-shell-join "${git_worktree_args[@]}")
  __fzfgit-parse-env "${FZFGIT_GIT_STATUS:-}" || return
  git_status_args=("${__fzfgit_parsed_args[@]}")
  git_status_options=$(__fzfgit-shell-join "${git_status_args[@]}")
  __fzfgit-parse-env "${FZFGIT_GIT_LOG:-}" || return
  git_log_args=("${__fzfgit_parsed_args[@]}")
  git_log_options=$(__fzfgit-shell-join "${git_log_args[@]}")

  # --border-label '🌴 Worktrees ' \
  git worktree list "${git_worktree_args[@]}" |
    fzf-down \
    --prompt 'Worktrees> ' \
    --header 'CTRL-X (remove worktree) | ALT-T ' \
    --bind "ctrl-x:reload(git worktree remove {1} > /dev/null; git worktree list$git_worktree_options)" \
    --preview "
      git -c color.status=always -C {1} status --short --branch$git_status_options
      echo
      git log --oneline --graph --date=short --color=always --pretty='format:%C(auto)%cd %h%d %s'$git_log_options {2} --
    " \
    --accept-nth '1'\
    --with-nth 2.. --bind 'alt-t:change-with-nth(..|2..)' \
    "$@"
}

fge () {
  local git_log_options
  local -a git_log_args=()

  __fzfgit-parse-env "${FZFGIT_GIT_LOG:-}" || return
  git_log_args=("${__fzfgit_parsed_args[@]}")
  git_log_options=$(__fzfgit-shell-join "${git_log_args[@]}")

  __git-refs --exclude=refs/remotes |
    fzf-down \
      --ansi \
      --delimiter=$'\t' \
      --nth 2,2.. \
      --tiebreak begin \
      --prompt 'Each ref> ' \
      --header-lines 1 \
      --preview-window down,border-top,40% \
      --color hl:underline,hl+:underline \
      --no-hscroll \
      --bind 'ctrl-/:change-preview-window(down,70%|hidden|)' \
      --bind "ctrl-f:change-prompt(Every ref> )+reload:bash \"$SCRIPT_PATH\" --refs" \
      --bind "ctrl-r:change-prompt(Each ref> )+reload:bash \"$SCRIPT_PATH\" --refs --exclude=refs/remotes" \
      --preview "git log --oneline --graph --date=short --color=always --pretty='format:%C(auto)%cd %h%d %s'$git_log_options {2} --" \
      --accept-nth 2 \
      "$@"
      # --bind "ctrl-o:execute-silent:bash \"$__fzf_git\" --list {1} {2}" \
      # --bind "alt-enter:become:printf '%s\n' {+2} | sed 's@[^/]*/@@'" \
}

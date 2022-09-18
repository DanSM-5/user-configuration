# GIT heart FZF
# -------------
# A powershell support for fzf-git functions (using gitbash under the hood)

# Ref: https://gist.github.com/junegunn/8b572b8d4b5eddd8b85e5f4d40f17236

# get git bash location
$__gitbash__ = $(where.exe bash | grep 'Git\\usr\\bin\\bash')

function is_in_git_repo () {
  if (git rev-parse HEAD 2> $null) { return $true } else { return $false }
}

$fzf_down = " SHELL='/bin/bash' fzf --height 50% --min-height 20 --layout=reverse --border --bind ctrl-/:toggle-preview "

      # --preview '(git diff --color=always -- {-1} | sed 1,4d | bat -p --color=always && bat --color=always {-1})' |
$fgf_command = @'
    git -c color.status=always status --short |
'@ + $script:fzf_down + @'
    -m --ansi --nth 2..,.. \
      --preview 'if \[ -f {-1} \]; then git diff --color=always -- {-1} | sed 1,4d | bat -p --color=always; bat --color=always {-1}; else ls -aF --color=always {-1}; fi' |
    cut -c4- | sed 's/.* -> //'
'@

$fgb_command = @'
    git branch -a --color=always | grep -v '/HEAD\s' | sort |
'@ + $script:fzf_down + @'
      --ansi --multi --tac \
        --preview 'git log --oneline --graph --date=short --color=always --pretty=\"format:%C(auto)%cd %h%d %s\" $(sed s/^..// <<< {} | cut -d\" \" -f1)' |
      sed 's/^..//' | cut -d' ' -f1 |
      sed 's#^remotes##'
'@

$fgt_command = @'
  git tag --sort -version:refname |
'@ + $script:fzf_down + @'
  --multi --preview-window right:70% \
    --preview 'git show --color=always {} | bat --color=always'
'@

$fgh_command = @'
  git log --date=short --format='%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)' --graph --color=always |
'@ + $script:fzf_down + @'
  --ansi --no-sort --reverse --multi --bind 'ctrl-s:toggle-sort' \
    --header 'Press CTRL-S to toggle sort' \
    --preview 'grep -o \"[a-f0-9]\{7,\}\" <<< {} | xargs git show --color=always | bat -p --color=always' |
  grep -o '[a-f0-9]\{7,\}'
'@

$fgha_command = @'
  git log --all --date=short --format='%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)' --graph --color=always |
'@ + $script:fzf_down + @'
  --ansi --no-sort --reverse --multi --bind 'ctrl-s:toggle-sort' \
    --header 'Press CTRL-S to toggle sort' \
    --preview 'grep -o \"[a-f0-9]\{7,\}\" <<< {} | xargs git show --color=always | bat -p --color=always' |
  grep -o '[a-f0-9]\{7,\}'
'@

$fgr_command = @'
  git remote -v | awk '{print $1 "\t" $2}' | uniq |
'@ + $script:fzf_down + @'
  --tac \
    --preview 'git log --oneline --graph --date=short --pretty=\"format:%C(auto)%cd %h%d %s\" {1}' |
  cut -d$'\t' -f1
'@

$fgs_command = @'
  git stash list |
'@ + $script:fzf_down + @'
  --reverse -d: --preview 'git show --color=always {1} | bat -p --color=always' |
  cut -d: -f1
'@

function fgf () {
  if ($script:is_in_git_repo) { return }
  & "$script:__gitbash__" -c $script:fgf_command
  # & "$script:__gitbash__" -c @'
  #   git -c color.status=always status --short |
  #   fzf --height 50% --min-height 20 --border --bind ctrl-/:toggle-preview -m --ansi --nth 2..,.. \
  #     --preview '(git diff --color=always -- {-1} | sed 1,4d | bat -p --color=always; bat --color=always {-1})' |
  #   cut -c4- | sed 's/.* -> //'
# '@
}

function fgb () {
  if ($script:is_in_git_repo) { return }
  # requires -l flag for sub-shell process
  & "$script:__gitbash__" -lc $script:fgb_command

  # require to escape the string twice in pwsh and once in gitbash
  # iex $("& `"$__gitbash__`" -lc `"git branch -a --color=always | grep -v '/HEAD\s' | sort | fzf --height 50% --min-height 20 --border --bind ctrl-/:toggle-preview --ansi --multi --tac --preview 'git log --oneline --graph --date=short --color=always --pretty=\```"format:%C(auto)%cd %h%d %s\```" ```$(sed s/^..// <<< {} | cut -d\```" \```" -f1)' | sed 's/^..//' | cut -d' ' -f1 | sed 's#^remotes##'`"")

  # only one escape for pwsh and one for gitbash
  # & "$testbash" -lc "git branch -a --color=always | grep -v '/HEAD\s' | sort | fzf --height 50% --min-height 20 --border --bind ctrl-/:toggle-preview --ansi --multi --tac --preview 'git log --oneline --graph --date=short --color=always --pretty=\`"format:%C(auto)%cd %h%d %s\`" `$(sed s/^..// <<< {} | cut -d\`" \`" -f1)' | sed 's/^..//' | cut -d' ' -f1 | sed 's#^remotes##'"

  # Final version
  # & "$script:__gitbash__" -lc @'
  #   git branch -a --color=always | grep -v '/HEAD\s' | sort |
  #     fzf --height 50% --min-height 20 --border --bind ctrl-/:toggle-preview --ansi --multi --tac \
  #       --preview 'git log --oneline --graph --date=short --color=always --pretty=\"format:%C(auto)%cd %h%d %s\" $(sed s/^..// <<< {} | cut -d\" \" -f1)' |
  #     sed 's/^..//' | cut -d' ' -f1 |
  #     sed 's#^remotes##'
# '@
}


function fgt () {
  if ($script:is_in_git_repo) { return }
  & "$script:__gitbash__" -lc $script:fgt_command
  # & "$script:__gitbash__" -c @'
  # git tag --sort -version:refname |
  # fzf --height 50% --min-height 20 --border --bind ctrl-/:toggle-preview --multi --preview-window right:70% \
  #   --preview 'git show --color=always {} | bat --color=always'
# '@
}

function fgh () {
  if ($script:is_in_git_repo) { return }
  & "$script:__gitbash__" -lc $script:fgh_command
  # & "$script:__gitbash__" -lc @'
  #   git log --date=short --format='%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)' --graph --color=always |
  #   fzf --height 50% --min-height 20 --border --bind ctrl-/:toggle-preview --ansi --no-sort --reverse --multi --bind 'ctrl-s:toggle-sort' \
  #     --header 'Press CTRL-S to toggle sort' \
  #     --preview 'grep -o \"[a-f0-9]\{7,\}\" <<< {} | xargs git show --color=always | bat -p --color=always' |
  #   grep -o '[a-f0-9]\{7,\}'
# '@
}

function fgha () {
  if ($script:is_in_git_repo) { return }
  & "$script:__gitbash__" -lc $script:fgha_command
  # & "$script:__gitbash__" -lc @'
  #   git log --all --date=short --format='%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)' --graph --color=always |
  #   fzf --height 50% --min-height 20 --border --bind ctrl-/:toggle-preview --ansi --no-sort --reverse --multi --bind 'ctrl-s:toggle-sort' \
  #     --header 'Press CTRL-S to toggle sort' \
  #     --preview 'grep -o \"[a-f0-9]\{7,\}\" <<< {} | xargs git show --color=always | bat -p --color=always' |
  #   grep -o '[a-f0-9]\{7,\}'
# '@
}

function fgr () {
  if ($script:is_in_git_repo) { return }
  & "$script:__gitbash__" -lc $script:fgr_command
  # & "$script:__gitbash__" -c @'
  #   git remote -v | awk '{print $1 \"\t\" $2}' | uniq |
  #   fzf --height 50% --min-height 20 --border --bind ctrl-/:toggle-preview --tac \
  #     --preview 'git log --oneline --graph --date=short --pretty=\"format:%C(auto)%cd %h%d %s\" {1}' |
  #   cut -d$'\t' -f1
# '@
}

function fgss () {
  if ($script:is_in_git_repo) { return }
  & "$script:__gitbash__" -lc $script:fgs_command
  # & "$script:__gitbash__" -c @'
  #   git stash list |
  #   fzf --height 50% --min-height 20 --border --bind ctrl-/:toggle-preview \
  #     --reverse -d: --preview 'git show --color=always {1} | bat -p --color=always' |
  #   cut -d: -f1
# '@
}

# Export-ModuleMember -Function fgb

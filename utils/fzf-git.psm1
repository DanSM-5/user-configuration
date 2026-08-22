# GIT heart FZF
# -------------
# Powershell version
# because using pipes with cmdlets break string encoding for formatted output

# Ref: https://gist.github.com/junegunn/8b572b8d4b5eddd8b85e5f4d40f17236

# TODO: Update fzf commands to use `--with-shell` rather
# than generating temporary powershell scripts

function __fzfgit_env_args ([AllowEmptyString()][string]$value = '') {
  if ([string]::IsNullOrEmpty($value)) { return }

  $parsed = [System.Collections.Generic.List[string]]::new()
  $current = [System.Text.StringBuilder]::new()
  [char]$quote = [char]0
  $started = $false
  $single_quote = [char]39
  $double_quote = [char]34
  $backslash = [char]92

  for ($index = 0; $index -lt $value.Length; $index++) {
    [char]$character = $value[$index]

    if ($quote -ne [char]0) {
      if ($character -eq $quote) {
        $quote = [char]0
        $started = $true
      } elseif ($quote -eq $double_quote -and $character -eq $backslash) {
        if ($index + 1 -lt $value.Length) {
          [char]$next_character = $value[$index + 1]
          if (
            [char]::IsWhiteSpace($next_character) -or
            $next_character -eq $single_quote -or
            $next_character -eq $double_quote -or
            $next_character -eq $backslash
          ) {
            $null = $current.Append($next_character)
            $index++
          } else {
            $null = $current.Append($character)
          }
        } else {
          $null = $current.Append($character)
        }
        $started = $true
      } else {
        $null = $current.Append($character)
        $started = $true
      }
    } elseif ($character -eq $single_quote -or $character -eq $double_quote) {
      $quote = $character
      $started = $true
    } elseif ($character -eq $backslash) {
      if ($index + 1 -lt $value.Length) {
        [char]$next_character = $value[$index + 1]
        if (
          [char]::IsWhiteSpace($next_character) -or
          $next_character -eq $single_quote -or
          $next_character -eq $double_quote -or
          $next_character -eq $backslash
        ) {
          $null = $current.Append($next_character)
          $index++
        } else {
          $null = $current.Append($character)
        }
      } else {
        $null = $current.Append($character)
      }
      $started = $true
    } elseif ([char]::IsWhiteSpace($character)) {
      if ($started) {
        $parsed.Add($current.ToString())
        $null = $current.Clear()
        $started = $false
      }
    } else {
      $null = $current.Append($character)
      $started = $true
    }
  }

  if ($quote -ne [char]0) {
    throw 'fzf-git: unmatched quote in Git option environment variable'
  }

  if ($started) {
    $parsed.Add($current.ToString())
  }

  return $parsed.ToArray()
}

function __fzfgit_pwsh_join ([string[]]$values = @()) {
  if (-not $values -or $values.Count -eq 0) { return '' }

  [string[]]$quoted = @($values | ForEach-Object {
    "'$($_.Replace("'", "''"))'"
  })
  return ' ' + ($quoted -join ' ')
}

function is_in_git_repo () {
  if (git rev-parse HEAD 2> $null) { return $true } else { return $false }
}

$__pager__ = if (Get-Command -Name delta -All -ErrorAction 0) { 'delta | ' } else { '' }

$user_conf_path = if ($env:user_conf_path) { $env:user_conf_path } else { "$HOME/.usr_conf" }
$path_preview_script = Join-Path $user_conf_path "utils/fzf-preview.ps1"
$script:fzf_git_module_path = $PSCommandPath

function __git_refs () {
  $format = '%(if:equals=refs/remotes)%(refname:rstrip=-2)%(then)%(color:magenta)remote-branch%(else)%(if:equals=refs/heads)%(refname:rstrip=-2)%(then)%(color:brightgreen)branch%(else)%(if:equals=refs/tags)%(refname:rstrip=-2)%(then)%(color:brightcyan)tag%(else)%(if:equals=refs/stash)%(refname:rstrip=-2)%(then)%(color:brightred)stash%(else)%(color:white)%(refname:rstrip=-2)%(end)%(end)%(end)%(end)%(color:reset)%09%(color:yellow)%(refname:short)%(color:reset)%09%(color:green)(%(creatordate:relative))%(color:reset)%09%(color:blue)%(subject)%(color:reset)'
  [string[]]$git_for_each_ref_args = @(__fzfgit_env_args $env:FZFGIT_GIT_FOR_EACH_REF)
  git for-each-ref `
    --sort=-creatordate --sort=-HEAD --color=always `
    "--format=$format" @git_for_each_ref_args @args
}

function __git_status_path ([string]$line) {
  if ($line.Length -le 3) { return '' }

  $status = $line.Substring(0, 2)
  $path = $line.Substring(3)
  if ($status.Contains('R') -or $status.Contains('C')) {
    $rename_index = $path.LastIndexOf(' -> ', [System.StringComparison]::Ordinal)
    if ($rename_index -ge 0) {
      $path = $path.Substring($rename_index + 4)
    }
  }

  if ($path.Length -ge 2 -and $path[0] -eq '"' -and $path[$path.Length - 1] -eq '"') {
    $path = $path.Substring(1, $path.Length - 2)
    $path = $path -replace '\\(["\\])', '$1'
  }

  return $path
}

function __git_status_entries ([string[]]$pathspec = @()) {
  [string[]]$git_status_args = @(__fzfgit_env_args $env:FZFGIT_GIT_STATUS)
  $status_options = @('status', '--short', '--no-branch', '--untracked-files=all') + $git_status_args + $pathspec
  [string[]]$plain_lines = @(git -c core.quotePath=false -c status.relativePaths=true -c color.status=never @status_options)
  [string[]]$colored_lines = @(git -c core.quotePath=false -c status.relativePaths=true -c color.status=always @status_options)

  for ($index = 0; $index -lt $plain_lines.Count; $index++) {
    $display = if ($index -lt $colored_lines.Count) { $colored_lines[$index] } else { $plain_lines[$index] }
    [PSCustomObject]@{
      Display = $display
      Path = __git_status_path $plain_lines[$index]
    }
  }
}

function __git_files (
  [ValidateSet('status', 'all', 'cwd')]
  [string]$mode = 'status'
) {
  $pathspec = if ($mode -eq 'cwd') { @('--', '.') } else { @() }
  $entries = @(__git_status_entries $pathspec)

  foreach ($entry in $entries) {
    "$($entry.Display)`t$($entry.Path)"
  }

  if ($mode -eq 'status') { return }

  $changed_paths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
  foreach ($entry in $entries) {
    $null = $changed_paths.Add($entry.Path)
  }

  $tracked_pathspec = if ($mode -eq 'cwd') {
    @('--', '.')
  } else {
    @('--', [string](git rev-parse --show-toplevel))
  }

  [string[]]$git_ls_files_args = @(__fzfgit_env_args $env:FZFGIT_GIT_LS_FILES)
  [string[]]$tracked_files = @(git -c core.quotePath=false ls-files @git_ls_files_args @tracked_pathspec)
  foreach ($path in $tracked_files) {
    if (-not $changed_paths.Contains($path)) {
      "   $path`t$path"
    }
  }
}

function get_fzf_down_options() {
  $options = @(
    '--height', '80%',
    '--min-height', '20',
    '--input-border',
    '--cycle',
    '--layout=reverse',
    '--multi',
    '--border',
    '--preview-window', 'right,50%,wrap-word',
    '--bind', 'alt-f:first',
    '--bind', 'alt-l:last',
    '--bind', 'alt-c:clear-query',
    '--bind', 'alt-a:select-all',
    '--bind', 'alt-d:deselect-all',
    '--bind', 'ctrl-/:change-preview-window(down|hidden|)',
    '--bind', 'ctrl-^:toggle-preview',
    '--bind', 'alt-up:preview-page-up',
    '--bind', 'alt-down:preview-page-down',
    '--bind', 'ctrl-s:toggle-sort'
  )

  return $options
}

function fgf () {
  if (-not (is_in_git_repo)) { return }

  [string[]]$git_diff_args = @(__fzfgit_env_args $env:FZFGIT_GIT_DIFF)
  $git_diff_options = __fzfgit_pwsh_join $git_diff_args
  $repo_prefix = [string](git rev-parse --show-prefix)
  $escaped_module_path = $script:fzf_git_module_path.Replace("'", "''")
  $escaped_preview_script = $path_preview_script.Replace("'", "''")
  $reload_files = "Import-Module '$escaped_module_path' -Force; __git_files"
  $header = 'CTRL-F: All repository files | CTRL-R: Changed files'
  if ($repo_prefix) {
    $header += ' | CTRL-D: Current directory files'
  }
  $preview = "if (Test-Path -LiteralPath {2} -PathType Leaf -ErrorAction SilentlyContinue) { git -c core.quotePath=false diff --color=always$git_diff_options -- {2} | Select-Object -Skip 4 | $($script:__pager__)bat -p --color=always; Write-Output ''; }; & '$escaped_preview_script' {2}"

  $down_options = get_fzf_down_options
  $cmd_options = @(
    '--prompt', 'Files> ',
    "--history=$env:FZF_HIST_DIR/fzf-git_file",
    '--preview-window', '60%,wrap-word',
    '--ansi',
    '--delimiter', "`t",
    '--with-nth', '1',
    '--accept-nth', '2',
    '--header', $header,
    '--with-shell', 'pwsh -NoLogo -NoProfile -NonInteractive -Command',
    '--bind', "ctrl-f:change-prompt(All Files> )+change-border-label()+reload:$reload_files all",
    '--bind', "ctrl-r:change-prompt(Files> )+change-border-label()+reload:$reload_files status",
    '--preview', $preview
  )

  if ($repo_prefix) {
    $cmd_options += @(
      '--bind', "ctrl-d:change-prompt(Dir Files> )+transform-border-label(`$PWD.Path)+reload:$reload_files cwd"
    )
  }

  [string[]]$selected = __git_files status |
    fzf @down_options @cmd_options @args

  return $selected
}

function fgb () {
  if (-not (is_in_git_repo)) { return }

  [string[]]$git_branch_args = @(__fzfgit_env_args $env:FZFGIT_GIT_BRANCH)
  [string[]]$git_log_args = @(__fzfgit_env_args $env:FZFGIT_GIT_LOG)
  $git_log_options = __fzfgit_pwsh_join $git_log_args
  $branch_format = '%(if)%(symref)%(then)%(else)%(if)%(HEAD)%(then)%(color:green)%(else)%(if:equals=refs/remotes)%(refname:rstrip=-2)%(then)%(color:red)%(end)%(end)%(HEAD) %(if:equals=refs/remotes)%(refname:rstrip=-2)%(then)remotes/%(refname:short)%(else)%(refname:short)%(end)%(color:reset)%09%(refname:short)%(end)'
  $preview = "git log --oneline --graph --date=short --color=always '--pretty=format:%C(auto)%cd%x20%h%d%x20%s'$git_log_options {2}"
  $down_options = get_fzf_down_options
  $cmd_options = @(
    '--prompt', 'Branches> ',
    "--history=$env:FZF_HIST_DIR/fzf-git_branch",
    '--ansi',
    '--tac',
    '--delimiter', "`t",
    '--with-nth', '1',
    '--accept-nth', '2',
    '--with-shell', 'pwsh -NoLogo -NoProfile -NonInteractive -Command',
    '--preview-window', 'right,70%,wrap-word',
    '--preview', $preview
  )

  [string[]]$selected = git branch -a --color=always --omit-empty --sort=refname "--format=$branch_format" @git_branch_args |
    fzf @down_options @cmd_options @args

  return $selected
}

function fgt () {
  if (-not (is_in_git_repo)) { return }

  [string[]]$git_tag_args = @(__fzfgit_env_args $env:FZFGIT_GIT_TAG)
  [string[]]$git_show_args = @(__fzfgit_env_args $env:FZFGIT_GIT_SHOW)
  $git_show_options = __fzfgit_pwsh_join $git_show_args
  $preview = "git show --color=always$git_show_options {} | $($script:__pager__)bat -p --color=always"
  $down_options = get_fzf_down_options
  $cmd_options = @(
    '--prompt', 'Tags> ',
    "--history=$env:FZF_HIST_DIR/fzf-git_tag",
    '--preview-window', 'right,70%,wrap-word',
    '--with-shell', 'pwsh -NoLogo -NoProfile -NonInteractive -Command',
    '--preview', $preview
  )

  $selected = git tag '--sort=-version:refname' @git_tag_args |
    fzf @down_options @cmd_options @args

  return $selected
}

function fgh () {
  if (-not (is_in_git_repo)) { return }

  [string[]]$git_log_args = @(__fzfgit_env_args $env:FZFGIT_GIT_LOG)
  [string[]]$git_show_args = @(__fzfgit_env_args $env:FZFGIT_GIT_SHOW)
  $git_show_options = __fzfgit_pwsh_join $git_show_args
  $preview = "git show --color=always$git_show_options {2} | $($script:__pager__)bat -p --color=always"
  $down_options = get_fzf_down_options
  $cmd_options = @(
    '--prompt', 'Hashes> ',
    "--history=$env:FZF_HIST_DIR/fzf-git_hash",
    '--ansi',
    '--no-sort',
    '--reverse',
    '--delimiter', "`t",
    '--with-nth', '1',
    '--accept-nth', '2',
    '--with-shell', 'pwsh -NoLogo -NoProfile -NonInteractive -Command',
    '--preview', $preview
  )

  [string[]]$selected = git log --date=short --format='%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)%C(reset)%x09%h' --graph --color=always @git_log_args |
    fzf @down_options @cmd_options @args

  return $selected
}

function fgha () {
  if (-not (is_in_git_repo)) { return }

  [string[]]$git_log_args = @(__fzfgit_env_args $env:FZFGIT_GIT_LOG)
  [string[]]$git_show_args = @(__fzfgit_env_args $env:FZFGIT_GIT_SHOW)
  $git_show_options = __fzfgit_pwsh_join $git_show_args
  $preview = "git show --color=always$git_show_options {2} | $($script:__pager__)bat -p --color=always"
  $down_options = get_fzf_down_options
  $cmd_options = @(
    '--prompt', 'All Hashes> ',
    "--history=$env:FZF_HIST_DIR/fzf-git_hash-all",
    '--ansi',
    '--no-sort',
    '--reverse',
    '--delimiter', "`t",
    '--with-nth', '1',
    '--accept-nth', '2',
    '--with-shell', 'pwsh -NoLogo -NoProfile -NonInteractive -Command',
    '--preview', $preview
  )

  [string[]]$selected = git log --all --date=short --format='%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)%C(reset)%x09%h' --graph --color=always @git_log_args |
    fzf @down_options @cmd_options @args

  return $selected
}

function fgr () {
  if (-not (is_in_git_repo)) { return }

  [string[]]$git_remote_args = @(__fzfgit_env_args $env:FZFGIT_GIT_REMOTE)
  [string[]]$git_log_args = @(__fzfgit_env_args $env:FZFGIT_GIT_LOG)
  $git_log_options = __fzfgit_pwsh_join $git_log_args
  $preview = "git log --color=always --oneline --graph --date=short '--pretty=format:%C(auto)%cd%x20%h%d%x20%s'$git_log_options {1}"
  $down_options = get_fzf_down_options
  $cmd_options = @(
    '--prompt', 'Remotes> ',
    "--history=$env:FZF_HIST_DIR/fzf-git_remotes",
    '--tac',
    '--accept-nth', '1',
    '--preview', $preview
  )

  $selected = git remote -v @git_remote_args | ForEach-Object {
    $remote_info = $_ -split "[`t ]"
    return $remote_info[0] + "`t" + $remote_info[1]
  } | Get-Unique |
    fzf @down_options @cmd_options @args

  return $selected
}

function fgs () {
  if (-not (is_in_git_repo)) { return }

  [string[]]$git_stash_args = @(__fzfgit_env_args $env:FZFGIT_GIT_STASH)
  [string[]]$git_show_args = @(__fzfgit_env_args $env:FZFGIT_GIT_SHOW)
  $git_show_options = __fzfgit_pwsh_join $git_show_args
  $preview = "git show --color=always$git_show_options {1} | $($script:__pager__)bat -p --color=always"
  $down_options = get_fzf_down_options
  $cmd_options = @(
    '--prompt', 'Stashes> ',
    "--history=$env:FZF_HIST_DIR/fzf-git_stash",
    '--reverse',
    '--delimiter', ':',
    '--accept-nth', '1',
    '--with-shell', 'pwsh -NoLogo -NoProfile -NonInteractive -Command',
    '--preview', $preview
  )

  [string[]]$selected = git stash list @git_stash_args |
    fzf @down_options @cmd_options @args

  return $selected
}

function fshow () {
  if (-not (is_in_git_repo)) { return }

  [string[]]$git_log_args = @(__fzfgit_env_args $env:FZFGIT_GIT_LOG)
  [string[]]$git_show_args = @(__fzfgit_env_args $env:FZFGIT_GIT_SHOW)
  [string[]]$git_diff_args = @(__fzfgit_env_args $env:FZFGIT_GIT_DIFF)
  $git_log_options = __fzfgit_pwsh_join $git_log_args
  $git_show_options = __fzfgit_pwsh_join $git_show_args
  $git_diff_options = __fzfgit_pwsh_join $git_diff_args

  if (Get-Command delta -ErrorAction SilentlyContinue) {
    $pager = 'delta --paging=always'
    $preview_pager = '| delta'
  } else {
    $pager = 'less -R'
    $preview_pager = ''
  }
  [string[]]$out = @()
  [string[]]$shas = @()
  $q = ''
  $k = ''
  $preview = "
  git show --color=always$git_show_options {2} $preview_pager |
    bat -p --color=always
"

  # Clipboard command
  $copy = 'Get-Content {+f2} | Set-Clipboard'

  $git_base_cmd = "git log --graph --color=always --format='%C(auto)%h%d %s %C(black)%C(bold)%cr%C(reset)%x09%h'"
  $git_current_cmd = "$git_base_cmd$git_log_options"
  $git_all_cmd = "$git_base_cmd --all$git_log_options"
  $down_options = get_fzf_down_options
  $cmd_options = @(
    '--query=',
    "--history=$env:FZF_HIST_DIR/fzf-git_show",
    '--prompt', 'Commits> ',
    '--ansi',
    '--no-sort',
    '--reverse',
    '--delimiter', "`t",
    '--with-nth', '1',
    '--accept-nth', '2',
    '--print-query',
    '--bind', "ctrl-y:execute-silent($copy)+bell",
    '--header', 'ctrl-d: Diff | ctrl-a: All | ctrl-f: HEAD | ctrl-y: Copy',
    '--with-shell', 'pwsh -NoLogo -NonInteractive -NoProfile -Command'
    '--bind', "ctrl-f:reload:$git_current_cmd",
    '--bind', "ctrl-a:reload:$git_all_cmd",
    '--preview', $preview,
    '--preview-window', 'right,50%,wrap-word',
    '--expect=ctrl-d'
  )

  try {
    while ($true) {
      [string[]]$out = @(git log --graph --color=always `
        --format="%C(auto)%h%d %s %C(black)%C(bold)%cr%C(reset)%x09%h" @git_log_args |
          fzf @down_options @cmd_options @args)

      if (-not $out) { break; }

      $q = $out[0]
      $k = if ($out.Count -gt 1) { $out[1] } else { '' }
      [string[]]$shas = if ($out.Count -gt 2) {
        @($out | Select-Object -Skip 2 | Where-Object { $_ })
      } else {
        @()
      }

      if (-not $shas) { continue; }
      if ($q) { $cmd_options[0] = "--query=$q" }
      if ($k -eq 'ctrl-d') {
        pwsh -NoLogo -NonInteractive -NoProfile -Command "git diff --color=always$git_diff_options $shas | $pager"
      } else {
        foreach ($sha in $shas) {
          pwsh -NoLogo -NonInteractive -NoProfile -Command "git show --color=always$git_show_options $sha | $pager"
        }
      }
    }
  } catch { return }
}

function fgl () {
  if (-not (is_in_git_repo)) { return }

  [string[]]$git_reflog_args = @(__fzfgit_env_args $env:FZFGIT_GIT_REFLOG)
  [string[]]$git_show_args = @(__fzfgit_env_args $env:FZFGIT_GIT_SHOW)
  $git_show_options = __fzfgit_pwsh_join $git_show_args
  $down_options = get_fzf_down_options
  $cmd_options = @(
    '--ansi',
    '--prompt', 'Reflogs> ',
    '--bind', 'alt-r:toggle-raw',
    '--with-shell', 'pwsh -NoLogo -NoProfile -NonInteractive -Command',
    '--preview', "git show --color=always$git_show_options {1} | delta",
    '--accept-nth', '1'
  )

  [string[]]$selected = git reflog --color=always --format='%C(blue)%gD %C(yellow)%h%C(auto)%d %gs' @git_reflog_args |
    fzf @down_options @cmd_options @args

  return $selected
}

function fgw () {
  if (-not (is_in_git_repo)) { return }

  [string[]]$git_worktree_args = @(__fzfgit_env_args $env:FZFGIT_GIT_WORKTREE)
  [string[]]$git_status_args = @(__fzfgit_env_args $env:FZFGIT_GIT_STATUS)
  [string[]]$git_log_args = @(__fzfgit_env_args $env:FZFGIT_GIT_LOG)
  $git_worktree_options = __fzfgit_pwsh_join $git_worktree_args
  $git_status_options = __fzfgit_pwsh_join $git_status_args
  $git_log_options = __fzfgit_pwsh_join $git_log_args
  $preview = @"
git -c color.status=always -C {1} status --short --branch$git_status_options
Write-Output ''
git log --oneline --graph --date=short --color=always '--pretty=format:%C(auto)%cd%x20%h%d%x20%s'$git_log_options {2} --
"@
  $down_options = get_fzf_down_options
  $cmd_options = @(
    '--prompt', 'Worktrees> ',
    '--header', 'CTRL-X (remove worktree) | ALT-T ',
    '--with-shell', 'pwsh -NoLogo -NoProfile -NonInteractive -Command',
    '--bind', "ctrl-x:reload(git worktree remove {1} > `$null; git worktree list$git_worktree_options)",
    '--preview', $preview,
    '--accept-nth', '1',
    '--with-nth', '2..',
    '--bind', 'alt-t:change-with-nth(..|2..)'
  )

  [string[]]$selected = git worktree list @git_worktree_args |
    fzf @down_options @cmd_options @args

  return $selected
}

function fge () {
  if (-not (is_in_git_repo)) { return }

  [string[]]$git_log_args = @(__fzfgit_env_args $env:FZFGIT_GIT_LOG)
  $git_log_options = __fzfgit_pwsh_join $git_log_args

  # Reload actions run in a child shell, so give them a self-contained helper.
  $refs_file = New-TemporaryFile
  $refs_script = $refs_file.FullName.Replace('.tmp', '.ps1')
  $env_args_function = (Get-Command __fzfgit_env_args -CommandType Function).Definition
  $refs_function = (Get-Command __git_refs -CommandType Function).Definition
  @"
function __fzfgit_env_args () {
$env_args_function
}
function __git_refs () {
$refs_function
}
__git_refs @args
"@ | Set-Content -Path $refs_script -Encoding utf8

  $escaped_refs_script = $refs_script.Replace("'", "''")
  $reload_refs = "& '$escaped_refs_script'"
  $preview = "git log --oneline --graph --date=short --color=always '--pretty=format:%C(auto)%cd%x20%h%d%x20%s'$git_log_options {2} --"
  $down_options = get_fzf_down_options
  $cmd_options = @(
    '--ansi',
    '--delimiter', "`t",
    '--nth', '2,2..',
    '--tiebreak', 'begin',
    '--prompt', 'Each ref> ',
    '--header-lines', '1',
    '--preview-window', 'down,border-top,40%',
    '--color', 'hl:underline,hl+:underline',
    '--no-hscroll',
    '--with-shell', 'pwsh -NoLogo -NoProfile -NonInteractive -Command',
    '--bind', 'ctrl-/:change-preview-window(down,70%|hidden|)',
    '--bind', "ctrl-f:change-prompt(Every ref> )+reload:$reload_refs",
    '--bind', "ctrl-r:change-prompt(Each ref> )+reload:$reload_refs '--exclude=refs/remotes'",
    '--preview', $preview,
    '--accept-nth', '2'
  )

  try {
    [string[]]$selected = __git_refs '--exclude=refs/remotes' |
      fzf @down_options @cmd_options @args

    return $selected
  } finally {
    if (Test-Path -Path $refs_file.FullName -PathType Leaf -ErrorAction SilentlyContinue) {
      Remove-Item -Force $refs_file.FullName
    }
    if (Test-Path -Path $refs_script -PathType Leaf -ErrorAction SilentlyContinue) {
      Remove-Item -Force $refs_script
    }
  }
}

# Export-ModuleMember -Function fgb

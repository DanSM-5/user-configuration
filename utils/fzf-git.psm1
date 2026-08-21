# GIT heart FZF
# -------------
# Powershell version
# because using pipes with cmdlets break string encoding for formatted output

# Ref: https://gist.github.com/junegunn/8b572b8d4b5eddd8b85e5f4d40f17236

# TODO: Update fzf commands to use `--with-shell` rather
# than generating temporary powershell scripts

function is_in_git_repo () {
  if (git rev-parse HEAD 2> $null) { return $true } else { return $false }
}

$__pager__ = if (Get-Command -Name delta -All -ErrorAction 0) { 'delta | ' } else { '' }

$user_conf_path = if ($env:user_conf_path) { $env:user_conf_path } else { "$HOME/.usr_conf" }
$path_preview_script = Join-Path $user_conf_path "utils/fzf-preview.ps1"

function __git_refs () {
  $format = "%(if:equals=refs/remotes)%(refname:rstrip=-2)%(then)%(color:magenta)remote-branch%(else)%(if:equals=refs/heads)%(refname:rstrip=-2)%(then)%(color:brightgreen)branch%(else)%(if:equals=refs/tags)%(refname:rstrip=-2)%(then)%(color:brightcyan)tag%(else)%(if:equals=refs/stash)%(refname:rstrip=-2)%(then)%(color:brightred)stash%(else)%(color:white)%(refname:rstrip=-2)%(end)%(end)%(end)%(end)`t%(color:yellow)%(refname:short) %(color:green)(%(creatordate:relative))`t%(color:blue)%(subject)%(color:reset)"
  $lines = @(git for-each-ref @args `
    --sort=-creatordate --sort=-HEAD --color=always `
    "--format=$format")

  if (-not $lines) { return }

  # Match `column -t` without requiring Unix utilities on Windows.
  $ansi_pattern = '\x1B\[[0-?]*[ -/]*[@-~]'
  $rows = @($lines | ForEach-Object {
    $fields = $_ -split "`t", 3
    [PSCustomObject]@{
      First = $fields[0]
      FirstLength = ($fields[0] -replace $ansi_pattern, '').Length
      Second = $fields[1]
      SecondLength = ($fields[1] -replace $ansi_pattern, '').Length
      Third = $fields[2]
    }
  })

  $first_width = ($rows | Measure-Object -Property FirstLength -Maximum).Maximum
  $second_width = ($rows | Measure-Object -Property SecondLength -Maximum).Maximum

  $rows | ForEach-Object {
    $first_padding = [string]::new([char]' ', $first_width - $_.FirstLength + 2)
    $second_padding = [string]::new([char]' ', $second_width - $_.SecondLength + 2)
    "$($_.First)$first_padding$($_.Second)$second_padding$($_.Third)"
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

  $query = "$args"
  $preview_file = New-TemporaryFile
  @"
    if (Test-Path -Path `$args -PathType Leaf -ErrorAction SilentlyContinue) {
      git diff --color=always -- `$args |
        Select-Object -Skip 4 | $script:__pager__
        bat -p --color=always;
      Write-Output "";
    }
    $path_preview_script `$args;
"@ > $preview_file.FullName

  $preview = if ($IsWindows) {
    "pwsh -NoProfile -NoLogo -NonInteractive -Command Invoke-Command -ScriptBlock ([scriptblock]::Create((Get-Content `""+ $preview_file.FullName + "`"))) -ArgumentList '{2..}'"
  } else {
    "pwsh -NoProfile -NoLogo -NonInteractive -Command 'Invoke-Command -ScriptBlock ([scriptblock]::Create((Get-Content `""+ $preview_file.FullName + "`"))) -ArgumentList {2..}'"
  }

  $down_options = get_fzf_down_options
  $cmd_options = @(
    "--query=$query",
    '--prompt', 'Files> ',
    "--history=$env:FZF_HIST_DIR/fzf-git_file",
    '--preview-window', '60%,wrap-word',
    '--ansi',
    '--nth', '2..,..',
    '--accept-nth', '2..',
    '--preview', $preview
  )

  try {
    [string[]]$selected = git -c color.status=always status --short |
      fzf @down_options @cmd_options | ForEach-Object {
        $file_name = $_ -replace '.* -> ', '' # Remove old name when renaming
        $file_name.Trim().Trim('"').Trim("'")
      }

    return $selected
  } finally {
    if (Test-Path -Path $preview_file.FullName -PathType Leaf -ErrorAction SilentlyContinue) {
      Remove-Item -Force $preview_file.FullName
    }
  }
}

function fgb () {
  if (-not (is_in_git_repo)) { return }

  $query = "$args"
  $preview_file = New-TemporaryFile
  @"
    try {
      `$clean_content = `$args | ForEach-Object {
        `$branch = `$_ -replace '^..',''
        `$branch = (`$branch -split ' ')[0]
        return `$branch
      }
      git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" `$clean_content
    } catch {
      Write-Error 'Cannot preview'
    }
"@ > $preview_file.FullName
  $preview_script = $preview_file.FullName.Replace('.tmp', '.ps1')
  Copy-Item $preview_file.FullName $preview_script

  $preview = "pwsh -NoProfile -NoLogo -NonInteractive -File `"$preview_script`" {}"
  $down_options = get_fzf_down_options
  $cmd_options = @(
    "--query=$query",
    '--prompt', 'Branches> ',
    "--history=$env:FZF_HIST_DIR/fzf-git_branch",
    '--ansi',
    '--tac',
    '--preview-window', 'right,70%,wrap-word',
    '--preview', $preview
  )


  try {
    [string[]]$selected = git branch -a --color=always | ForEach-Object {
        if ($_ -NotMatch '/HEAD\s') {
          return $_
        }
      } | Sort-Object |
      fzf @down_options @cmd_options | ForEach-Object {
        $branch = $_ -replace '^..',''
        $branch = ($branch -split ' ')[0]
        $branch -replace '^remotes\/', ''
      }

    return $selected
  } finally {
    if (Test-Path -Path $preview_file.FullName -PathType Leaf -ErrorAction SilentlyContinue) {
      Remove-Item -Force $preview_file.FullName
    }
    if (Test-Path -Path $preview_script -PathType Leaf -ErrorAction SilentlyContinue) {
      Remove-Item -Force $preview_script
    }
  }
}

function fgt () {
  if (-not (is_in_git_repo)) { return }

  $query = "$args"
  $preview_file = New-TemporaryFile
  @"
    git show --color=always `$args |
    $script:__pager__ bat -p --color=always
"@ > $preview_file.FullName

  $preview = if ($IsWindows) {
    "pwsh -NoProfile -NoLogo -NonInteractive -Command Invoke-Command -ScriptBlock ([scriptblock]::Create((Get-Content `""+ $preview_file.FullName + "`"))) -ArgumentList {}"
  } else {
    "pwsh -NoProfile -NoLogo -NonInteractive -Command 'Invoke-Command -ScriptBlock ([scriptblock]::Create((Get-Content `""+ $preview_file.FullName + "`"))) -ArgumentList {}'"
  }
  $down_options = get_fzf_down_options
  $cmd_options = @(
    "--query=$query",
    '--prompt', 'Tags> ',
    "--history=$env:FZF_HIST_DIR/fzf-git_tag",
    '--preview-window', 'right,70%,wrap-word',
    '--preview', $preview
  )

  try {
    $selected = git tag --sort -version:refname |
      fzf @down_options @cmd_options

    return $selected
  } finally {
    if (Test-Path -Path $preview_file.FullName -PathType Leaf -ErrorAction SilentlyContinue) {
      Remove-Item -Force $preview_file.FullName
    }
  }
}

function fgh () {
  if (-not (is_in_git_repo)) { return }

  $placeholder = if ($IsWindows) {
    "'{}'"
  } else {
    '{}'
  }

  $query = "$args"
  $content_file = New-Temporaryfile
  $preview_file = New-Temporaryfile
  @"
    `$args > $($content_file.FullName);
    `$hash = if (`$`(Get-Content $($content_file.FullName)`) -match "[a-f0-9]{7,}") {
      `$matches[0]
    } else { @() }
    git show --color=always `$hash |
      $script:__pager__ bat -p --color=always
"@ > $preview_file.FullName
  $preview_script = $preview_file.FullName.Replace('.tmp', '.ps1')
  Copy-Item $preview_file.FullName $preview_script

  $preview = "pwsh -NoProfile -NoLogo -NonInteractive -File `"$preview_script`" $placeholder"
  $down_options = get_fzf_down_options
  $cmd_options = @(
    "--query=$query",
    '--prompt', 'Hashes> ',
    "--history=$env:FZF_HIST_DIR/fzf-git_hash",
    '--ansi',
    '--no-sort',
    '--reverse',
    '--preview', $preview
  )

  try {
    [string[]]$selected = git log --date=short --format='%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)' --graph --color=always |
      fzf @down_options @cmd_options | ForEach-Object {
        if ($_ -match "[a-f0-9]{7,}") {
          return $matches[0]
        }
      }

    # grep -o "[a-f0-9]\{7,\}"
    return $selected
  } finally {
    if (Test-Path -Path $preview_file.FullName -PathType Leaf -ErrorAction SilentlyContinue) {
      Remove-Item -Force $preview_file.FullName
    }
    if (Test-Path -Path $preview_script -PathType Leaf -ErrorAction SilentlyContinue) {
      Remove-Item -Force $preview_script
    }
    if (Test-Path -Path $content_file.FullName -PathType Leaf -ErrorAction SilentlyContinue) {
      Remove-Item -Force $content_file.FullName
    }
  }
}

function fgha () {
  if (-not (is_in_git_repo)) { return }

  $placeholder = if ($IsWindows) {
    "'{}'"
  } else {
    '{}'
  }

  $query = "$args"
  $content_file = New-Temporaryfile
  $preview_file = New-Temporaryfile
  @"
    `$args > $($content_file.FullName);
    `$hash = if (`$`(Get-Content $($content_file.FullName)`) -match "[a-f0-9]{7,}") {
      `$matches[0]
    } else { @() }
    git show --color=always `$hash |
      $script:__pager__ bat -p --color=always
"@ > $preview_file.FullName
  $preview_script = $preview_file.FullName.Replace('.tmp', '.ps1')
  Copy-Item $preview_file.FullName $preview_script

  $preview = "pwsh -NoProfile -NoLogo -NonInteractive -File `"$preview_script`" $placeholder"
  $down_options = get_fzf_down_options
  $cmd_options = @(
    "--query=$query",
    '--prompt', 'All Hashes> ',
    "--history=$env:FZF_HIST_DIR/fzf-git_hash-all",
    '--ansi',
    '--no-sort',
    '--reverse',
    '--preview', $preview
  )

  try {
    [string[]]$selected = git log --all --date=short --format='%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)' --graph --color=always |
      fzf @down_options @cmd_options | ForEach-Object {
        if ($_ -match "[a-f0-9]{7,}") {
          return $matches[0]
        }
      }
      # grep -o "[a-f0-9]\{7,\}"

    return $selected
  } finally {
    if (Test-Path -Path $preview_file.FullName -PathType Leaf -ErrorAction SilentlyContinue) {
      Remove-Item -Force $preview_file.FullName
    }
    if (Test-Path -Path $preview_script -PathType Leaf -ErrorAction SilentlyContinue) {
      Remove-Item -Force $preview_script
    }
    if (Test-Path -Path $content_file.FullName -PathType Leaf -ErrorAction SilentlyContinue) {
      Remove-Item -Force $content_file.FullName
    }
  }
}

function fgr () {
  if (-not (is_in_git_repo)) { return }

  $preview = 'git log --color=always --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" {1}'
  $down_options = get_fzf_down_options
  $cmd_options = @(
    "--query=$query",
    '--prompt', 'Remotes> ',
    "--history=$env:FZF_HIST_DIR/fzf-git_remotes",
    '--tac',
    '--accept-nth', '1',
    '--preview', $preview
  )

  $selected = git remote -v | ForEach-Object {
    $remote_info = $_ -split "[`t ]"
    return $remote_info[0] + "`t" + $remote_info[1]
  } | Get-Unique |
    fzf @down_options @cmd_options

  return $selected
}

function fgs () {
  if (-not (is_in_git_repo)) { return }

  $query = "$args"
  $preview_file = New-Temporaryfile
  @"
    git show --color=always `$args |
      $script:__pager__ bat -p --color=always
"@ > $preview_file.FullName
  $preview_script = $preview_file.FullName.Replace('.tmp', '.ps1')
  Copy-Item $preview_file.FullName $preview_script

  $preview = "pwsh -NoProfile -NoLogo -NonInteractive -File `"$preview_script`" {1}"
  $down_options = get_fzf_down_options
  $cmd_options = @(
    "--query=$query",
    '--prompt', 'Stashes> ',
    "--history=$env:FZF_HIST_DIR/fzf-git_stash",
    '--reverse',
    '--delimiter', ':',
    '--accept-nth', '1',
    '--preview', $preview
  )

  try {
    [string[]]$selected = git stash list |
      fzf @down_options @cmd_options

    return $selected
  } finally {
    if (Test-Path -Path $preview_file.FullName -PathType Leaf -ErrorAction SilentlyContinue) {
      Remove-Item -Force $preview_file.FullName
    }
    if (Test-Path -Path $preview_script -PathType Leaf -ErrorAction SilentlyContinue) {
      Remove-Item -Force $preview_script
    }
  }
}

function fshow () {
  if (-not (is_in_git_repo)) { return }

  if (Get-Command delta -ErrorAction SilentlyContinue) {
    $pager = 'delta --paging=always'
    $preview_pager = '| delta'
  } else {
    $pager = 'less -R'
    $preview_pager = ''
  }
  $content_file = New-Temporaryfile
  $out = ''
  $shas = ''
  $q = ''
  $k = ''
  $preview = "
  `$var = @'
{}
'@
  `$var = `$var.Trim().Trim(`"'`").Trim('`"')
  `$hash = if (`$var -match `"[a-f0-9]{7,}`") {
    `$matches[0]
  } else { @() }
  git show --color=always `$hash $preview_pager |
    bat -p --color=always
"

  # Clipboard command
  $copy = 'Get-Content {+f} | ForEach-Object { ($_ -Split "\s+")[1] } | Set-Clipboard'

  $git_base_cmd = "git log --graph --color=always --format='%C(auto)%h%d %s %C(black)%C(bold)%cr'"
  $git_current_cmd = "$git_base_cmd $args"
  $git_all_cmd = "$git_base_cmd --all $args"
  $down_options = get_fzf_down_options
  $cmd_options = @(
    '--query=',
    "--history=$env:FZF_HIST_DIR/fzf-git_show",
    '--prompt', 'Commits> ',
    '--ansi',
    '--no-sort',
    '--reverse',
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
      $out = git log --graph --color=always `
        --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" @args |
          fzf @down_options @cmd_options

      if (-not $out) { break; }

      $out > $content_file.FullName
      $q = Get-Content $content_file.FullName | Select-Object -Index 0
      $k = Get-Content $content_file.FullName | Select-Object -Index 1
      $shas = Get-Content $content_file.FullName | Select-Object -Skip 2 | ForEach-Object {
        if ($_ -match "[a-f0-9]{7,}") {
          return $matches[0]
        }
      }

      if (-not $shas) { continue; }
      if ($q) { $cmd_options[0] = "--query=$q" }
      if ($k -eq 'ctrl-d') {
        pwsh -NoLogo -NonInteractive -NoProfile -Command "git diff --color=always $shas | $pager"
      } else {
        foreach ($sha in $shas) {
          pwsh -NoLogo -NonInteractive -NoProfile -Command "git show --color=always $sha | $pager"
        }
      }
    }
  } catch {
    if (Test-Path -Path $content_file.FullName -PathType Leaf -ErrorAction SilentlyContinue) {
      Remove-Item -Force $content_file.FullName
    }
  }
}

function fgl () {
  if (-not (is_in_git_repo)) { return }

  $down_options = get_fzf_down_options
  $cmd_options = @(
    '--ansi',
    '--prompt', 'Reflogs> ',
    '--bind', 'alt-r:toggle-raw',
    '--with-shell', 'pwsh -NoLogo -NoProfile -NonInteractive -Command',
    '--preview', 'git show --color=always {1} | delta',
    '--accept-nth', '1'
  )

  [string[]]$selected = git reflog --color=always --format='%C(blue)%gD %C(yellow)%h%C(auto)%d %gs' |
    fzf @down_options @cmd_options @args

  return $selected
}

function fgw () {
  if (-not (is_in_git_repo)) { return }

  $preview = @'
git -c color.status=always -C {1} status --short --branch
Write-Output ''
git log --oneline --graph --date=short --color=always --pretty=format:%C(auto)%cd%x20%h%d%x20%s {2} --
'@
  $down_options = get_fzf_down_options
  $cmd_options = @(
    '--prompt', 'Worktrees> ',
    '--header', 'CTRL-X (remove worktree) | ALT-T ',
    '--with-shell', 'pwsh -NoLogo -NoProfile -NonInteractive -Command',
    '--bind', 'ctrl-x:reload(git worktree remove {1} > $null; git worktree list)',
    '--preview', $preview,
    '--accept-nth', '1',
    '--with-nth', '2..',
    '--bind', 'alt-t:change-with-nth(..|2..)'
  )

  [string[]]$selected = git worktree list |
    fzf @down_options @cmd_options @args

  return $selected
}

function fge () {
  if (-not (is_in_git_repo)) { return }

  # Reload actions run in a child shell, so give them a self-contained helper.
  $refs_file = New-TemporaryFile
  $refs_script = $refs_file.FullName.Replace('.tmp', '.ps1')
  $refs_function = (Get-Command __git_refs -CommandType Function).Definition
  @"
function __git_refs () {
$refs_function
}
__git_refs @args
"@ | Set-Content -Path $refs_script -Encoding utf8

  $escaped_refs_script = $refs_script.Replace("'", "''")
  $reload_refs = "& '$escaped_refs_script'"
  $preview = 'git log --oneline --graph --date=short --color=always --pretty=format:%C(auto)%cd%x20%h%d%x20%s {2} --'
  $down_options = get_fzf_down_options
  $cmd_options = @(
    '--ansi',
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

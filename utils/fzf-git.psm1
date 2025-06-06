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

function get_fzf_down_options() {
  $options = @(
    '--height', '80%',
    '--min-height', '20',
    '--input-border',
    '--cycle',
    '--layout=reverse',
    '--multi',
    '--border',
    '--preview-window', 'right,50%,wrap',
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
    '--preview-window', '60%,wrap',
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
    '--preview-window', 'right,70%,wrap',
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
    '--preview-window', 'right,70%,wrap',
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
    '--preview-window', 'right,50%,wrap',
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

# Export-ModuleMember -Function fgb


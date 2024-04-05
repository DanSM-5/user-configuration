# GIT heart FZF
# -------------
# Powershell version (requires coreutils grep, sed, awk, cut, less)
# because using pipes with cmdlets break string encoding for formatted output

# Ref: https://gist.github.com/junegunn/8b572b8d4b5eddd8b85e5f4d40f17236

function is_in_git_repo () {
  if (git rev-parse HEAD 2> $null) { return $true } else { return $false }
}

$__pager__ = if (Test-Command delta) { 'delta | ' } else { '' }

function get_fzf_down_options() {
  $options = @(
    '--height', '50%',
    '--min-height', '20',
    '--layout=reverse',
    '--border',
    '--bind', 'ctrl-/:change-preview-window(down|hidden|)',
    '--bind', 'alt-up:preview-page-up',
    '--bind', 'alt-down:preview-page-down',
    '--bind', 'ctrl-s:toggle-sort'
  )

  return $options
}

function fgf () {
  if ($script:is_in_git_repo) { return }

  $preview_file = New-TemporaryFile
  @"
    if (Test-Path -Path `$args -PathType Leaf -ErrorAction SilentlyContinue) {
      git diff --color=always -- `$args |
        $script:__pager__ sed '1,4d' |
        bat -p --color=always;
      bat -p --color=always `$args
    } else {
      if (Get-Command erd -ErrorAction SilentlyContinue) {
        erd --layout inverted --color force --level 3 -I --suppress-size -- `$args
      } else {
        Get-ChildItem `$args
      }
    }
"@ > $preview_file.FullName

  # NOTE: The above command uses sed '1,4d' instead of
  # $script:__pager__ Select-Object -Skip 4 |
  # because powershell cmdlets break encoding

  $preview = "pwsh -NoProfile -NoLogo -NonInteractive -Command Invoke-Command -ScriptBlock ([scriptblock]::Create((Get-Content '"+ $preview_file.FullName + "'))) -ArgumentList '{-1}'"
  # '--preview', 'pwsh -NoLogo -NonInteractive -NoProfile '
  $down_options = get_fzf_down_options
  $cmd_options = @(
    '--multi',
    '--ansi',
    '--nth', '2..,..',
    '--preview', $preview
  )

  try {
    $selected = git -c color.status=always status --short |
      fzf @down_options @cmd_options |
      cut -c4- | sed 's/.* -> //'

    return $selected
  } finally {
    if (Test-Path -Path $preview_file.FullName -PathType Leaf -ErrorAction SilentlyContinue) {
      Remove-Item -Force $preview_file.FullName
    }
  }
}

function fgb () {
  if ($script:is_in_git_repo) { return }

  $preview_file = New-TemporaryFile
  @"
    `$content_file = New-TemporaryFile;
    `$args > `$content_file.FullName;
    try {
      `$clean_content = sed 's/^..//' `$content_file.FullName | cut -d' ' -f1;
      git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" `$clean_content
    } finally {
      if (Test-Path -Path `$content_file.FullName -PathType Leaf -ErrorAction SilentlyContinue) {
        Remove-Item -Force `$content_file.FullName
      }
    }
"@ > $preview_file.FullName

  $preview = "pwsh -NoProfile -NoLogo -NonInteractive -Command Invoke-Command -ScriptBlock ([scriptblock]::Create((Get-Content '"+ $preview_file.FullName + "'))) -ArgumentList '{}'"
  # '--preview', 'pwsh -NoLogo -NonInteractive -NoProfile '
  $down_options = get_fzf_down_options
  $cmd_options = @(
    '--multi',
    '--ansi',
    '--tac'
    '--preview', $preview
  )


  try {
    $selected = git branch -a --color=always | grep -v '/HEAD\s' | sort |
      fzf @down_options @cmd_options |
      sed 's/^..//' | cut -d' ' -f1 |
      sed 's#^remotes##'

    return $selected
  } finally {
    if (Test-Path -Path $preview_file.FullName -PathType Leaf -ErrorAction SilentlyContinue) {
      Remove-Item -Force $preview_file.FullName
    }
  }
}

function fgt () {
  if ($script:is_in_git_repo) { return }

  $preview_file = New-TemporaryFile
  @"
    git show --color=always `$args |
    $script:__pager__ bat -p --color=always
"@ > $preview_file.FullName

  $preview = "pwsh -NoProfile -NoLogo -NonInteractive -Command Invoke-Command -ScriptBlock ([scriptblock]::Create((Get-Content '"+ $preview_file.FullName + "'))) -ArgumentList '{}'"
  $down_options = get_fzf_down_options
  $cmd_options = @(
    '--multi',
    '--preview-window', 'right:70%',
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
  if ($script:is_in_git_repo) { return }

  $preview_file = New-Temporaryfile
  @"
    `$content_file = New-Temporaryfile;
    `$args > `$content_file.FullName;
    try {
      `$hash = grep -o "[a-f0-9]\{7,\}" `$content_file.FullName;
      git show --color=always `$hash |
        $script:__pager__ bat -p --color=always
    } finally {
      if (Test-Path -Path `$content_file.FullName -PathType Leaf -ErrorAction SilentlyContinue) {
        Remove-Item -Force `$content_file.FullName
      }
    }
"@ > $preview_file.FullName
  $preview_script = $preview_file.FullName.Replace('.tmp', '.ps1')
  Copy-Item $preview_file.FullName $preview_script

  $preview = "pwsh -NoProfile -NoLogo -NonInteractive -File $preview_script '{}'"
  $down_options = get_fzf_down_options
  $cmd_options = @(
    '--ansi',
    '--no-sort',
    '--reverse',
    '--multi',
    '--preview', $preview
  )

  try {
    $selected = git log --date=short --format='%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)' --graph --color=always |
      fzf @down_options @cmd_options |
      grep -o "[a-f0-9]\{7,\}"

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

function fgha () {
  if ($script:is_in_git_repo) { return }

  $preview_file = New-Temporaryfile
  @"
    `$content_file = New-Temporaryfile;
    `$args > `$content_file.FullName;
    try {
      `$hash = grep -o "[a-f0-9]\{7,\}" `$content_file.FullName;
      git show --color=always `$hash |
        $script:__pager__ bat -p --color=always
    } finally {
      if (Test-Path -Path `$content_file.FullName -PathType Leaf -ErrorAction SilentlyContinue) {
        Remove-Item -Force `$content_file.FullName
      }
    }
"@ > $preview_file.FullName
  $preview_script = $preview_file.FullName.Replace('.tmp', '.ps1')
  Copy-Item $preview_file.FullName $preview_script

  $preview = "pwsh -NoProfile -NoLogo -NonInteractive -File $preview_script '{}'"
  $down_options = get_fzf_down_options
  $cmd_options = @(
    '--ansi',
    '--no-sort',
    '--reverse',
    '--multi',
    '--preview', $preview
  )

  try {
    $selected = git log --all --date=short --format='%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)' --graph --color=always |
      fzf @down_options @cmd_options |
      grep -o "[a-f0-9]\{7,\}"

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

function fgr () {
  if ($script:is_in_git_repo) { return }

  $preview = 'git log --color=always --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" {1}'
  $down_options = get_fzf_down_options
  $cmd_options = @(
    '--tac',
    '--preview', $preview
  )

  # NOTE: not sure how to add tab delimiter for cut, so it is left without it
  # because tab is the default delimiter
  $selected = git remote -v | awk '{print $1 "\t" $2}' | uniq |
    fzf @down_options @cmd_options |
    cut -f1 # -d$'\t'

  return $selected
}

function fgs () {
  if ($script:is_in_git_repo) { return }

  $preview_file = New-Temporaryfile
  @"
    git show --color=always `$args |
      $script:__pager__ bat -p --color=always
"@ > $preview_file.FullName
  # $preview_script = $preview_file.FullName.Replace('.tmp', '.ps1')
  # Copy-Item $preview_file.FullName $preview_script

  $preview = "pwsh -NoProfile -NoLogo -NonInteractive -Command Invoke-Command -ScriptBlock ([scriptblock]::Create((Get-Content '"+ $preview_file.FullName + "'))) -ArgumentList '{}'"
  # $preview = "pwsh -NoProfile -NoLogo -NonInteractive -File $preview_script '{}'"
  $down_options = get_fzf_down_options
  $cmd_options = @(
    '--reverse',
    '--delimiter', ':',
    '--preview', $preview
  )

  try {
    $selected = git stash list |
      fzf @down_options @cmd_options |
      cut -d':' -f1

    return $selected
  } finally {
    if (Test-Path -Path $preview_file.FullName -PathType Leaf -ErrorAction SilentlyContinue) {
      Remove-Item -Force $preview_file.FullName
    }
    # if (Test-Path -Path $preview_script -PathType Leaf -ErrorAction SilentlyContinue) {
    #   Remove-Item -Force $preview_script
    # }
  }
}

function fshow () {
  if ($script:is_in_git_repo) { return }

  $pager = if (Get-Command delta -ErrorAction SilentlyContinue) {
    'delta --paging=always'
  } else {
    'less -R'
  }
  $content_file = New-Temporaryfile
  $out = ''
  $shas = ''
  $q = ''
  $k = ''

  $down_options = get_fzf_down_options
  $cmd_options = @(
    '--query=',
    '--ansi',
    '--multi',
    '--no-sort',
    '--reverse',
    '--print-query',
    '--expect=ctrl-d'
  )

  try {
    while ($true) {
      $out = git log --graph --color=always `
        --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" @args |
          fzf @down_options @cmd_options

      if (-not $out) { break; }

      $out > $content_file.FullName
      $q = head -1 $content_file.FullName
      $k = head -2 $content_file.FullName | tail -1
      $shas = sed '1,2d;s/^[^a-z0-9]*//;/^$/d' $content_file.FullName | awk '{print $1}'

      if (-not $shas) { continue; }
      if ($q) { $cmd_options[0] = "--query=$q" }
      if ($k -eq 'ctrl-d') {
        pwsh -NoLogo -NonInteractive -NoProfile -Command "git show --color=always $shas | $pager"
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

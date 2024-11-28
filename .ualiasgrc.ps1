
############################################
#      GENERAL FUNCTIONS AND ALIASES       #
############################################

# Follow structure conf folders and files
$user_conf_path = if ($env:user_conf_path) { $env:user_conf_path } else { "${HOME}${dirsep}.usr_conf" }
$user_scripts_path = if ($env:user_scripts_path) { $env:user_scripts_path } else { "${HOME}${dirsep}user-scripts" }
$prj = if ($env:prj) { $env:prj } else { "${HOME}${dirsep}prj" }
$user_config_cache = if ($env:user_config_cache) { $env:user_config_cache } else { "${HOME}${dirsep}.cache${dirsep}.user_config_cache" }

$env:PREFERRED_EDITOR = if ($env:PREFERRED_EDITOR) { $env:PREFERRED_EDITOR } else { "vim" }

# Dot sourcing function scripts
# TODO: Loop through files and source them
# E.G. Get-ChildItem -Path utils | Where { $_.Name -Like 'function-*.ps1' }
. "${env:user_conf_path}${dirsep}utils${dirsep}function-Out-HostColored.ps1"
# . "${env:user_conf_path}${dirsep}utils${dirsep}function-With-Env.ps1"
. "${env:user_conf_path}${dirsep}utils${dirsep}function-New-CommandWrapper.ps1"


if (Test-Path Alias:wenv) { Remove-Item Alias:wenv }
Set-Alias -Name wenv -Value With-Env

# Script called from function
function pimg () { & "${env:user_conf_path}${dirsep}utils${dirsep}paste-image.ps1" @args }

function gpr { Set-Location $env:prj }
function gus { Set-Location $env:user_scripts_path }
function guc { Set-Location $env:user_conf_path }
function gvc { Set-Location "${HOME}${dirsep}vim-config" }
# function gvc { Set-Location "${HOME}${dirsep}.SpaceVim.d" }
function goh { Set-Location "$HOME"}

function epf { nvim $PROFILE }
function ecf { nvim "$(Join-Path -Path $env:user_conf_path -ChildPath .uconfrc.ps1)" }
function egc { nvim "$(Join-Path -Path $env:user_conf_path -ChildPath .uconfgrc.ps1)" }
function eal { nvim "$(Join-Path -Path $env:user_conf_path -ChildPath .ualiasrc.ps1)" }
function ega { nvim "$(Join-Path -Path $env:user_conf_path -ChildPath .ualiasgrc.ps1)" }
function evc { nvim "$(Join-Path -Path $HOME -ChildPath "vim-config${dirsep}vimstart.vim")" }
# function evc { nvim "$(Join-Path -Path $HOME -ChildPath ".SpaceVim.d${dirsep}init.toml")" }

$fzfPreviewScript = Join-Path -Path $env:user_conf_path -ChildPath "utils${dirsep}fzf-preview.ps1"
$fzf_preview_normal = ("pwsh -NoProfile -NonInteractive -NoLogo -File `"$fzfPreviewScript`"" + " \""" + '.' + "\"" {}")

function getPsFzfOptions {
  # $path = $PWD.ProviderPath.Replace('\', '/')
  $psFzfOptions = @{
    # Preview = $("pwsh -NoProfile -NonInteractive -NoLogo -File \""$fzfPreviewScript\"" \""" + $path + "\"" {}" );
    Preview = $fzf_preview_normal
    Bind = @(
      'ctrl-^:toggle-preview',
      'ctrl-/:change-preview-window(down|hidden|)',
      'alt-up:preview-page-up',
      'alt-down:preview-page-down',
      'ctrl-s:toggle-sort',
      'alt-f:first',
      'alt-l:last',
      'alt-c:clear-query'
    )
    Height = '80%'
    MinHeight = 20
    Border = $true
    Info = 'inline'
    PreviewWindow = '60%'
  }
  return $psFzfOptions
}

function getFzfOptions () {
  # $path = $PWD.ProviderPath.Replace('\', '/')
  # $fzfPreviewScript = Join-Path -Path $env:user_conf_path -ChildPath "utils${dirsep}fzf-preview.ps1"
  # $preview = ("pwsh -NoProfile -NonInteractive -NoLogo -File `"$fzfPreviewScript`"" + " \""" + $path + "\"" {}")

  $options = @(
    '--bind', 'ctrl-^:toggle-preview',
    '--bind', 'ctrl-/:change-preview-window(down|hidden|)',
    '--bind', 'alt-up:preview-page-up',
    '--bind', 'alt-down:preview-page-down',
    '--bind', 'ctrl-s:toggle-sort',
    '--bind', 'alt-f:first',
    '--bind', 'alt-l:last',
    '--bind', 'alt-c:clear-query',
    '--preview-window', '60%',
    # '--preview', $preview,
    '--preview', $fzf_preview_normal,
    '--height', '80%',
    '--min-height', '20',
    '--info=inline',
    '--border'
  )

  return $options
}

function getFzfPreview ([string] $ScriptContent = 'Get-Content $args') {
  try {
    $preview_file = New-Temporaryfile
    $ScriptContent > $preview_file.FullName
    $preview_script = $preview_file.FullName.Replace('.tmp', '.ps1')
    $fzf_preview = "pwsh -NoProfile -NoLogo -NonInteractive -File `"$preview_script`""
    Copy-Item $preview_file.FullName $preview_script

    $preview_options = @{
      preview = $fzf_preview
      file = $preview_script
    }

    return $preview_options
  } finally {
    if (Test-Path -Path $preview_file.FullName -PathType Leaf -ErrorAction SilentlyContinue) {
      Remove-Item -Force $preview_file.FullName
    }
  }
}

function fd-Excluded {
  $exclusionArr = @(Get-Content "$user_conf_path\fzf\fd_exclude" ; Get-Content "$user_conf_path\fzf\fd_show")
  return $exclusionArr
}

function spf {
  . $global:profile
}
function scfg {
  . "${env:user_conf_path}${dirsep}.uconfrc.ps1"
}
function sgcf {
  . "${env:user_conf_path}${dirsep}.uconfgrc.ps1"
}
function sals {
  . "${env:user_conf_path}${dirsep}.ualiasrc.ps1"
}
function sgal {
  . "${env:user_conf_path}${dirsep}.ualiasgrc.ps1"
}
function refrenv {
  . "${env:user_conf_path}${dirsep}utils${dirsep}refrenv.ps1"
}

# GIT
function glg {
  git log --oneline --decorate --graph
}
function glga {
  git log --all --oneline --decorate --graph
}
function gcommit { git commit -m $args }
function gcomm { git commit $args }
function gfetch { git fetch $args }
function gpull { git pull $args }
function gupdate {
  git fetch
  git pull
}
function gpush { git push $args }
function gadd { git add $args }
function greset { git reset $args }
function gbranch { git branch $args }
function grebase { git grebase $args }
function gmerge { git merge $args }
function gco { git checkout $args }
function gck { git checkout $args }
function grm { git checkout -- . }
function grepo {
  git rev-parse HEAD *> $null

  if (-not $?) {
    Write-Host "Not in a git repository"
    return
  }

  git @args
}

function g { git @args }

function gstatus {
  grepo status @args
}

if (Test-Path Alias:gs) { Remove-Item Alias:gs }
Set-Alias -Name gs -Value gstatus

# Git status short version
function gsb { gstatus -sb @args }
# Show cache
function gdf { grepo diff }
function gdc { grepo diff --cached }

# Shadowed by alias Get-Service
# function gsv { gstatus -v @args }
function gamend { git commit --amend }
function gdif { git diff $args }
function gstash { git stash $args }
function gsl { git stash list $args }
function gsa { git stash apply $args }
function gspop { git stash pop $args }
function gsp { git stash push -m $args }
function gss { git stash show $args }
function gsd { git stash drop $args }
function gprev { git diff HEAD^..HEAD }

function gprevd ([int] $num = 1) {
  git diff HEAD~"$num"..HEAD
}

function gprevr ([int] $first = 1, [int] $second = 0) {
  git diff HEAD~"$first"..HEAD~"$second"
}

function fadd () {
  fgf @args | ForEach-Object {
    Write-Host $_
    git add $_
  }
}

function fpad () {
  $files = @()
  fgf @args | ForEach-Object {
    Write-Host $_
    $files += "$_"
  }

  if ($files) {
    git add -p @files
  }
}

function fco () {
  fgb @args | ForEach-Object { git checkout "$($_ -replace 'origin/', '')" }
}

function fck () {
  fgb @args | ForEach-Object { git checkout "$($_ -replace 'origin/', '')" }
}

function fgrm () {
  fgf @args | ForEach-Object { git checkout -- "$_" }
}

function fsa () {
  fgs @args | ForEach-Object { git stash apply $_ }
}

function fmerge () {
  fgb @args | ForEach-Object { git merge "$_" }
}

function get_bare_repository () {
  $current_directory = $PWD.ToString()
  $toplevel = ''
  $bare_root = ''
  $is_bare_repository = $false

  if ("$(git rev-parse --is-bare-repository 2> $null)" -eq 'true') {
    $is_bare_repository = $true
    if (!(Test-Path -Path 'config' -PathType Leaf -ErrorAction SilentlyContinue)) {
      while ($PWD.Drive.Root -ne $PWD) {
        # Check if is a bare repo
        if (("$(git rev-parse --is-bare-repository 2> $null)" -eq 'true') -and (Test-Path -Path 'config' -PathType Leaf -ErrorAction SilentlyContinue)) {
          $bare_root = $PWD.ToString()
          break
        }
        # If error, it means we are no longer under a git repository
        if (!$?) {
          Write-Error "Could not find the root of the bare repository"
          return
        }
        # Move up a directory
        Set-Location ..
      }
    } else {
      $bare_root = $PWD.ToString()
    }
  } else {
    while ($PWD.Drive.Root -ne $PWD) {
      # Check if is a bare repo
      if ("$(git rev-parse --is-bare-repository 2> $null)" -eq 'true') {
        $is_bare_repository = $true
        break
      }
      # If error, it means we are no longer under a git repository
      if (!$?) { break }
      # Move up a directory
      Set-Location ..
    }

    # Recover current dir
    Set-Location "$current_directory"

    if ($is_bare_repository -eq $false) {
      Write-Error "Not in a bare repository"
      return
    }

    $toplevel = git rev-parse --show-toplevel
    if (!(Test-Path -Path "$toplevel/.git" -PathType Leaf -ErrorAction SilentlyContinue)) {
      Write-Error "Cannot find .git file"
      return
    }

    $bare_root = ((((Get-Content "$toplevel/.git") -Split ' ')[1]) -Split '/worktrees')[0]

    if (!(Test-Path -Path "$bare_root" -PathType Container -ErrorAction SilentlyContinue)) {
      Write-Error "Cannot find location of bare repository"
      return
    }

    # Test if detected directory is bare repository
    Push-Location "$bare_root"
    if ("$(git rev-parse --is-bare-repository 2>/dev/null)" -ne 'true') {
      Write-Error "Wrongly detecting '$bare_root' as root of bare repository"
      Pop-Location
      return
    }
    Pop-Location
  }

  return $bare_root
}

if (Test-Path Alias:gbr) { Remove-Item Alias:gbr }
Set-Alias -Name gbr -Value get_bare_repository

# Bare repo checkout
function gwc () {
  $bare_root = ''
  $branch_name = ''

  $bare_root = get_bare_repository

  if (!$bare_root) {
    return
  }

  Push-Location "$bare_root" *> $null

  if ( $args[0] -eq "-b" ) {
    $branch_name = $args[1]
    if (!(Test-Path -Path "$branch_name" -PathType Container -ErrorAction SilentlyContinue)) {
      $git_args = $args[2..$args.Count]
      git worktree add -b "$branch_name" "$branch_name" @git_args
    }
  } else {
    $branch_name = $args[0]
    if (!(Test-Path -Path "$branch_name" -PathType Container -ErrorAction SilentlyContinue)) {
      $git_args = $args[1..$args.Count]
      git worktree add "$branch_name" "$branch_name" @git_args
    }
  }

  # Recover previous location
  Pop-Location *> $null

  # Attempt to cd into new worktree
  Set-Location "$bare_root/$branch_name" *> $null
}

function fwc () {
  $branch_name = fgb @args | ForEach-Object {
    # Clean branch name
    $_ -replace 'origin/', ''
  }
  $branch_name = "$branch_name"

  if (!$branch_name) {
    return
  }

  gwc "$branch_name"
}

function fwr () {
  $selection = ''
  $bare_root = ''

  $bare_root = get_bare_repository

  if (!$bare_root) {
    return
  }

  fgb @args | ForEach-Object {
    # Clean branch name
    $_ -replace 'origin/', ''
  } | ForEach-Object {
    if (!$_) {
      git worktree remove "$_"
    }
  }
}

# Example
# $quick_access = @(
#   "$HOME"
#   "$env:prj"
#   "$env:prj\txt"
#   "$env:user_conf_path"
#   "$env:user_scripts_path"
#   "$HOME\.SpaceVim.d"
#   "$HOME\.SpaceVim.d\autoload"
#   "$env:AppData"
#   "$env:AppData\mpv"
#   "$env:localAppData"
#   "$env:temp"
# )

# $quick_edit = @(
#   "$env:user_conf_path\.uconfgrc.ps1"
#   "$env:user_conf_path\.ualiasgrc.ps1"
#   "$env:user_conf_path\.uconfrc.ps1"
#   "$env:user_conf_path\.ualiasrc.ps1"
#   "$HOME\.SpaceVim.d\init.toml"
#   "$HOME\.SpaceVim.d\autoload\config.vim"
# )

function qnv () {
  if (-not $quick_access) {
    return
  }

  $options = getPsFzfOptions

  $quick_access |
    Invoke-Fzf `
      -Header "(ctrl-/) Toggle preview" `
      @options | ForEach-Object {
        Set-Location "$_"
      }
}

function qed ([string] $editor = 'nvim') {
  if (-not $quick_edit) {
    return
  }

  $options = getPsFzfOptions

  $quick_edit |
    Invoke-Fzf `
      -Header "(ctrl-/) Toggle preview" `
      @options | ForEach-Object {
        & "$editor" "$_"
      }
}

function cprj ([Switch] $Raw) {
  $directories = & "${env:user_conf_path}${dirsep}utils${dirsep}getprojects.ps1"

  if (!$directories) {
    return
  }

  $fd_exclude_args = fd-Excluded
  $fd_command = "fd --color=always --type file $fd_exclude_args . {}"
  $reload_command = "pwsh -NoLogo -NonInteractive -NoProfile -File ${env:user_conf_path}${dirsep}utils${dirsep}getprojects.ps1"

  $options = getFzfOptions
  $selection = @(
    $directories |
      fzf @options `
        --history="$env:FZF_HIST_DIR/cprj" `
        --no-multi `
        --ansi --cycle `
        --info=inline `
        --header 'CTRL-R: Reload | CTRL-F: Files | CTRL-O: Open | CTRL-Y: Copy' `
        --bind "ctrl-f:change-prompt(Files> )+reload($fd_command)+clear-query+change-multi+unbind(ctrl-f)" `
        --bind "ctrl-r:change-prompt(Projs> )+reload($reload_command)+rebind(ctrl-f)+clear-query+change-multi(0)" `
        --bind "ctrl-y:execute-silent(pwsh -NoLogo -NonInteractive -NoProfile -File ${env:user_conf_path}${dirsep}utils${dirsep}copy-helper.ps1 {+f})+abort" `
        --bind "ctrl-o:execute-silent(pwsh -NoLogo -NoProfile -NonInteractive -Command Start-Process '{}')+abort" `
        --bind 'alt-a:select-all' `
        --bind 'alt-d:deselect-all' `
        --bind 'alt-f:first' `
        --bind 'alt-l:last' `
        --bind 'alt-c:clear-query' `
        --header 'Select project directory: ' `
        --prompt 'Projs> '
  )

  if (!$selection) { return }

  if ($Raw) { return $selection }

  if (Test-Path -PathType Leaf -Path $selection[0] -ea 0) {
    & "$env:PREFERRED_EDITOR" @selection
    return
  }

  Set-Location $selection[0]
}

function rfv {
  & "${env:user_conf_path}${dirsep}utils${dirsep}rgfzf.ps1" @args
}

function fcd () {
  $location = if ($args[0]) { $args[0] } else { "." }
  $query = $args[1..$args.length]
  $pattern = "."
  $options = getPsFzfOptions

  if ( -not (Test-Path $location) ) {
    $pattern = "$location"
    $location = "$HOME"
  }

  $location = if ("$location" -eq "~") { "$HOME" } else { "$location" }
  $exclude = fd-Excluded

  $selection = "$(
    fd `
      @exclude `
      --path-separator '/' `
      --color=always `
      -tl -td `
      "$pattern" "$location" |
    Invoke-Fzf `
      -Ansi -Cycle `
      -Header "(ctrl-/) Search in: $location" `
      -Query "$query" `
      @options
    )"

  if ((-not $selection) -or (-not (Test-Path $selection))) {
    return
  }

  Set-Location "$selection"
}

function fcdd () {
  $pattern = if ($args[0]) { $args[0] } else { "." }
  $query = $args[1..$args.length]
  $options = getPsFzfOptions
  $exclude = fd-Excluded

  $selection = "$(
    fd `
      @exclude `
      --path-separator '/' `
      --color=always `
      -tl -td "$pattern" |
    Invoke-Fzf `
      -Ansi -Cycle `
      -Header 'Press CTRL-/ to toggle preview' `
      -Query "$query" `
      @options
    )"

  if ((-not $selection) -or (-not (Test-Path $selection))) {
    return
  }

  Set-Location "$selection"
}

function fcde () {
  $location = if ($args[0]) { $args[0] } else { "." }
  $pattern = if ($args[1]) { $args[1] } else { "." }
  $query = $args[2..$args.length]
  $options = getPsFzfOptions

  if ( -not (Test-Path $location) ) {
    Write-Output "Invalid location. Defaulting to cwd."
    $location = $PWD
  }

  $location = if ("$location" -eq "~") { "$HOME" } else { "$location" }
  $exclude = fd-Excluded

  $selection = "$(
    fd `
      @exclude `
      -L -tf "$pattern" "$location" |
    ForEach-Object { Split-Path "$_" } |
    Sort-Object -Unique |
    Invoke-Fzf `
      -Header 'Press CTRL-/ to toggle preview' `
      -Query "$query" `
      @options
  )"

  if ((-not $selection) -or (-not (Test-Path $selection))) {
    return
  }

  Set-Location "$selection"
}

function info () {
  # can also be piped into less
  Get-Help -Full $args[0] | bat -l man -p
}

function up ([int] $val = 1) {
  $cmmd = ""
  if ($val -le 0) {
    $val = 1
  }
  for ($i = 1; $i -lt $val; $i++) {
    $cmmd = "/.." + $cmmd
  }
  try {
    Set-Location "..${cmmd}"
  } catch {
    Write-Output "Couldn't go up $limit dirs."
  }
}

# NAVIGATION
function .. {
  $index = if ($args) { $args } else { 0 }

  up $index
}

function ... {
  up 2
}

function showAllPorts {
  netstat -aon
}

# Node & NPM
function npm-list {
  npm list -g --dept=0
}

function nlg { npm list -g --dept=0 }

function nr { npm run $args }
function mr { npm run $args }

function fnr {
  if ( -not (Test-Path package.json) ) {
    Write-Output "No package.json in dir $PWD"
    return
  }

  $runner = if ($args[0]) { $args[0] } else { 'npm' }
  $query = $args[1..$args.Length]
  $runner_func = $null

  switch -Regex ("$runner") {
    "^(m|pnpm|mr)$" {
      $runner_func = { pnpm run @args }
    }
    "^(n|npm|nr|-)$" {
      $runner_func = { npm run @args }
    }
  }

  $value_script = "
    `$val = {};
    `$val = `$val.Trim(`"'`").Trim('`"');
    Get-Content package.json |
      jq -r "".scripts[```"`$val```"]""
  "
  $copy_script = $value_script + " | Set-Clipboard"
  $selection = Get-Content package.json |
    jq -r '.scripts | keys[]' |
    Sort-Object |
    fzf --query "$query" --height '50%' --min-height '20' `
      --with-shell 'pwsh -nolo -nopro -nonin -c' `
      --border --no-multi `
      --bind "ctrl-y:execute-silent({} | Set-Clipboard)+abort" `
      --bind "ctrl-u:execute-silent($copy_script)+abort" `
      --preview-window 'up:3:hidden:wrap' `
      --bind 'ctrl-/:toggle-preview,ctrl-s:toggle-sort' `
      --preview $value_script

  if( -not $selection ) { return }

  Invoke-Command $runner_func -ArgumentList $selection
}


function fif () {
  if ($args.length -eq 0) {
    Write-Output 'Need a string to search for!'
    return
  }

  $single = "$args"
  $options = getPsFzfOptions

  rg --color=always --files-with-matches --no-messages "$single" |
    Invoke-Fzf `
      -Ansi -Cycle `
      -Height $options.Height -MinHeight $options.MinHeight -Border `
      -Bind $options.Bind `
      -Preview "pwsh -NoLogo -NonInteractive -NoProfile -File $env:user_conf_path/utils/highlight.ps1 \`"$single\`" {}"
}

function fdirs () {
  $options = getPsFzfOptions

  $selection = $($(Get-Location -Stack) |
    Invoke-Fzf `
      -Cycle `
      @options)

  if ($selection) {
    Set-Location "$selection"
  }
}

function fenv () {
  $options = @(
    '--preview', "pwsh -NoLogo -NonInteractive -NoProfile -File $env:user_conf_path${dirsep}utils${dirsep}log-helper.ps1 {}",
    '--bind', 'ctrl-/:toggle-preview',
    '--bind', 'alt-up:preview-page-up',
    '--bind', 'alt-down:preview-page-down',
    '--bind', 'ctrl-s:toggle-sort',
    '--expect', 'ctrl-h,ctrl-v',
    '--header', 'CTRL-Y: Copy | CTRL-V: Value | CTRL-H: Key',
    '--bind', "ctrl-y:execute-silent(pwsh -NoLogo -NonInteractive -NoProfile -File '${env:user_conf_path}${dirsep}utils${dirsep}copy-helper.ps1' {})+abort",
    '--preview-window', 'up:50%:hidden:wrap'
  )

  $output = @($(Get-childItem -Path env: |
    ForEach-Object { Write-Output "$($_.key)=$($_.value.Trim() -Replace '\n', ' ')" } |
    fzf @options))

    if ($output[0] -eq 'ctrl-h') {
      $res = $output[1] -Split '='
      $res[0]
    } elseif ($output[0] -eq 'ctrl-v') {
      $res = $output[1] -Split '='
      $res[1..$res.length] -Join '='
    } else {
      $output
    }
}

function getFunctionsDefinitions ([switch] $NullTerminated) {
  $end_of_function = if ($NullTerminated) { "`0" } else { "" }
  $sb = [System.Text.StringBuilder]::new()

  foreach ($func_info in (Get-ChildItem function:\)) {
    if ($func_info.Name -match '^[A-Z]:$') {
      continue
    }

    $name = $func_info.Name
    $definition = $func_info.Definition

    $func_str = @"
function $name () {
    $definition
}$end_of_function
"@

    # $func_str.Replace("`r", '')
    [void] $sb.Append($func_str)
  }

  return $sb.ToString().Replace("`r", '')
}

function pfn () {
  getFunctionsDefinitions -NullTerminated |
    bat --plain --language powershell --color always |
    fzf --read0 --ansi --reverse --multi --highlight-line
}

function getShellAliasAndFunctions ([Switch] $GetTempFile) {
  $outTempFile = New-TemporaryFile
  $presortedFile = New-TemporaryFile

  try {
    # Get alias names
    Get-Alias | ForEach-Object { $_.Name } >> $presortedFile.FullName

    # Get function names
    $sb_functions = [System.Text.StringBuilder]::new()
    foreach ($func_info in (Get-ChildItem function:\)) {
      if ($func_info.Name -match '^[A-Z]:$') {
        continue
      }

      $name = $func_info.Name
      [void] $sb_functions.Append("$name`n")
    }

    $function_names = $sb_functions.ToString().Trim()
    $function_names >> $presortedFile.FullName

    # Get sorted output
    [System.IO.File]::ReadLines($presortedFile.FullName) | Sort-Object -u | Out-File $outTempFile -encoding ascii

    if (-not $GetTempFile) {
      return (Get-Content $outTempFile.FullName)
    } else {
      return $outTempFile
    }
  } finally {
    # Remove Unsorted file
    if (Test-Path -Path $presortedFile.FullName -PathType leaf -ErrorAction SilentlyContinue) {
      Remove-Item -Force -Path $presortedFile.FullName
    }

    # Remove Sorted file
    if ((-not $GetTempFile) -and (Test-Path -Path $outTempFile.FullName -PathType leaf -ErrorAction SilentlyContinue)) {
      Remove-Item -Force -Path $outTempFile.FullName
    }
  }
}

function fcmd () {
  $commandFile = getShellAliasAndFunctions -GetTempFile
  $definitionsFile = New-TemporaryFile

  try {
    # Get all function and alias definitions in a file for later reuse
    foreach ($cmd in [System.IO.File]::ReadLines($commandFile.FullName)) {
      $definition = (Get-Command -Name "$cmd").Definition

      "`n$cmd`n $definition`n" >> $definitionsFile.FullName
    }

    # Create a script body pointing to the temporary file with the commands definitions
    $preview = @"
      `$Item = {}
      `$PreviewItem = `$Item.Trim("'").Trim('"');
      `$cmdResults = Get-Command `$PreviewItem -ErrorAction SilentlyContinue;
      if (`$cmdResults) {
        `$RunningInWindowsTerminal = [bool](`$env:WT_Session);
        `$IsWindowsCheck = (`$PSVersionTable.PSVersion.Major -le 5) -or `$IsWindows;
        `$ansiCompatible = `$RunningInWindowsTerminal -or (-not `$IsWindowsCheck);
        if (`$cmdResults.CommandType -ne 'Application') {
          if (`$ansiCompatible -and (Get-Command bat -ErrorAction SilentlyContinue)) {
            Get-Help `$PreviewItem | bat --language man -p --color=always
          } else {
            Get-Help `$PreviewItem
          }
        } else {
          `$cmdResults.Source
        }
      } else {
        if (`$PreviewItem -eq "..") {
          `$PreviewItem = "\.\."
        } elseif (`$PreviewItem -eq "...") {
          `$PreviewItem = "\.\.\."
        }
        rg -A 100 -B 1 -m 1 "^`$PreviewItem" "$($definitionsFile.FullName)" |
          bat --language powershell --color=always -p -H 2
      }
"@

    $options = getFzfOptions
    [System.IO.File]::ReadLines($commandFile.FullName) |
      fzf @options `
        --with-shell "pwsh -NoLogo -NonInteractive -NoProfile -Command" `
        --preview $preview
  } finally {
    # Remove Commands file
    if (Test-Path -Path $commandFile.FullName -PathType leaf -ErrorAction SilentlyContinue) {
      Remove-Item -Force -Path $commandFile.FullName
    }

    # Remove Definitions file
    if (Test-Path -Path $definitionsFile.FullName -PathType leaf -ErrorAction SilentlyContinue) {
      Remove-Item -Force -Path $definitionsFile.FullName
    }
  }
}

function fnvm () {
  $nvm_version = nvm list |
    Where-Object { $_ } |
    fzf |
    ForEach-Object {
    $trimmed = $_.Trim()
    if ($trimmed -match '^[*-]') { ($trimmed.Split())[1].Trim() } else { $trimmed }
  }

  if ($nvm_version) {
    nvm use $nvm_version
  }
}

function getAppPid ([String] $port, [Switch] $help = $false) {
  if ($help) {
    Write-Output "
    Print all connections where the given port is found
    Command syntax: [ getAppPid `"5500`" ]

    Flags
    -help    Print this help"
    return
  }
  if ( -not $port ) { return }
  netstat -aon | grep ":$port"
}

function getTaskByPid ([String] $pidvalue, [Switch] $help = $false) {
  if ($help) {
    Write-Output "
    Find a process name by its PID
    Command syntax: [ getTaskByPid `"25641`" ]

    Flags
    -help    Print this help"

    return
  }
  if ( -not $pidvalue ) { return }
  tasklist | grep $pidvalue
}

function getAllAppsInPort ([String] $port, [Switch] $help = $false) {
  if ($help) {
    Write-Output "
    Find and print all the processes using a specific port
    Command syntax: [ getAllAppsInPort `"25641`" ]

    Flags
    -help    Print this help"

    return
  }
  if ( -not $port ) { return }
  getAppPid $port | awk -v protocol=TCP '{ if ( $1 == protocol ) { print $5 } else { print $4 } }' | Foreach-Object { getTaskByPid $_ }
}

function makeSymLink ([String] $target, [String] $path) {
  if (-not (Split-Path $target -IsAbsolute)) {
    # Get absolute path for the requested symlink
    $symlinkFinalPath = $executionContext.sessionState.path.getUnresolvedProviderPathFromPSPath($path)
    # Get location where symlink will be located
    $symlinkLocation = [System.IO.Path]::GetDirectoryName($symlinkFinalPath)
    # Create temporal file
    # [io.file]::create((expand $file)).close()
    # $absolutePathToTarget = (Get-Item $target).FullName
    $absolutePathToTarget = $executionContext.sessionState.path.getUnresolvedProviderPathFromPSPath($target)
    Push-Location $symlinkLocation
    $relativePathToTarget = $absolutePathToTarget | Resolve-Path -Relative
    Pop-Location

    New-Item -ItemType SymbolicLink -Target $relativePathToTarget -Path $path

    return
  }

  New-Item -ItemType SymbolicLink -Target $target -Path $path
}

if (Test-Path Alias:ln-s) { Remove-Item Alias:ln-s }
Set-Alias -Name ln-s -Value makeSymLink

function makeShortCut ([string] $target, [string] $path, [string] $arguments = '') {
  if (-not ($path -match '\.lnk')) { $path = "$path.lnk" }
  $shell = New-Object -ComObject WScript.Shell
  $shortcut = $shell.CreateShortcut("$path")

  if ($shorcut.TargetPath -ne $target) {
    $shortcut.TargetPath = "$target"
    if ($arguments) { $shortcut.Arguments = $arguments }
    $shortcut.Save()
  }
}

function mkdr { New-Item $args -ItemType Directory -ea 0 }

if (Get-Command -Name 'eza' -ErrorAction SilentlyContinue) {
  function ll () { eza -AlF --icons --group-directories-first @args }
  function la () { eza -AF --icons --group-directories-first @args }
  function l () { eza -F --icons --group-directories-first @args }
} else {
  function ll () { Get-ChildItem @args }
  # Simple attempt to get a behavior like 'ls -ACF'
  # in powershell (including color output).
  # Not perfect but gets the job done.
  function l () {
    [CmdletBinding()]
    param(
      [String]
      $DirectoryName = '.',
      [Parameter(ValueFromPipeline = $true)]
      [String]
      $PathFromPipe
    )

    $path = if ($PathFromPipe) { $PathFromPipe } else { $DirectoryName }
    # Resolve path
    $path = [IO.Path]::GetFullPath([IO.Path]::Combine((Get-Location -PSProvider FileSystem).ProviderPath, $path))
    # $path = Join-Path -Path $path -ChildPath .

    $position = $PSCmdlet.MyInvocation.PipelinePosition
    $length = $PSCmdlet.MyInvocation.PipelineLength

    # NOTE: Looks like -Force is better to get all files
    # $filesFound = Get-ChildItem -Attributes Directory, Directory+Hidden, Hidden, Archive, Archive+Hidden -Path $path -Include * | % {
    $filesFound = Get-ChildItem -Path $path -Force -ErrorAction SilentlyContinue | ForEach-Object {
      # $acc = [PSCustomObject] @{ Dirs = '' }
      # $acc = @()
      # } {
      $fileName = $_.Name

      # Return filename as it, no need to format for pipeline
      if ($position -ne $length) {
        return $fileName
      }

      $item = [PSCustomObject] @{ Content = '' }

      # if (Test-Path -PathType Leaf -Path f) {}
      if ($_.Attributes -Band [IO.FileAttributes]::ReparsePoint) {
        $fileName = "$fileName@"
      } elseif ($_.Attributes -Band [IO.FileAttributes]::Directory) {
        $fileName = "$fileName/"
      } elseif ($_.Attributes -Band [IO.FileAttributes]::Archive) {
        $fileName = "$fileName*"
      }

      $item.Content = $fileName
        return $item
    }

    # Return object as is if not in a pipeline
    if ($position -ne $length) {
      return $filesFound
    }

    if ($filesFound.Length -eq 0) {
      return $filesFound
    }

    # Regext for color output. Currently only Directories, Files and Links
    $colorMap = @{
      # Match names ending with '/' either that the start or end. => Directories
      # ('^[\.]?\b[\w\W].*\b/(?= )', '(?<=  )[\.]?\b[\w\W].*\b\/') = 'white,darkblue'
      # '\S+(?:\s?)\/' = 'white,darkblue' # Second attempt, doesn't accept spaces between words
      '\S+\.?\w+(?:\s\W*\w+)*\/' = 'white,darkblue'
      # Match names ending with '*' either that the start or end. => Files
      # ('^[\.]?\b[\w\W].*\b\*(?= )', '(?<=  )[\.]?\b[\w\W].*\b\*') = 'green' # First attempt, doesn't work with multiple columns
      # '\S+\*' = 'green' # Seconds attempt, doesn't accept spaces between words
      '\S+\.?\w+(?:\s\W*\w+)*\*' = 'green'
      # Match names ending with '@' either that the start or end. => Links
      # ('^[\.]?\b[\w\W].*\b@(?= )', '(?<=  )[\.]?\b[\w\W].*\b@') = 'cyan' # First attempt, doesn't work with multiple columns
      # '\S+@' = 'cyan' # Second attempt, doesn't accept spaces between words
      '\S+\.?\w+(?:\s\W*\w+)*@' = 'cyan'
    }

    # Set number of columns
    $columns = if ($filesFound.Length -gt 100) { 4 } elseif ($filesFound.Length -gt 20) { 3 } else { 2 }
    # Format output to be displayed
    $filesFound |
      Sort-Object -Property Content |
      Format-Wide -Column $columns -Property Content |
      Out-HostColored -PatternColorMap $colorMap
  }
}

function pvim() { vim --clean @args }
function pnvim() { nvim --clean @args }

function ntmp {
  $temporary = if ($env:TEMP) { $env:TEMP } else { "${HOME}${dirsep}tmp" }
  $editor = if ($env:PREFERRED_EDITOR) { $env:PREFERRED_EDITOR } else { vim }
  & $editor "$temporary/tmp-$(New-Guid).md"
}

function ntxt ([String] $filename = '') {
  $filename = if ($filename) { $filename } else { "tmp-$(New-Guid).md" }
  $filename = "${env:prj}${dirsep}txt${dirsep}${filename}"
  $dirlocation = [System.IO.Path]::GetDirectoryName($filename)

  $editor = if ($env:PREFERRED_EDITOR) { $env:PREFERRED_EDITOR } else { vim }
  New-Item -Path $dirlocation -ItemType Directory -ea 0

  & $editor "$filename"
}

function ftxt () {
  $txt = "${env:prj}${dirsep}txt"

  if (-not (Test-Path -PathType Container -Path "$txt" -ErrorAction SilentlyContinue)) {
    Write-Output "No $txt directory"
    return
  }

  $selected = @()
  $fzf_options = getFzfOptions

  Push-Location "$txt" *> $null
  $selected = @($(
    fd --color=always -tf . |
      fzf @fzf_options --ansi --cycle --multi `
      --with-shell 'pwsh -NoLogo -NonInteractive -NoProfile -Command' `
      --preview-window '~4,60%' `
      --preview 'bat --style=full --color=always {}'
  ))

  if ($selected.Length -eq 0) {
    Pop-Location *> $null
    return
  }

  $editor = if ($env:PREFERRED_EDITOR) { $env:PREFERRED_EDITOR } else { 'vim' }

  try {
    & "$editor" @selected
  } finally {
    Pop-Location *> $null
  }
}

# extract files
function ex () {
  $filename = $args[0]
  $options = $args[1..$args.Length]

  if (Test-Path "$fileName" -ErrorAction SilentlyContinue) {
    switch -wildcard -casesensitive ($filename) {
      "*.tbz"        { tar xjvf "$filename" @options; Break }
      "*.tar.bz2"    { tar xjvf "$filename" @options; Break }
      "*.tar.bz"     { tar xjvf "$filename" @options; Break }
      "*.tbz2"       { tar xjvf "$filename" @options; Break }
      "*.tar.gz"     { tar xzvf "$filename" @options; Break }
      "*.tgz"        { tar xzvf "$filename" @options; Break }
      "*.bz2"        { bunzip2 "$filename" @options; Break }
      "*.rar"        { unrar x "$filename" @options; Break }
      "*.gz"         { gunzip "$filename" @options; Break }
      "*.tar"        { tar xvf "$filename" @options; Break }
      "*.zip"        { unzip "$filename" @options; Break }
      "*.Z"          { uncompress "$filename" @options; Break }
      "*.7z"         { 7z x "$filename" @options; Break }
      "*.iso"        { 7z x "$filename" @options; Break }
      "*.deb"        { ar x "$filename" @options; Break }
      "*.tar.xz"     { tar xJvf "$filename" @options; Break }
      "*.txz"        { tar xJvf "$filename" @options; Break }
      "*.tar.zst"    { zstd -d "$filename" @options; Break }
      "*.ipk"        { zstd -d "$filename" @options; Break }
      "*.wgt"        { zstd -d "$filename" @options; Break }
      "*.apk"        { zstd -d "$filename" @options; Break }
      default        { Write-Host "'$filename' cannot be extracted via ex command!"; Break }
    }
  } else {
    Write-Host "'$filename' is not a file"
  }
}

function archive () {
  $atype = $args[0]
  $filename = $args[1]
  $options = $args[2..$args.Length]

  switch -wildcard -casesensitive ($atype) {
    "*.tar"        { tar cvf "$filename" $options; Break }
    "*.tgz"        { tar czvf "$filename" $options; Break }
    "*.7z"         { 7z a "$filename" $options; Break }
    "*.zip"        { zip -r "$filename" $options; Break }
    "*.rar"        { rar a "$filename" $options; Break }
    default        { Write-Host "Archive type '$filename' is not supported by archive command!"; Break }
  }
}

function mpvp () {
  $url = $args[0]
  $extra_args = $args[1..$args.length]

  Write-Output "Playing: $url"

  $yt_dlp_args = "-f bestvideo+bestaudio/best"

  $command_str = "yt-dlp $yt_dlp_args -o - ""$url"" | mpv --cache $extra_args -"
  cmd /c "$command_str"
}

function plpp () {
  $url = "$(pbpaste)"

  if ( -not "$url" ) {
    Write-Output "Invalid url"
    return
  }

  $url = $url.Trim()

  mpvp "$url"
}

function play () {
  $url = "$(pbpaste)"

  if ( -not "$url" ) {
    Write-Output "Invalid url"
    return
  }

  $url = $url.Trim()
  Write-Output "Playing: $url"

  if (
    "$url".contains('.torrent')
  ) {
    toru stream --torrent "$url" @args
    return
  }

  if (
    "$url".contains('magnet:')
  ) {
    toru stream --magnet "$url" @args
    return
  }

  if (
    # "$url".contains('.torrent') -or
    # "$url".contains('magnet:') -or
    "$url".contains('webtorrent://') -or
    "$url".contains('peerflix://')
  ) {
    if ($args) {
      webtorrent --mpv "$url" @args
    } else {
      webtorrent --mpv "$url"
    }
    return
  }

  # Let mpv handle the url
  mpv "$url" @args
}

function tplay ([Switch] $limit) {
  $url = "$(pbpaste)"

  if (-not $url) {
    Write-Output "No url"
    return
  }

  $url = $url.Trim()
  Write-Output "Playing: $url"

  if (
    "$url".contains('.torrent')
  ) {
    toru stream --torrent "$url" @args
    return
  }

  if (
    "$url".contains('magnet:')
  ) {
    toru stream --magnet "$url" @args
    return
  }

  # For webtorrent only
  $webtorrent_args = @()

  if ($limit) {
    $webtorrent_args += '-u'
    $webtorrent_args += 1
  }

  foreach ($wa in $args) {
    $webtorrent_args += $wa
  }

  if ($webtorrent_args) {
    webtorrent --mpv "$url" @webtorrent_args
  } else {
    webtorrent --mpv "$url"
  }
}

function reboot () { Restart-Computer -ComputerName localhost -Force }
function setoff () { Stop-Computer -ComputerName localhost -Force }

function restart () { shutdown /r /f /t 0 }
function turnoff () { shutdown /s /f /t 0 }

function tkill () { taskkill /f /im $args }

function yt-dw () {
  $video_url = "$(pbpaste)"
  if ( -not $video_url ) { return }
  yt-dlp "$video_url" $args
}

function dwv () {
  $video_url= "$(pbpaste)"
  if ( -not $video_url) { return }

  $video_url = $video_url.Trim()
  Write-Output "Downloading: $video_url"
  yt-dlp "$video_url" @args
}

function dwi () {
  $image_url = "$(pbpaste)"
  if ( -not $image_url ) { return }

  $image_url = $image_url.Trim()
  Write-Output "Downloading: $image_url"
  gallery-dl "$image_url" @args
}

function fed () {
  $location = $args[0] ?? "."
  $query = $args[2..$args.length]
  $pattern = "."
  $editor = "$env:PREFERRED_EDITOR" ?? 'vim'
  $options = getPsFzfOptions

  if ( -not (Test-Path $location) ) {
    $pattern = "$location"
    $location = "$HOME"
  }

  $location = if ("$location" -eq "~") { "$HOME" } else { "$location" }
  if ("$location" -like '~*') {
    $location = "$HOME" + $location.Substring(1)
  }

  $exclude = fd-Excluded

  $selection = @($(
    fd `
      @exclude `
      --path-separator '/' `
      --color=always `
      -tf `
      "$pattern" "$location" |
    Invoke-Fzf `
      -Multi `
      -Ansi `
      -Cycle `
      -Header "(ctrl-/) Search in: $location" `
      -Query "$query" `
      @options
  ))

  if (-not $selection) {
    return
  }

  if ($args[1] -and ($args[1] -ne "-")) {
    $editor = $args[1]
  }

  & "$editor" $selection
}

function fedd () {
  $query = $args[1..$args.length]
  $editor = "$env:PREFERRED_EDITOR" ?? 'vim'
  $options = getPsFzfOptions
  $exclude = fd-Excluded

  $selection = "$(
    fd `
      @exclude `
      --path-separator '/' `
      --color=always `
      -tf |
    Invoke-Fzf `
      -Multi `
      -Cycle `
      -Header "(ctrl-/) Search in: $location" `
      -Query "$query" `
      @options
    )"
  # -Bind ctrl-/:toggle-preview `
# -Preview "bat --color=always {}" `

  if ((-not $selection) -or (-not (Test-Path $selection))) {
    return
  }

  if ($args[0] -and ($args[0] -ne "-")) {
    $editor = $args[0]
  }

  & "$editor" "$selection"
}

if (Test-Path Alias:utf8) { Remove-Item Alias:utf8 }
Set-Alias -Name utf8 -Value With-UTF8

if (-not (Test-Path env:OutputEncodingBackupSet)) {
  $OutputEncodingBackup = [Console]::OutputEncoding
  $env:OutputEncodingBackupSet = 'true'
}

function Switch-Utf8 ([switch] $Enable = $false) {
  if ($Enable) {
    [Console]::OutputEncoding = New-Object System.Text.Utf8Encoding
  } else {
    [Console]::OutputEncoding = $OutputEncodingBackup
  }
}

if (Test-Path Alias:sutf8) { Remove-Item Alias:sutf8 }
Set-Alias -Name sutf8 -Value Switch-Utf8

function fmpv () {
  $mpv_args = $args
  $fzf_options = getFzfOptions
  $mpv_block = {
    $selection = @($(
      fd -tf --color=always | fzf --multi --ansi --cycle `
        @fzf_options `
        --border
    ))

    if ($selection.Length -eq 0) { return }

    mpv @mpv_args -- @selection
  }

  if ($IsWindows) {
    With-UTF8 $mpv_block
  } else {
    & $mpv_block
  }
}

function getClipboardPath {
  $filepath = "$(pbpaste)"
  $filepath = $filepath.Trim()
  $directory = ""

  if ("$filepath" -match '^/[a-zA-Z]/') {
    $filepath = $filepath.Substring(1, 1).toUpper() + ':' + $filepath.Substring(2)
  } elseif ("$filepath" -match '^/mnt/[a-zA-Z]') {
    $filepath = $filepath.Substring(5, 1).toUpper() + ':' + $filepath.Substring(6)
  }

  if ( -not "$filepath" -or -not (Test-Path "$filepath") ) { return }
  if ( (Get-Item "$filepath") -is [System.IO.DirectoryInfo] ) { # Is directory
    $directory = "$filepath"
  } else {
    # $directory = Get-Item "$filepath" | Select-Object DirectoryName | % { $_.DirectoryName }
    $directory = Split-Path "$filepath"
  }
  return "$directory"
}

function ccd () {
  $filepath = getClipboardPath
  if ( -not "$filepath" ) {
    Write-Output "Invalid path"
    return
  }
  Set-Location "$filepath"
}

function ocd () {
  $filepath = getClipboardPath
  if ( -not "$filepath" ) {
    Write-Output "Invalid path"
    return
  }
  Start-Process "$filepath"
}

function ptc () {
  $location = $args[0] ?? "."
  $query = $args[1..$args.length]
  $pattern = "."
  $options = getPsFzfOptions

  if ( -not (Test-Path $location) ) {
    $pattern = "$location"
    $location = "$HOME"
  }

  $exclude = fd-Excluded

  $selection = "$(
    &{
      Write-Output '.';
      fd `
        @exclude `
        --path-separator '/' `
        --color=always `
        -tl -td -tf `
        "$pattern" "$location" } |
    Invoke-Fzf `
      -Ansi -Cycle `
      -Header "(ctrl-/) Search in: $location" `
      -Query "$query" `
      @options
    )"

  if ((-not $selection) -or (-not (Test-Path $selection))) {
    return
  }

  $selection = Get-Item "$selection" -Force | Select-Object FullName | ForEach-Object { $_.FullName }
  Write-Output "$selection" | tr -d "\r\n" | pbcopy
}

function Count-Files (
  [Switch] $Size,
  [String[]]
  [Parameter(Position=1, ValueFromRemainingArguments)]
  $FdProps
) {

  function Get-SimpleCount () {
    $dir = $_.Name
    fd --hidden $FdProps . $dir | Measure-Object | ForEach-Object {
      [PSCustomObject] @{
        Name = $dir
        Count = $_.Count
      }
    }
  }

  function Get-CountWithSize () {
    $dir = $_.Name
    $size = Get-ChildItem -Recurse -Path $dir 2>&1 | ForEach-Object {
      if ($_ -is [System.Management.Automation.ErrorRecord]) {
        # Print message if it is an error
        Write-Host $_.Exception.Message -ForegroundColor Red
      } else {
        # Otherwise, just output the input object as-is
        $_
      }
    } | Measure-Object -Property Length -Sum

    if ($size.Sum -gt 1GB) {
      $size = "$([math]::Round($size.Sum / 1GB, 3))GB"
    } elseif ($size.Sum -gt 1MB) {
      $size = "$([math]::Round($size.Sum / 1MB, 3))MB"
    } elseif ($size.Sum -gt 1KB) {
      $size = "$([math]::Round($size.Sum / 1KB, 3))KB"
    } else {
      $temp = if ($size.Sum) { $size.Sum } else { 0 }
      $size = "$([math]::Round($temp, 3))B"
    }

    fd --hidden $FdProps . "$dir" | Measure-Object | ForEach-Object {
      [PSCustomObject] @{
        Name = $dir
        Count = $_.Count
        Size = $size
      }
    }
  }

  if ($Size) {
    $result = Get-ChildItem -Attributes Directory, Directory+Hidden | ForEach-Object { Get-CountWithSize $_ }
  } else {
    $result = Get-ChildItem -Attributes Directory, Directory+Hidden | ForEach-Object { Get-SimpleCount $_ }
  }

  $result | Format-Table -Auto -Wrap
}

function cevery ([Switch] $Size) {
  Write-Host "Counting all files in $PWD"
  Count-Files -Size:$Size
}

function cdirs ([Switch] $Size) {
  Write-Host "Counting directories in $PWD"
  Count-Files -Size:$Size -td
}

function cfiles ([Switch] $Size) {
  Write-Host "Counting files in $PWD"
  Count-Files -Size:$Size -tf
}

function mountDir ([string] $Letter, [string] $PathToMount) {
  if (-Not (Test-Path -Path "$PathToMount" -ErrorAction SilentlyContinue)) {
    Write-Error "Error: the path '$PathToMount' does not exist"
    return
  }

  if (-Not $Letter) {
    Write-Error "Mount letter required"
    return
  }

  subst "${letter}:" "$pathToMount"
}

function unmountDir ([string] $Letter) {
  if (-Not $Letter) {
    Write-Error "Mount letter required"
    return
  }

  subst /d "${Letter}:"
}

function unshort ([string] $Url) {
  curl --head --location "$Url" | Select-String "Location"
}


function publicip {
  curl checkip.amazonaws.com
}

function qrcode ([String] $Text) {
  curl "qrenco.de/$Text"
}

function wifiList ([string] $WifiName = '') {

  function parseNetsh ([string] $line) {
    $content = $line -Split ':'
    "$($content[1..$content.Length] -Join ':' )".Trim()
  }

  if ($WifiName) {
    $profilePass = "No Password"
    $out_content = netsh wlan show profile "$WifiName" key=clear

    if (-Not $?) {
      Write-Output $out_content
      return
    }

    $out_content = $out_content | Select-String "Key Content"

    $profilePass = parseNetsh "$out_content"

    Write-Output "${WifiName}: $profilePass"
    return
  }

  netsh wlan show profile | Select-String "All User" | ForEach-Object {
    $profileName = parseNetsh "$_"
    $profilePass = "No Password"

    $profilePass = netsh wlan show profile "$profileName" key=clear |
      Select-String "Key Content" | ForEach-Object { parseNetsh "$_" }

    $profilePass = if ($profilePass) { $profilePass } else { "No Password" }

    Write-Output "${profileName}: $profilePass"
  }
}

if (Test-Command Download-Gdl) {
  # Alias to Set-Env
  if (Test-Path Alias:dgl) { Remove-Item Alias:dgl }
  Set-Alias -Name dgl -Value Download-Gdl
}

if (Test-Command Download-Ydl) {
  # Alias to Set-Env
  if (Test-Path Alias:dyl) { Remove-Item Alias:dyl }
  Set-Alias -Name dyl -Value Download-Ydl
}

function bdif () {
  if (git rev-parse HEAD) { } else { return }

  $changed_files = @(git diff --name-only --relative --diff-filter=d)

  if (-not $changed_files) {
    return
  }

  bat --diff $changed_files
}

# Matches both soft and hard link
function Test-ReparsePoint([string]$path) {
  $file = Get-Item $path -Force -ea SilentlyContinue
  return [bool]($file.Attributes -band [IO.FileAttributes]::ReparsePoint)
}

# TODO: If condition is not reliable with LinkType ("SymbolicLink" | "HardLink")
# Try using Test-ReparsePoint or dir /aL
# https://stackoverflow.com/questions/817794/find-out-whether-a-file-is-a-symbolic-link-in-powershell
function frm () {
  $query = "$args"
  $options = getPsFzfOptions
  $exclude = fd-Excluded

  fd `
    @exclude `
    --path-separator '/' `
    --color=always `
    -tf -tl |
  Invoke-Fzf `
    @options `
    -Ansi -Cycle `
    -Multi `
    -Query "$query" | Where-Object {
      # If item is a file or a SymbolicLink
      (
        Test-Path -PathType Leaf "$_" -ErrorAction SilentlyContinue
      ) -or ($_.LinkType)
    } | Remove-Item
}

function frdr () {
  $query = "$args"
  $options = getPsFzfOptions
  $exclude = fd-Excluded

  fd `
    @exclude `
    --path-separator '/' `
    --color=always `
    -td -d 1 |
  Invoke-Fzf `
    @options `
    -Ansi -Cycle `
    -Multi `
    -Query "$query" | Where-Object {
      # If item is a file or a SymbolicLink
      (
        Test-Path -PathType Container "$_" -ErrorAction SilentlyContinue
      ) -or ($_.LinkType)
    } | Remove-Item -recurse -force
}

# Note: Print-MemoryUsage was moved to its own independent script
if (Test-Path Alias:pmu) { Remove-Item Alias:pmu }
Set-Alias -Name pmu -Value Print-MemoryUsage

function grc () {
  Push-Location $env:user_conf_path
  & "${env:user_conf_path}${dirsep}utils${dirsep}rgfzf.ps1" @args
  Pop-Location
}

function grs () {
  Push-Location $env:user_scripts_path
  & "${env:user_conf_path}${dirsep}utils${dirsep}rgfzf.ps1" @args
  Pop-Location
}

function padd () {
  mkdr "$HOME/projects"
  Push-Location "$HOME/projects"
  git clone @args
  Pop-Location
}

function padb () {
  mkdr "$HOME/projects"
  Push-Location "$HOME/projects"
  try {
    clone-bare @args
  } finally {
    Pop-Location
  }
}

function rupdate () {
  # Navigate to important repos and pull the changes
  $repositories = @(
    "$env:user_conf_path"
    "$env:user_scripts_path"
    "$HOME${dirsep}.SpaceVim.d"
    "$HOME${dirsep}.config${dirsep}vscode-nvim"
    "$HOME${dirsep}omp-theme"
    "$HOME${dirsep}vim-config"
  )

  foreach ($repo in $repositories) {
    if (!(Test-Path -Path "$repo" -PathType Container -ErrorAction SilentlyContinue)) {
      continue
    }

    Push-Location "$repo" *> $null || return
    Write-Output "Repo: $repo"
    $remote = (((git remote -v)[0]).Split())[1]
    Write-Output "Remote: $remote"
    git fetch && git pull --rebase
    Pop-Location *> $null || return
  }
}

function themes_bat ([string] $filename) {
  # Get other themes like tokio night
  # Ref: https://github.com/folke/tokyonight.nvim/issues/23
  if ((!$filename) -or !(Test-Path -Path $filename -PathType Leaf -ErrorAction SilentlyContinue)) {
    Write-Output "You need to provide a file to show the themes"
    return
  }

  $fzf_options = getFzfOptions
  $selected_theme = bat --list-themes |
    fzf @fzf_options `
      --cycle --cycle `
      --preview-window 'right:80%' `
      --preview "bat --theme={} --color=always $filename"

  if (!$selected_theme) {
    return
  }

  Write-Output "The theme '$selected_theme' has been set temporary on 'env:BAT_THEME' environment variable"
  $env:BAT_THEME = $selected_theme
}

function themes_vivid () {
  $fzf_options = getFzfOptions
  $selected_theme = vivid themes |
    fzf @fzf_options `
      --cycle `
      --preview-window 'right:70%' `
      --with-shell 'pwsh --NoLogo -NoProfile -NonInteractive -Command'`
      --preview '
      Write-Output "Theme: {}";
      Write-Output "";
      $env:LS_COLORS = vivid generate {};
      eza --color=always --icons=always;
      Write-Output "";
      eza -AlF --color=always --icons=always;
      '

  if (!$selected_theme) {
    return
  }

  Write-Output "The theme '$selected_theme' has been set temporary on 'env:LS_COLORS' environment variable"
  $env:LS_COLORS = "$(vivid generate $selected_theme)"
}

if ($IsWindows) {
  # If we have pwsh winget module, then show winget packages
  if (Get-Module Microsoft.WinGet.Client -ErrorAction SilentlyContinue) {
    function show_packages () {
      $selected = ''
      $fzf_options = getFzfOptions
      $packages = Get-WinGetPackage | ForEach-Object {
        "$($_.Name)`t$($_.Id)"
      }

      while ($true) {
        $selected = $packages | fzf @fzf_options `
          --cycle `
          --delimiter "`t" --with-nth=1 `
          --preview 'winget show {2} | bat --style=plain --color=always --language yml' | ForEach-Object {
            ($_ -Split "`t")[1]
          }

        if (!$selected) { break }
        winget show $selected | bat --style=plain --color=always --paging=always --language 'yml'
        $selected = ''
      }
    }
  } else {
    function show_packages () {
      $selected = ''
      $fzf_options = getFzfOptions
      $packages = scoop list | ForEach-Object { $_.Name }

      while ($true) {
        $selected = $packages | fzf @fzf_options `
          --cycle `
          --preview 'scoop info {}'

        if (!$selected) { break }
        scoop info $selected | bat --style=plain --color=always --paging=always
        $selected = ''
      }
    }
  }
}

function config () {
  $first = $args[0]

  if (!$first) {
    Push-Location "$HOME/.config"
    fed '.'
    Pop-Location
  } elseif (Test-Path -Path "$HOME/.config/$first" -PathType Container -ErrorAction SilentlyContinue) {
    Set-Location "$HOME/.config/$args"
  } elseif (Test-Path -Path "$HOME/.config/$first" -PathType Leaf -ErrorAction SilentlyContinue) {
    & $env:PREFERRED_EDITOR "$HOME/.config/$first"
  } else {
    Write-Output "$first does not exist in the .config directory."
  }
}


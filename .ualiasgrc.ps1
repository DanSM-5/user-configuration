
############################################
#      GENERAL FUNCTIONS AND ALIASES       #
############################################

# Follow structure conf folders and files
$user_conf_path = "$HOME\.usr_conf"
$user_scripts_path = "$HOME\user-scripts"
$prj = "$HOME\prj"

$env:PREFERED_EDITOR = if ($env:PREFERED_EDITOR) { $env:PREFERED_EDITOR } else { "vim" }

# Dot sourcing function scripts
# TODO: Loop through files and source them
# E.G. Get-ChildItem -Path utils | Where { $_.Name -Like 'function-*.ps1' }
. "$user_conf_path\utils\function-Out-HostColored.ps1"
. "$user_conf_path\utils\function-With-Env.ps1"
. "$user_conf_path\utils\function-New-CommandWrapper.ps1"

# Script called from function
function pimg () { & "$user_conf_path\utils\paste-image.ps1" $args }

function gpr { cd $prj }
function gus { cd $user_scripts_path }
function guc { cd $user_conf_path }
function gvc { cd "$HOME\.SpaceVim.d" }
function goh { cd "$HOME"}

function epf { nvim $PROFILE }
function ecf { nvim "$user_conf_path\.uconfrc.ps1" }
function egc { nvim "$user_conf_path\.uconfgrc.ps1" }
function eal { nvim "$user_conf_path\.ualiasrc.ps1" }
function ega { nvim "$user_conf_path\.ualiasgrc.ps1" }
function evc { nvim "$HOME\.SpaceVim.d\init.toml" }

function getPsFzfOptions {
  $path = $PWD.ProviderPath.Replace('\', '/')
  $psFzfPreviewScript = "$user_conf_path\utils\PsFzfTabExpansion-Preview.ps1"
  $psFzfOptions = @{
    Preview = $("pwsh -NoProfile -NonInteractive -NoLogo -File \""$psFzfPreviewScript\"" \""" + $path + "\"" {}" );
    Bind = 'ctrl-/:change-preview-window(down|hidden|)','alt-up:preview-page-up','alt-down:preview-page-down','ctrl-s:toggle-sort'
    Height = '80%'
    MinHeight = 20
    Border = $true
  }
  return $psFzfOptions
}

function fd-Excluded {
  $exclusionArr = @( $env:FD_SHOW_OPTIONS -Split ' ' )
  $exclusionArr += @( $env:FD_EXCLUDE_OPTIONS -Split ' ' )
  return $exclusionArr
}

function spf {
  . $global:profile
}
function scfg {
  . "$user_conf_path\.uconfrc.ps1"
}
function sgcf {
  . "$user_conf_path\.uconfgrc.ps1"
}
function sals {
  . "$user_conf_path\.ualiasrc.ps1"
}
function sgal {
  . "$user_conf_path\.ualiasgrc.ps1"
}
function refrenv {
  . "$user_conf_path\utils\refrenv.ps1"
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
function gstatus {
  git rev-parse HEAD *> $null

  if (-not $?) {
    Write-Host "Not in a git repository"
    return
  }

  git status $args
}

if (Test-Path Alias:gs) { Remove-Item Alias:gs }
Set-Alias -Name gs -Value gstatus

# Shadowed by alias Get-Service
# function gsv { gstatus -v @args }
function gamend { git commit --amend }
function gdif { git diff $args }
function gstash { git stash $args }
function gsl { git stash list $args }
function gsa { git stash apply $args }
function gspop { git stash pop $args }
function gsp { git stash push $args }
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
  fgf | % { git add $_ }
}

function fpad () {
  $files = @()
  fgf | % { $files += "$_" }

  if ($files) {
    git add -p $files
  }
}

function fco () {
  fgb | % { git checkout "$($_ -replace 'origin/', '')" }
}

function fck () {
  fgb | % { git checkout "$($_ -replace 'origin/', '')" }
}

function fgrm () {
  fgf | % { git checkout -- "$_" }
}

function fsa () {
  fgss | % { git stash apply $_ }
}

# Example
# $quick_access = @(
#   "$HOME"
#   "$prj"
#   "$prj\txt"
#   "$user_conf_path"
#   "$user_scripts_path"
#   "$HOME\.SpaceVim.d"
#   "$HOME\.SpaceVim.d\autoload"
#   "$env:AppData"
#   "$env:AppData\mpv"
#   "$env:localAppData"
#   "$env:temp"
# )

# $quick_edit = @(
#   "$user_conf_path\.uconfgrc.ps1"
#   "$user_conf_path\.ualiasgrc.ps1"
#   "$user_conf_path\.uconfrc.ps1"
#   "$user_conf_path\.ualiasrc.ps1"
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
      @options |
    % { cd "$_" }
}

function qed ([string] $editor = 'nvim') {
  if (-not $quick_edit) {
    return
  }

  $options = getPsFzfOptions

  $quick_edit |
    Invoke-Fzf `
      -Header "(ctrl-/) Toggle preview" `
      @options |
    % { & "$editor" "$_" }
}

function rfv {
  if ($args) {
    Invoke-PsFzfRipgrep "$args"
  } else {
    Invoke-PsFzfRipgrep
  }
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
      -tl -td `
      "$pattern" "$location" |
    Invoke-Fzf `
      -Header "(ctrl-/) Search in: $location" `
      -Query "$query" `
      @options
    )"

  if ((-not $selection) -or (-not (Test-Path $selection))) {
    return
  }

  cd "$selection"
}

function fcdd () {
  $pattern = if ($args[0]) { $args[0] } else { "." }
  $query = $args[1..$args.length]
  $options = getPsFzfOptions
  $exclude = fd-Excluded

  $selection = "$(
    fd `
      $exclude `
      -tl -td "$pattern" |
    Invoke-Fzf `
      -Header 'Press CTRL-/ to toggle preview' `
      -Query "$query" `
      @options
    )"

  if ((-not $selection) -or (-not (Test-Path $selection))) {
    return
  }

  cd "$selection"
}

function fcde () {
  $location = if ($args[0]) { $args[0] } else { "." }
  $pattern = if ($args[1]) { $args[1] } else { "." }
  $query = $args[2..$args.length]
  $options = getPsFzfOptions

  if ( -not (Test-Path $location) ) {
    echo "Invalid location. Defaulting to cwd."
    $location = "$(pwd)"
  }

  $location = if ("$location" -eq "~") { "$HOME" } else { "$location" }
  $exclude = fd-Excluded

  $selection = "$(
    fd `
      $exclude `
      -L -tf "$pattern" "$location" |
    % { Split-Path "$_" } |
    Sort-Object -Unique |
    Invoke-Fzf `
      -Header 'Press CTRL-/ to toggle preview' `
      -Query "$query" `
      @options
  )"

  if ((-not $selection) -or (-not (Test-Path $selection))) {
    return
  }

  cd "$selection"
}

function info () {
  # can also be piped into less.exe
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
    cd "..${cmmd}"
  } catch {
    echo "Couldn't go up $limit dirs."
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

function fnr {
  if ( -not (Test-Path package.json) ) {
    echo "No package.json in dir $(pwd)"
    return
  }

  $query = "$args"

  $selection = "$(cat package.json |
    jq -r '.scripts | keys[]' |
    sort |
    Invoke-Fzf -Query "$query" -Height 50% -MinHeight 20 -Border)"

  if( -not $selection ) { return }
  npm run $selection
}


function fif () {
  if ($args.length -eq 0) {
    echo 'Need a string to search for!'
    return
  }

  $single = "$args"
  $options = getPsFzfOptions

  rg --files-with-matches --no-messages "$single" |
    Invoke-Fzf `
      -Height $options.Height -MinHeight $options.MinHeight -Border `
      -Bind $options.Bind `
      -Preview "pwsh -NoLogo -NonInteractive -NoProfile -File $user_conf_path/utils/highlight.ps1 \`"$single\`" {}"
}

function fdirs () {
  $options = getPsFzfOptions

  $selection = $($(Get-Location -Stack) |
    Invoke-Fzf `
      @options)

  if ($selection) {
    Set-Location "$selection"
  }
}

function fenv () {
  $showValue = $false

  if ($args[0] -eq '-v') { $showValue = $true }

  $options = @{
    Preview = $("pwsh -NoLogo -NonInteractive -NoProfile -File \""$($user_conf_path -Replace '\\', '/')/utils/log-helper.ps1\"" {}");
    Bind = @(
      'ctrl-/:toggle-preview'
      # TODO: Investigate change-preview-window not working
      # 'ctrl-/:change-preview-window(down|hidden|)'
      'alt-up:preview-page-up'
      'alt-down:preview-page-down'
      'ctrl-s:toggle-sort'
      "ctrl-y:execute-silent(pwsh -NoLogo -NonInteractive -NoProfile -File $user_conf_path\utils\copy-helper.ps1 {})+abort"
    )
  }

  Get-childItem -Path env: |
    % { echo "$($_.key)=$($_.value.Trim() -Replace '\n', ' ')" } |
    Invoke-Fzf `
      -PreviewWindow 'up:3:hidden:wrap' `
      @options |
    % {
      $res = $($_ -Split '=')
      if ($showValue) { $res[1..$res.length] -Join '=' } else { $res[0] }
    }
}

function getAppPid ([String] $port, [Switch] $help = $false) {
  if ($help) {
    echo ""
    echo "  Print all connections where the given port is found"
    echo "  Command syntax: [ getAppPid `"5500`" ]"
    echo ""
    echo "  Flags"
    echo "  -help    Print this help"
    echo ""
    return
  }
  if ( -not $port ) { return }
  netstat -aon | grep ":$port"
}

function getTaskByPid ([String] $pidvalue, [Switch] $help = $false) {
  if ($help) {
    echo ""
    echo "  Find a process name by its PID"
    echo "  Command syntax: [ getTaskByPid `"25641`" ]"
    echo ""
    echo "  Flags"
    echo "  -help    Print this help"
    echo ""
    return
  }
  if ( -not $pidvalue ) { return }
  tasklist | grep $pidvalue
}

function getAllAppsInPort ([String] $port, [Switch] $help = $false) {
  if ($help) {
    echo ""
    echo "  Find and print all the processes using a specific port"
    echo "  Command syntax: [ getAllAppsInPort `"25641`" ]"
    echo ""
    echo "  Flags"
    echo "  -help    Print this help"
    echo ""
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

function ll () { ls $args }

function l () {  
  # $path = if($args[0]) { $args[0] } else { '.' }
  [CmdletBinding()]
  param(
    $DirectoryName = '.',
    [Parameter(ValueFromPipeline = $true)]
    $PathFromPipe
  )

  $path = if ($PathFromPipe) { $PathFromPipe } else { $DirectoryName }

  # Regext for color output
  $colorMap = @{
    # Match names ending with '/' either that the start or end. => Directories
    ('^[\.]?\b[\w\W].*\b/(?= )', '(?<=  )[\.]?\b[\w\W].*\b\/') = 'white,darkblue'
    # Match names ending with '*' either that the start or end. => Files
    ('^[\.]?\b[\w\W].*\b\*(?= )', '(?<=  )[\.]?\b[\w\W].*\b\*') = 'green'
    # Match names ending with '@' either that the start or end. => Links
    ('^[\.]?\b[\w\W].*\b@(?= )', '(?<=  )[\.]?\b[\w\W].*\b@') = 'cyan'
  }

  $position = $PSCmdlet.MyInvocation.PipelinePosition
  $length = $PSCmdlet.MyInvocation.PipelineLength

  Get-ChildItem -Attributes Directory, Directory+Hidden, Hidden, Archive, Archive+Hidden -Path $path | % {
    # $acc = [PSCustomObject] @{ Dirs = '' }
    # $acc = @()
  # } {
    $fileName = $_.Name

    if ($position -ne $length) {
      return $fileName
    }

    $item = [PSCustomObject] @{ Content = '' }

    # if (Test-Path -PathType Leaf -Path f) {}
    if ($_.Attributes -Band [Io.FileAttributes]::ReparsePoint) {
      $fileName = "$fileName@"
    } elseif ($_.Attributes -Band [Io.FileAttributes]::Directory) {
      $fileName = "$fileName/"
    } elseif ($_.Attributes -Band [Io.FileAttributes]::Archive) {
      $fileName = "$fileName*"
    }

    $item.Content = $fileName
    return $item
  # } {
  #   $acc.Dirs 
  } | Format-Wide -Property Content |
    Out-HostColored $colorMap
}

function ntemp {
  nvim "$env:temp/temp-$(New-Guid).txt"
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

  echo "Playing: $url"

  $yt_dlp_args = "-f bestvideo+bestaudio/best"

  $command_str = "yt-dlp $yt_dlp_args -o - ""$url"" | mpv --cache $extra_args -"
  cmd /c "$command_str"
}

function plpp () {
  $url = "$(pbpaste)"

  if ( -not "$url" ) {
    echo "Invalid url"
    return
  }

  $url = $url.Trim()

  mpvp "$url"
}

function play () {
  $url = "$(pbpaste)"

  if ( -not "$url" ) {
    echo "Invalid url"
    return
  }

  $url = $url.Trim()
  echo "Playing: $url"

  if (
    "$url".contains('.torrent') -or
    "$url".contains('magnet:') -or
    "$url".contains('webtorrent://') -or
    "$url".contains('peerflix://')
  ) {
    if ($args) {
      webtorrent --mpv "$url" $args
    } else {
      webtorrent --mpv "$url"
    }
  } else {
    mpv "$url" $args
  }
}

function tplay ([Switch] $limit) {
  $url = "$(pbpaste)"

  if (-not $url) {
    echo "No url"
    return
  }

  $url = $url.Trim()
  echo "Playing: $url"

  $webtorrent_args = @()

  if ($limit) {
    $webtorrent_args += '-u'
    $webtorrent_args += 1
  }

  foreach ($wa in $args) {
    $webtorrent_args += $wa
  }

  if ($webtorrent_args) {
    webtorrent --mpv "$url" $webtorrent_args
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
  echo "Downloading: $video_url"
  yt-dlp "$video_url" @args
}

function dwi () {
  $image_url = "$(pbpaste)"
  if ( -not $image_url ) { return }

  $image_url = $image_url.Trim()
  echo "Downloading: $image_url"
  gallery-dl "$image_url" @args
}

function fed () {
  $location = $args[0] ?? "."
  $query = $args[2..$args.length]
  $pattern = "."
  $editor = "$env:PREFERED_EDITOR" ?? 'vim'
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
      $exclude `
      -tf `
      "$pattern" "$location" |
    Invoke-Fzf `
      -Multi `
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
  $editor = "$env:PREFERED_EDITOR" ?? 'vim'
  $options = getPsFzfOptions
  $exclude = fd-Excluded

  $selection = "$(
    fd `
      $exclude `
      -tf |
    Invoke-Fzf `
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

function fmpv {
  $selection = $(fd -tf | Invoke-Fzf -m -q "$args")
  if ( -not $selection ) { return }
  mpv $selection
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
    echo "Invalid path"
    return
  }
  cd "$filepath"
}

function ocd () {
  $filepath = getClipboardPath
  if ( -not "$filepath" ) {
    echo "Invalid path"
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
    fd `
      $exclude `
      -tl -td -tf `
      "$pattern" "$location" |
    % -Begin { '.' } { "$_" } |
    Invoke-Fzf `
      -Header "(ctrl-/) Search in: $location" `
      -Query "$query" `
      @options
    )"

  if ((-not $selection) -or (-not (Test-Path $selection))) {
    return
  }

  $selection = Get-Item "$selection" | Select-Object FullName | % { $_.FullName }
  echo "$selection" | tr -d "\r\n" | pbcopy
}

function Count-Files (
  [Switch] $Size,
  [String[]]
  [Parameter(Position=1, ValueFromRemainingArguments)]
  $FdProps
) {

  function Get-SimpleCount () {
    $dir = $_.Name
    fd --hidden $FdProps . $dir | Measure-Object | % {
      [PSCustomObject] @{
        Name = $dir
        Count = $_.Count
      }
    }
  }

  function Get-CountWithSize () {
    $dir = $_.Name
    $size = Get-ChildItem -Recurse -Path $dir 2>&1 | % {
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

    fd --hidden $FdProps . "$dir" | Measure-Object | % {
      [PSCustomObject] @{
        Name = $dir
        Count = $_.Count
        Size = $size
      }
    }
  }

  if ($Size) {
    $result = Get-ChildItem -Attributes Directory, Directory+Hidden | % { Get-CountWithSize $_ }
  } else {
    $result = Get-ChildItem -Attributes Directory, Directory+Hidden | % { Get-SimpleCount $_ }
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

function mountDir ([string] $letter, [string] $pathToMount) {
  if (-Not (Test-Path -Path "$pathToMount" -ErrorAction SilentlyContinue)) {
    Write-Output "Error, the path '$pathToMount' does not exist"
    return
  }

  if (-Not $letter) {
    Write-Output "Mount letter required"
    return
  }

  subst "${letter}:" "$pathToMount"
}

function unmountDir ([string] $letter) {
  if (-Not $letter) {
    Write-Output "Mount letter required"
    return
  }

  subst /d "${letter}:"
}

function unshort ([string] $url) {
  curl.exe --head --location "$url" | Select-String "Location"
}


function publicip {
  curl.exe checkip.amazonaws.com
}

function qrcode ([String] $text) {
  curl.exe "qrenco.de/$text"
}

function wifiList ([string] $wifiName = '') {

  function parseNetsh ([string] $line) {
    ($line -Split ':')[1].Trim()
  }

  if ($wifiName) {
    $profilePass = "No Password"
    $out_content = netsh wlan show profile "$wifiName" key=clear

    if (-Not $?) {
      Write-Output $out_content
      return
    }

    $out_content = $out_content | Select-String "Key Content"

    $profilePass = parseNetsh "$out_content"

    Write-Output "${wifiName}: $profilePass"
    return
  }

  netsh wlan show profile | Select-String "All User" | % {
    $profileName = parseNetsh "$_"
    $profilePass = "No Password"

    $profilePass = netsh wlan show profile "$profileName" key=clear |
      Select-String "Key Content" | % { parseNetsh "$_" }

    $profilePass = if ($profilePass) { $profilePass } else { "No Password" }

    Write-Output "${profileName}: $profilePass"
  }
}

if (Test-Command Download-Gdl) {
  # Alias to Set-Env
  if (Test-Path Alias:dgl) { Remove-Item Alias:dgl }
  Set-Alias -Name dgl -Value Download-Gdl
}

function bdif () {
  if (git rev-parse HEAD) { } else { return }

  $changed_files = @(git diff --name-only --relative --diff-filter=d)

  if (-not $changed_files) {
    return
  }

  bat --diff $changed_files 
}

if (Get-Command -Name "lf.exe" -ErrorAction SilentlyContinue) {
  function lf () {
    # Important to use @args and no $args to forward arguments
    lf.ps1 @args
  }
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
    -tf -tl |
  Invoke-Fzf `
    @options `
    -Multi `
    -Query "$query" | ? { 
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
    -td -d 1 |
  Invoke-Fzf `
    @options `
    -Multi `
    -Query "$query" | ? { 
      # If item is a file or a SymbolicLink
      (
        Test-Path -PathType Container "$_" -ErrorAction SilentlyContinue
      ) -or ($_.LinkType)
    } | Remove-Item -recurse -force
}


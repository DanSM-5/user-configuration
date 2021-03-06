
############################################
#      GENERAL FUNCTIONS AND ALIASES       #
############################################

# Follow structure conf folders and files
$user_conf_path = "$HOME\.usr_conf"
$user_scripts_path = "$HOME\user-scripts"
$prj = "$HOME\prj"

$env:PREFERED_EDITOR = if ($env:PREFERED_EDITOR) { $env:PREFERED_EDITOR } else { "vim" }

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
function evc { nvim "$user_conf_path\init.toml" }

# function fzf-defaults {
#   [CmdletBinding()]
#   param(
#     [Parameter()]
#     [Array] $piped
#   )
#   echo $piped
#   echo $args
#   $piped | fzf --height 50% --min-height 20 --border --bind ctrl-/:toggle-preview $args
# }

function spf {
  . $global:profile
}
function scfg {
  . "$HOME\.usr_conf\.uconfrc.ps1"
}
function sgcf {
  . "$HOME\.usr_conf\.uconfgrc.ps1"
}
function sals {
  . "$HOME\.usr_conf\.ualiasrc.ps1"
}
function sgal {
  . "$HOME\.usr_conf\.ualiasgrc.ps1"
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
function gck { git checkout $args }
function grm { git checkout -- . }
function fgrm { rm "$(fgf)" }
function gstatus { git status $args }
function gs { git status $args }
function gsv { git status -v $args }
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

function fck () {
  fgb | % { git checkout "$($_ -replace 'origin/', '')" }
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

  $quick_access | fzf --min-height 20 --bind ctrl-/:toggle-preview --preview 'echo {} && echo **************** && ls {}' |
    % { cd "$_" }
}

function qed ([string] $editor = 'nvim') {
  if (-not $quick_edit) {
    return
  }

  $quick_edit | fzf --min-height 20 --bind ctrl-/:toggle-preview --preview 'bat --color=always {}' |
    % { & "$editor" "$_" }
}

# NAVIGATION
function .. {
  cd ..
}

function ... {
  cd ../..
}

function fcd ([int] $depth = 1) {
  $selection = "$(
    fd --exclude ".git" `
      --exclude "node_modules" `
      --hidden -tl -td -d "$depth" |
    fzf --height 50% --min-height 20 --border `
      --bind ctrl-/:toggle-preview `
      --header 'Press CTRL-/ to toggle preview' `
      --preview "ls {}"
    )"

  if ((-not $selection) -or (-not (Test-Path $selection))) {
    return
  }

  cd "$selection"
}

function fcdd () {
  $selection = "$(
    fd --exclude ".git" `
      --exclude "node_modules" `
      --hidden -tl -td |
    fzf --height 50% --min-height 20 --border `
      --bind ctrl-/:toggle-preview `
      --header 'Press CTRL-/ to toggle preview' `
      --preview "ls {}"
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

function showAllPorts {
  netstat -aon
}

# Node & NPM
function npm-list {
  npm list -g --dept=0
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
  New-Item -ItemType SymbolicLink -Target $target -Path $path
}

function ll () { ls $args }

function ntemp {
  nvim "$env:temp/temp-$(New-Guid).txt"
}

# extract files
function ex ([String] $filename) {
  if (Test-Path $fileName) {
    switch -wildcard -casesensitive ($filename) {
      "*.tar.bz2"    { tar xjvf $filename; Break }
      "*.tar.gz"     { tar xzvf $filename; Break }
      "*.bz2"        { bunzip2 $filename; Break }
      "*.rar"        { unrar x $filename; Break }
      "*.gz"         { gunzip $filename; Break }
      "*.tar"        { tar xvf $filename; Break }
      "*.tbz2"       { tar xjvf $filename; Break }
      "*.tgz"        { tar xzvf $filename; Break }
      "*.zip"        { unzip $filename; Break }
      "*.Z"          { uncompress $filename; Break }
      "*.7z"         { 7z x $filename; Break }
      "*.deb"        { ar x $filename; Break }
      "*.tar.xz"     { tar xvf $filename; Break }
      "*.tar.zst"    { unzstd $filename; Break }
      default        { echo "'$filename' cannot be extracted via ex()!"; Break }
    }
  } else {
    echo "'$filename' is not a file"
  }
}

# Mimic env.exe to include env variables to call a ps1 script
# E.g. With-Env VAR=VAL script.ps1
# Ref: https://devblogs.microsoft.com/scripting/proxy-functions-spice-up-your-powershell-core-cmdlets/
# PS > $MetaData = New-Object System.Management.Automation.CommandMetaData (Get-Command  Some-Command)
# PS > [System.Management.Automation.ProxyCommand]::Create($MetaData)
function With-Env () {
  param()

  begin
  {
      try {
          $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand("$user_conf_path\utils\With-Env.ps1", [System.Management.Automation.CommandTypes]::ExternalScript)
          $PSBoundParameters.Add('$args', $args)
          $scriptCmd = {& $wrappedCmd @PSBoundParameters }

          $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
          $steppablePipeline.Begin($myInvocation.ExpectingInput, $ExecutionContext)
      } catch {
          throw
      }
  }

  process
  {
      try {
          $steppablePipeline.Process($_)
      } catch {
          throw
      }
  }

  end
  {
      try {
          $steppablePipeline.End()
      } catch {
          throw
      }
  }
  <#
    .ForwardHelpTargetName $user_conf_path\utils\With-Env.ps1
    .ForwardHelpCategory ExternalScript
  #>
}

function play () { mpv $(pbpaste) }
function tplay () { webtorrent --mpv "$(pbpaste)" }

function reboot () { Restart-Computer -ComputerName localhost -Force }
function setoff () { Stop-Computer -ComputerName localhost -Force }

function restart () { shutdown /r /f /t 0 }
function turnoff () { shutdown /s /f /t 0 }

function tkill () { taskkill /f /im $args }

function pimg () { & "$user_conf_path\utils\paste-image.ps1" $args }

function yt-dw () {
  yt-dlp "$(pbpaste)"
}

function dwi () {
  gallery-dl "$(pbpaste)"
}

function fed ([int] $depth = 1) {
  $selection = "$(
    fd --exclude ".git" `
      --exclude "node_modules" `
      --hidden -tf -d "$depth" |
    fzf --height 50% --min-height 20 --border `
      --bind ctrl-/:toggle-preview `
      --header 'Press CTRL-/ to toggle preview' `
      --preview "bat --color=always {}"
    )"

  if ((-not $selection) -or (-not (Test-Path $selection))) {
    return
  }

  & "$env:PREFERED_EDITOR" "$selection"
}

function fedd () {
  $selection = "$(
    fd --exclude ".git" `
      --exclude "node_modules" `
      --hidden -tf |
    fzf --height 50% --min-height 20 --border `
      --bind ctrl-/:toggle-preview `
      --header 'Press CTRL-/ to toggle preview' `
      --preview "bat --color=always {}"
    )"

  if ((-not $selection) -or (-not (Test-Path $selection))) {
    return
  }

  & "$env:PREFERED_EDITOR" "$selection"
}


############################################
#      GENERAL FUNCTIONS AND ALIASES       #
############################################

# Follow structure conf folders and files
$user_conf_path = "$HOME\.usr_conf\.uconfrc.ps1"
$user_scripts_path = "$HOME\user-scripts"
$prj = "$HOME\prj"

function gpr { cd $prj }
function gus { cd $user_scripts_path }

function epf { vim $PROFILE }
function ecf { vim "$HOME\.usr_conf\.uconfrc.ps1" }
function egc { vim "$HOME\.usr_conf\.uconfgrc.ps1" }
function eal { vim "$HOME\.usr_conf\.ualiasrc.ps1" }
function ega { vim "$HOME\.usr_conf\.ualiasgrc.ps1" }
function evc { vim "$HOME\.SpaceVim.d\init.toml" }

function guc { cd "$HOME\.usr_conf" }
function gvc { cd "$HOME\.SpaceVim.d" }

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
function gs { git status . }
function gstatus { git status . }
function gfetch {
  git fetch
}
function gpull {
  git pull
}

function gupdate {
  git fetch
  git pull
}

function grm {
  git checkout -- .
}
function gck { git checkout $args }
function gcommit { git commit -m $args }
function gcomm { git commit $args }
function glg {
  git log --oneline --decorate --graph
}
function glga {
  git log --all --oneline --decorate --graph
}
function gadd { git add $args }
function gpush { git push $args }
function gamend { git commit --amend }
function gdif { git diff $args }
function gstash { git stash $args }
function gsl { git stash list $args }
function gsa { git stash apply $args }
function gspop { git stash pop $args }
function gsp { git stash push $args }
function gss { git stash show $args }
function gsd { git stash drop $args }

# NAVIGATION
function .. {
  cd ..
}

function ... {
  cd ../..
}

function up ([String] $num = "1") {
  $val = [int] $num
  $dirup = ".."
  $cmmd = ""
  if ($val -le 0) {
    $val = 1
  }
  for ($i = 1; $i -lt $val; $i++) {
    $cmmd = "/.." + $cmmd
  }
  cd "${dirup}${cmmd}"
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

function ntemp {
  vim "$env:temp/temp-$(New-Guid).txt"
}

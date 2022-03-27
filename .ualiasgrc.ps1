
############################################
#      GENERAL FUNCTIONS AND ALIASES       #
############################################

# Follow structure conf folders and files
$user_conf_path = "$HOME\.usr_conf\.uconfrc.ps1"
$user_scripts_path = "C:\user-scripts"
$prj = "$HOME\prj"

function gpr { cd $prj }
function gus { cd $user_scripts_path }

function epf { gvim $PROFILE }
function ecf { gvim "$HOME\.usr_conf\.uconfrc.ps1" }
function egc { gvim "$HOME\.usr_conf\.uconfgrc.ps1" }
function eal { gvim "$HOME\.usr_conf\.ualiasrc.ps1" }
function ega { gvim "$HOME\.usr_conf\.ualiasgrc.ps1" }
function evc { gvim "$HOME\.SpaceVim.d\init.toml" }

function guc { cd "$HOME\.usr_conf" }

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
  git fetch -and git pull
}

function grm {
  git checkout -- .
}

function gck { git checkout $args }

function gcommit { git commit -m $args }

function glg {
  git log --oneline --decorate --graph
}

function glga {
  git log --all --oneline --decorate --graph
}

function gadd { git add $args }

function gpush { git push $args }

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


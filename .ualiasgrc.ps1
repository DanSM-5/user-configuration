
############################################
#      GENERAL FUNCTIONS AND ALIASES       #
############################################

# Follow structure conf folders and files
$user_conf_path = "$HOME/.uconfrc"
$user_scripts_path = "C:/user-scripts"
$prj = "$HOME/prj"

function spf {
  . $profile
}
function scfg {
  . "$HOME/.uconfrc.ps1"
}
function sgcf {
  . "$HOME/.uconfgrc.ps1"
}
function sals {
  . "$HOME/.ualiasrc.ps1"
}
function sgal {
  . "$HOME/.ualiasgrc.ps1"
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
  git fetch && git pull
}

function grm {
  git checkout -- .
}

function gck ([String] $cmmd) {
  git checkout ${cmmd}
}

function gcommit ([String] $cmmd) {
  git commit -m ${cmmd}
}

function glg {
  git log --oneline --decorate --graph
}

function glga {
  git log --all --oneline --decorate --graph
}

function gadd ([String] $cmmd) {
  git add $cmmd
}

function gpush ([String] $cmmd) {
  git push $cmmd
}

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

function showAllPorts () {
  netstat -aon
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


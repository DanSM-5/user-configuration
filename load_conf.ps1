
###############################
#     SOURCE USER SCRIPTS     #
###############################

# $env:IS_WSL = $false
# $env:IS_WSL2 = $false
# $env:IS_TERMUX = $false
# $env:IS_GITBASH = $false

$env:IS_WINDOWS = $IsWindows
$env:IS_MAC = $IsMacOS
$env:IS_LINUX = $IsLinux
$env:IS_POWERSHELL = $true

if (Test-Path -Path $HOME\.usr_conf\.uconfgrc.ps1 -PathType Leaf) {
  . $HOME\.usr_conf\.uconfgrc.ps1
}
if (Test-Path -Path $HOME\.usr_conf\.ualiasgrc.ps1 -PathType Leaf) {
  . $HOME\.usr_conf\.ualiasgrc.ps1
}
if (Test-Path -Path $HOME\.usr_conf\.uconfrc.ps1 -PathType Leaf) {
  . $HOME\.usr_conf\.uconfrc.ps1
}
if (Test-Path -Path $HOME\.usr_conf\.ualiasrc.ps1 -PathType Leaf) {
  . $HOME\.usr_conf\.ualiasrc.ps1
}

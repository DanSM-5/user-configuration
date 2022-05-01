
###############################
#     SOURCE USER SCRIPTS     #
###############################

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

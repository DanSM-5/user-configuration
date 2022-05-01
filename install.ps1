
$conf_string = "
################################
#       LOAD USER CONFIG       #
################################
if (Test-Path -Path $HOME\.usr_conf\load_conf.ps1 -PathType Leaf) {
  . $HOME\.usr_conf\load_conf.ps1
}
"

$conf_string >> $PROFILE

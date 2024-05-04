
$conf_string = @"
################################
#       LOAD USER CONFIG       #
################################

if (Test-Path -Path "`$HOME\.usr_conf\load_conf.ps1" -PathType Leaf -ErrorAction SilentlyContinue) {
  . "`$HOME\.usr_conf\load_conf.ps1"
}
"@

$conf_string >> $PROFILE

Write-Output "Installation completed!"


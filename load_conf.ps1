
###############################
#     SOURCE USER SCRIPTS     #
###############################

$env:IS_WSL = 'false'
$env:IS_WSL2 = 'false'
$env:IS_TERMUX = 'false'
$env:IS_GITBASH = 'false'
$env:IS_CMD = 'false'
$env:IS_WINSHELL = if ($IsWindows) { 'true' } else { 'false' }

$env:IS_WINDOWS = if ($IsWindows) { 'true' } else { 'false' }
$env:IS_MAC = if ($IsMacOS) { 'true' } else { 'false' }
$env:IS_LINUX = if ($IsLinux) { 'true' } else { 'false' }
$env:IS_POWERSHELL = 'true'

# Needed for all scripts even if other fails
function Test-Command {
  Param ($command)
  $oldPreference = $ErrorActionPreference
  $ErrorActionPreference = 'stop'
  try {
    if (Get-Command $command) { return $true }
  } catch { return $false }
  finally { $ErrorActionPreference = $oldPreference }
}


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

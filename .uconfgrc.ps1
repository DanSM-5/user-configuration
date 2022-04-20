
############################################
#          GENERAL CONFIGURATIONS          #
############################################

# Follow structure conf folders and files
$user_conf_path = "$HOME\.usr_conf"
$user_scripts_path = "$HOME\user-scripts"
$prj = "$HOME\prj"

function testCommand {
  Param ($command)
  $oldPreference = $ErrorActionPreference
  $ErrorActionPreference = 'stop'
  try {
    if (Get-Command $command) { return $true }
  } catch { return $false }
  finally { $ErrorActionPreference = $oldPreference }
}

if ((testCommand oh-my-posh) -and (Test-Path "${HOME}\omp-theme")) {
  # Import-Module oh-my-posh
  $env:POSH_GIT_ENABLED = $true
  $env:POSH_THEMES_PATH = "${HOME}\omp-theme"

  oh-my-posh --init --shell pwsh --config $env:POSH_THEMES_PATH/jandedobbeleer.omp.json | Invoke-Expression
}

if (testCommand Set-PsFzfOption) {
  # fzf
  # replace 'Ctrl+t' and 'Ctrl+r' with your preferred bindings:
  Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
  Set-PSFzfOption -EnableAliasFuzzyEdit -EnableAliasFuzzyFasd -EnableAliasFuzzyHistory -EnableAliasFuzzyKillProcess -EnableAliasFuzzySetLocation -EnableAliasFuzzySetEverything -EnableAliasFuzzyZLocation -EnableAliasFuzzyGitStatus
  Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
}

if (testCommand rg) {
  $env:FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow --glob "!.git/*"'
}

# Set Emacs keybindings for readline
# Set-PSReadLineOption -EditMode Emacs

# Set Prediction - PS 7.1 or above only
if ($PSVersionTable.PSVersion -ge 7.1) {
  Set-PSReadLineOption -PredictionSource History
  Set-PSReadLineOption -Colors @{ InlinePrediction = "#B3E5FF" }
}


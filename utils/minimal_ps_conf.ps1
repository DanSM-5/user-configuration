# Minimal config for Windows Powershell

$user_conf_path = "${HOME}\.usr_conf"
$user_scripts_path = "${HOME}\user-scripts"
$prj = "${HOME}\prj"
$user_config_cache = "${HOME}\.cache\.user_config_cache"

$env:PREFERRED_EDITOR = 'nvim'
$env:EDITOR = 'nvim'
$env:user_conf_path = "$user_conf_path"
$env:user_scripts_path = "$user_scripts_path"
$env:user_config_cache = $user_config_cache
$env:prj = "$prj"
$env:WIN_ROOT = "C:"
$env:WIN_HOME = $HOME
$env:HOME = $HOME
$env:COLORTERM = 'truecolor'
$env:PATHEXT += ";.py"
$env:PATH = "${HOME}\.local\bin;${env:PATH}"
$env:PATH = "${HOME}\bin;${env:PATH}"
$env:PATH += ";${env:user_scripts_path}\bin"

$WIN_HOME = $env:WIN_HOME
$WIN_ROOT = $env:WIN_ROOT
$EDITOR = $env:EDITOR
$PREFERRED_EDITOR = $env:PREFERRED_EDITOR

if (Get-Command -Name 'Set-PsFzfOption' -ErrorAction SilentlyContinue) {
  # fzf
  $env:FZF_DEFAULT_OPTS="--height 80% --layout=reverse --border"
  $altc = 'Alt+c'
  $alta = 'Alt+a'

  Set-PSFzfOption -EnableAliasFuzzyEdit `
    -PSReadlineChordProvider 'Ctrl+t' `
    -PSReadlineChordReverseHistory 'Ctrl+r' `
    -PSReadlineChordSetLocation $altc `
    -PSReadlineChordReverseHistoryArgs $alta `
    -EnableAliasFuzzyFasd `
    -EnableAliasFuzzyHistory `
    -EnableAliasFuzzyKillProcess `
    -EnableAliasFuzzySetEverything `
    -EnableAliasFuzzyZLocation `
    -EnableAliasFuzzyScoop `
    -TabExpansion `
    -EnableFd

  Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }

  # Import-module "$user_conf_path\utils\fzf-git.psm1"

  # Remove alias fgs from PSFzf
  if (Test-Path Alias:fgs) {
    Remove-Item Alias:fgs
    Set-Alias -Name fgst -Value Invoke-FuzzyGitStatus
  }

  function rfv () {
    & "${user_conf_path}\utils\rgfzf.ps1" @args
  }
}

$script:gsudoModule = "$(scoop prefix gsudo)/gsudoModule.psd1"
if (Test-Path "$script:gsudoModule") {
  Import-Module "$script:gsudoModule"
  if (Test-Path Alias:sudo) { Remove-Item Alias:sudo }
  Set-Alias -Name sudo -Value gsudo
}

if ((Get-Module PSReadLine).Version -ge '2.2') {
  Set-PSReadLineOption -PredictionSource History
  Set-PSReadLineOption -Colors @{ InlinePrediction = "#B3E5FF" }
  Set-PSReadLineKeyHandler -Chord "Ctrl+RightArrow" -Function ForwardWord
  Set-PSReadLineKeyHandler -Chord "Ctrl+LeftArrow" -Function BackwardWord
}

if (Get-Command -Name starship -ErrorAction SilentlyContinue) {
  Invoke-Expression (&starship init powershell)
}

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

if (Get-Command -Name 'eza' -ErrorAction SilentlyContinue) {
  function ll () { eza -AlF --icons --group-directories-first @args }
  function la () { eza -AF --icons --group-directories-first @args }
  function l () { eza -F --icons --group-directories-first @args }
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
    Set-Location "..${cmmd}"
  } catch {
    Write-Output "Couldn't go up $limit dirs."
  }
}

function .. {
  $index = if ($args) { $args } else { 0 }

  up $index
}

function ... {
  up 2
}

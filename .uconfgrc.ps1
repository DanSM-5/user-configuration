
############################################
#          GENERAL CONFIGURATIONS          #
############################################

# Follow structure conf folders and files
$user_conf_path = "$HOME\.usr_conf"
$user_scripts_path = "$HOME\user-scripts"
$prj = "$HOME\prj"

$env:PREFERED_EDITOR = 'nvim'
$env:EDITOR = 'nvim'

# Set true color support
$env:COLORTERM = 'truecolor'

function Test-Command {
  Param ($command)
  $oldPreference = $ErrorActionPreference
  $ErrorActionPreference = 'stop'
  try {
    if (Get-Command $command) { return $true }
  } catch { return $false }
  finally { $ErrorActionPreference = $oldPreference }
}

if ((Test-Command oh-my-posh) -and (Test-Path "${HOME}\omp-theme")) {
  # Import-Module oh-my-posh
  $env:POSH_THEMES_PATH = "${HOME}\omp-theme"
  # $global:POSH_TRANSIENT=$false

  # oh-my-posh --init --shell pwsh --config $env:POSH_THEMES_PATH/jandedobbeleer.omp.json | Invoke-Expression
  oh-my-posh init pwsh --config $env:POSH_THEMES_PATH/jandedobbeleer.omp.v2.json | Invoke-Expression
  # oh-my-posh --init --shell pwsh --config "$(scoop prefix oh-my-posh)/themes/jandedobbeleer.omp.json" | Invoke-Expression
}

if (Test-Command Set-PsFzfOption) {
  # fzf
  $color_gruvbox = '--colot="bg+:#3c3836,bg:#32302f,spinner:#fb4934,hl:#928374,fg:#ebdbb2,header:#928374,info:#8ec07c,pointer:#fb4934,marker:#fb4934,fg+:#ebdbb2,prompt:#fb4934,hl+:#fb4934"'
  $env:FZF_DEFAULT_OPTS="--height 80% --layout=reverse --border"
  # replace 'Ctrl+t' and 'Ctrl+r' with your preferred bindings:
  Set-PSFzfOption -EnableAliasFuzzyEdit `
    -PSReadlineChordProvider 'Ctrl+t' `
    -PSReadlineChordReverseHistory 'Ctrl+r' `
    -PSReadlineChordSetLocation 'Alt+c' `
    -PSReadlineChordReverseHistoryArgs 'Alt+a' `
    -EnableAliasFuzzyFasd `
    -EnableAliasFuzzyHistory `
    -EnableAliasFuzzyKillProcess `
    -EnableAliasFuzzySetEverything `
    -EnableAliasFuzzyZLocation `
    -EnableAliasFuzzyGitStatus `
    -EnableAliasFuzzyScoop `
    -TabExpansion `
    -EnableFd
    
    # -EnableAliasFuzzySetLocation `
  Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }

  # if (Test-Path Alias:fcd) { Remove-Item Alias:fcd }
  # Set-Alias -Name fcd -Value Invoke-FuzzySetLocation

  Import-module "$user_conf_path\utils\fzf-git.psm1"
}

if (Test-Command fzf) {

  $env:FZF_CTRL_R_OPTS = "
    --preview 'pwsh -NoLogo -NonInteractive -NoProfile -File $user_conf_path\utils\log-helper.ps1 {}' --preview-window up:3:hidden:wrap
    --bind 'ctrl-/:toggle-preview,ctrl-s:toggle-sort'
    --bind 'ctrl-y:execute-silent(pwsh -NoLogo -NonInteractive -NoProfile -File $user_conf_path\utils\copy-helper.ps1 {})+abort'
    --color header:italic
    --header 'Press CTRL-Y to copy command into clipboard'"

  $psFzfPreviewScript = "$user_conf_path\utils\PsFzfTabExpansion-Preview.ps1"

  $env:FZF_CTRL_T_OPTS = "
    --preview 'pwsh -NoProfile -NonInteractive -NoLogo -File $psFzfPreviewScript " + ". {}'
    --bind 'ctrl-/:change-preview-window(down|hidden|),alt-up:preview-page-up,alt-down:preview-page-down,ctrl-s:toggle-sort'"

  $env:FZF_ALT_C_OPTS = $env:FZF_CTRL_T_OPTS
}

# Add gsudo !! command
$script:gsudoModule = "$(scoop prefix gsudo)/gsudoModule.psd1"
if (Test-Path "$script:gsudoModule") {
  Import-Module "$script:gsudoModule"
}

if (Test-Command fd) {
    $env:FD_SHOW_OPTIONS = @(
      "--follow",
      "--hidden",
      "--no-ignore"
    )

    $env:FD_EXCLUDE_OPTIONS = @(
      '--exclude', 'AppData',
      '--exclude', 'Android',
      '--exclude', 'node_modules',
      '--exclude', 'tizen-studio',
      '--exclude', 'Library',
      '--exclude', 'scoop',
      '--exclude', 'vimfiles',
      '--exclude', 'aws'
      '--exclude', '.vscode-server',
      '--exclude', '.vscode-server-server',
      '--exclude', '.git',
      '--exclude', '.gitbook',
      '--exclude', '.gradle',
      '--exclude', '.nix-defexpr',
      '--exclude', '.azure',
      '--exclude', '.SpaceVim',
      '--exclude', '.cache',
      '--exclude', '.node-gyp',
      '--exclude', '.npm',
      '--exclude', '.nvm',
      '--exclude', '.colima',
      '--exclude', '.pyenv',
      '--exclude', '.DS_Store',
      '--exclude', '.vscode',
      '--exclude', '.vim',
      '--exclude', '.bun'
    )

  $FD_OPTIONS="$env:FD_SHOW_OPTIONS $env:FD_EXCLUDE_OPTIONS"
  $env:FZF_CTRL_T_COMMAND="fd $FD_OPTIONS"
  $env:FZF_ALT_C_COMMAND="fd --type d $FD_OPTIONS"
}

if (Test-Command rg) {
  $env:FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --glob "!.git" --glob "!node_modules" --follow'
}

# Set Emacs keybindings for readline
# Set-PSReadLineOption -EditMode Emacs

# Set Prediction - PS 7.1 or above only
if ($PSVersionTable.PSVersion -ge 7.1) {
  Set-PSReadLineOption -PredictionSource History
  Set-PSReadLineOption -Colors @{ InlinePrediction = "#B3E5FF" }
}

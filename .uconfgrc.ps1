
############################################
#          GENERAL CONFIGURATIONS          #
############################################

# Follow structure conf folders and files
$user_conf_path = "${HOME}${dirsep}.usr_conf"
$user_scripts_path = "${HOME}${dirsep}user-scripts"
$prj = "${HOME}${dirsep}prj"

$env:PREFERED_EDITOR = 'nvim'
$env:EDITOR = 'nvim'
$env:user_conf_path = "$user_conf_path"
$env:user_scripts_path = "$user_scripts_path"
$env:prj = "$prj"
$env:WIN_ROOT = if ($IsWindows) { "C:" } else { "" }
$env:WIN_HOME = "$HOME"
$env:HOME = if ($env:HOME) { $env:HOME } else { $HOME }

# Set true color support
$env:COLORTERM = 'truecolor'

$WIN_HOME = $env:WIN_HOME
$WIN_ROOT = $env:WIN_ROOT

if ((Test-Command oh-my-posh) -and (Test-Path "${HOME}${dirsep}omp-theme")) {
  # Import-Module oh-my-posh
  $env:POSH_THEMES_PATH = "${HOME}${dirsep}omp-theme"
  # $global:POSH_TRANSIENT=$false

  # oh-my-posh --init --shell pwsh --config $env:POSH_THEMES_PATH/jandedobbeleer.omp.json | Invoke-Expression
  oh-my-posh init pwsh --config "${env:POSH_THEMES_PATH}${dirsep}jandedobbeleer.omp.v2.json" | Invoke-Expression
  # oh-my-posh --init --shell pwsh --config "$(scoop prefix oh-my-posh)/themes/jandedobbeleer.omp.json" | Invoke-Expression
}

if (Test-Command Set-PsFzfOption) {
  # fzf
  $color_gruvbox = '--colot="bg+:#3c3836,bg:#32302f,spinner:#fb4934,hl:#928374,fg:#ebdbb2,header:#928374,info:#8ec07c,pointer:#fb4934,marker:#fb4934,fg+:#ebdbb2,prompt:#fb4934,hl+:#fb4934"'
  $env:FZF_DEFAULT_OPTS="--height 80% --layout=reverse --border"
  # replace 'Ctrl+t' and 'Ctrl+r' with your preferred bindings:
  $altc = if ($IsMacOS) { 'ç' } else { 'Alt+c' }
  $alta = if ($IsMacOS) { 'å' } else { 'Alt+a' }

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

    # -EnableAliasFuzzyGitStatus `
    # -EnableAliasFuzzySetLocation `
  Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }

  # if (Test-Path Alias:fcd) { Remove-Item Alias:fcd }
  # Set-Alias -Name fcd -Value Invoke-FuzzySetLocation

  Import-module "$user_conf_path\utils\fzf-git.psm1"
  # Import-module "$user_conf_path\utils\rgfzf.psm1"

  # Remove alias fgs from PSFzf
  if (Test-Path Alias:fgs) {
    Remove-Item Alias:fgs
    Set-Alias -Name fgst -Value Invoke-FuzzyGitStatus
  }
}

  $env:FD_SHOW_OPTIONS = @(
    '--follow',
    '--hidden',
    '--no-ignore'
  )

  $env:FD_EXCLUDE_OPTIONS = @(
    '--exclude', 'AppData',
    '--exclude', 'Android',
    '--exclude', 'OneDrive',
    '--exclude', 'Powershell',
    '--exclude', 'node_modules',
    '--exclude', 'tizen-studio',
    '--exclude', 'Library',
    '--exclude', 'scoop',
    '--exclude', 'vimfiles',
    '--exclude', 'aws',
    '--exclude', 'pipx',
    '--exclude', '.vscode-server',
    '--exclude', '.vscode-server-server',
    '--exclude', '.git',
    '--exclude', '.gitbook',
    '--exclude', '.gradle',
    '--exclude', '.nix-defexpr',
    '--exclude', '.azure',
    '--exclude', '.SpaceVim',
    '--exclude', '.cache',
    '--exclude', '.jenv',
    '--exclude', '.node-gyp',
    '--exclude', '.npm',
    '--exclude', '.nvm',
    '--exclude', '.colima',
    '--exclude', '.pyenv',
    '--exclude', '.DS_Store',
    '--exclude', '.vscode',
    '--exclude', '.vim',
    '--exclude', '.bun',
    '--exclude', '.nuget',
    '--exclude', '.dotnet',
    '--exclude', '.pnpm-store',
    '--exclude', '.pnpm*',
    '--exclude', '.zsh_history.*',
    '--exclude', '.android',
    '--exclude', '.sony',
    '--exclude', '.chocolatey',
    '--exclude', '.gem',
    '--exclude', '.jdks',
    '--exclude', '.nix-profile',
    '--exclude', '.sdkman',
    '--exclude', '__pycache__',
    '--exclude', '.local/pipx/*',
    '--exclude', '.local/share/*',
    '--exclude', '.local/state/*',
    '--exclude', '.local/lib/*',
    '--exclude', 'cache',
    '--exclude', 'browser-data',
    '--exclude', 'go',
    '--exclude', 'nodejs',
    '--exclude', 'podman',
    '--exclude', 'PlayOnLinux*',
    '--exclude', '.PlayOnLinux'
  )

$FD_OPTIONS = "$env:FD_SHOW_OPTIONS $env:FD_EXCLUDE_OPTIONS"

if (Test-Command fzf) {

  $env:FZF_CTRL_R_OPTS = "
    --preview 'pwsh -NoLogo -NonInteractive -NoProfile -File ${user_conf_path}${dirsep}utils${dirsep}log-helper.ps1 {}' --preview-window up:3:hidden:wrap
    --bind 'ctrl-/:toggle-preview,ctrl-s:toggle-sort'
    --bind 'ctrl-y:execute-silent(pwsh -NoLogo -NonInteractive -NoProfile -File ${user_conf_path}${dirsep}utils${dirsep}copy-helper.ps1 {})+abort'
    --color header:italic
    --header 'ctrl-y: Copy'"

  $fzfPreviewScript = "${user_conf_path}${dirsep}utils${dirsep}fzf-preview.ps1"

  $env:FZF_CTRL_T_OPTS = "
    --multi
    --ansi --cycle
    --header 'ctrl-a: All | ctrl-d: Dirs | ctrl-f: Files | ctrl-y: Copy | ctrl-t: CWD'
    --prompt 'All> '
    --bind `"ctrl-a:change-prompt(All> )+reload(fd $FD_OPTIONS --color=always)`"
    --bind `"ctrl-f:change-prompt(Files> )+reload(fd $FD_OPTIONS --color=always --type file)`"
    --bind `"ctrl-d:change-prompt(Dirs> )+reload(fd $FD_OPTIONS --color=always --type directory)`"
    --bind `"ctrl-t:change-prompt(CWD> )+reload(pwsh -NoLogo -NoProfile -NonInteractive -Command eza --color=always --all --dereference --oneline --group-directories-first `$PWD)`"
    --bind 'ctrl-y:execute-silent(pwsh -NoLogo -NonInteractive -NoProfile -File ${user_conf_path}${dirsep}utils${dirsep}copy-helper.ps1 {+f})+abort'
    --bind `"ctrl-o:execute-silent(pwsh -NoLogo -NoProfile -NonInteractive -Command Start-Process '{}')+abort`"
    --bind 'alt-a:select-all'
    --bind 'alt-d:deselect-all'
    --bind 'alt-f:first'
    --bind 'alt-l:last'
    --bind 'alt-c:clear-query'
    --preview 'pwsh -NoProfile -NonInteractive -NoLogo -File $fzfPreviewScript " + ". {}'
    --bind 'ctrl-/:change-preview-window(down|hidden|),alt-up:preview-page-up,alt-down:preview-page-down,ctrl-s:toggle-sort'"

  $env:FZF_ALT_C_OPTS = "
    --ansi
    --preview 'pwsh -NoProfile -NonInteractive -NoLogo -File $fzfPreviewScript " + ". {}'
    --bind 'ctrl-/:change-preview-window(down|hidden|),alt-up:preview-page-up,alt-down:preview-page-down,ctrl-s:toggle-sort'"
}

if (Test-Command fd) {
  $env:FZF_CTRL_T_COMMAND = "fd $FD_OPTIONS --color=always"
  $env:FZF_ALT_C_COMMAND = "fd --type directory --color=always $FD_OPTIONS"
}

if (Test-Command rg) {
  $env:FZF_DEFAULT_COMMAND = if ($IsWindows) {
    'rg --files --no-ignore --hidden --glob "!.git" --glob "!node_modules" --follow'
  } else {
    'rg --files --no-ignore --hidden --glob !.git --glob !node_modules --follow'
  }
}

# Set Emacs keybindings for readline
# Set-PSReadLineOption -EditMode Emacs

# Set Prediction - PS 7.1 or above only
if ($PSVersionTable.PSVersion -ge 7.1) {
  Set-PSReadLineOption -PredictionSource History
  Set-PSReadLineOption -Colors @{ InlinePrediction = "#B3E5FF" }
  Set-PSReadLineKeyHandler -Chord "Ctrl+RightArrow" -Function ForwardWord
  Set-PSReadLineKeyHandler -Chord "Ctrl+LeftArrow" -Function BackwardWord
}

# Windows only config
if ($IsWindows) {
  # Allow to execute python scripts directly
  $env:PATHEXT += ";.py"

  # Import the Chocolatey Profile that contains the necessary code to enable
  # tab-completions to function for `choco`.
  # Be aware that if you are missing these lines from your profile, tab completion
  # for `choco` will not function.
  # See https://ch0.co/tab-completion for details.
  $ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
  if (Test-Path -Path $ChocolateyProfile -ErrorAction SilentlyContinue) {
    Import-Module "$ChocolateyProfile"
  }

  if (Test-Command 'lf.exe') {
    Set-PSReadLineKeyHandler -Chord Ctrl+o -ScriptBlock {
      [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert('lfcd.ps1')
      [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }

    function lf () {
      # Important to use @args and no $args to forward arguments
      lf.ps1 @args
    }
  }


$alto = if ($IsMacOS) { 'ø' } else { 'Alt+o' }
Set-PSReadLineKeyHandler -Chord $alto -ScriptBlock {
  [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
  [Microsoft.PowerShell.PSConsoleReadLine]::Insert('cprj')
  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

# Commented test for scoop as it is unlikely to not be installed on windows
# if (Test-Command scoop) {
  # Add gsudo !! command
  $script:gsudoModule = "$(scoop prefix gsudo)/gsudoModule.psd1"
  if (Test-Path "$script:gsudoModule") {
    Import-Module "$script:gsudoModule"
    if (Test-Path Alias:sudo) { Remove-Item Alias:sudo }
    Set-Alias -Name sudo -Value gsudo
  }
# }
} elseif ($IsMacOS) {
  # Polifyl for some functions
  $env:TEMP = "/tmp"
  function start () {
    open @args
  }

  # Macos won't let me usr ctrl for moving words
  # It must be alt 🫠
  Set-PSReadLineKeyHandler -Chord "Alt+RightArrow" -Function ForwardWord
  Set-PSReadLineKeyHandler -Chord "Alt+LeftArrow" -Function BackwardWord
}

if ((
  Test-Path -Path "${env:user_scripts_path}${dirsep}bin" -ErrorAction SilentlyContinue
) -and (
  -not (Test-Command 'path_end')
)) {
  $env:PATH += ";${env:user_scripts_path}${dirsep}bin"
}

# Temporary hold the first entries in the path
$firstpathentries = $env:PATH -split $pathsep | Select -First 10
if (-not ($firstpathentries -Match ([regex]::Escape("${HOME}${dirsep}bin")))) {
  $env:PATH = "${HOME}${dirsep}bin${pathsep}${env:PATH}"
}

if (-not ($firstpathentries -Match ([regex]::Escape("${HOME}${dirsep}.local${dirsep}bin")))) {
  $env:PATH = "${HOME}${dirsep}.local${dirsep}bin${pathsep}${env:PATH}"
}
# Remove firstpathentries
Remove-Variable firstpathentries


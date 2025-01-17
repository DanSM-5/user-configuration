
############################################
#          GENERAL CONFIGURATIONS          #
############################################

# Follow structure conf folders and files

# Configuration location
$user_conf_path = if ($env:user_conf_path) { $env:user_conf_path } else { "${HOME}${dirsep}.usr_conf" }
# Scripts location
$user_scripts_path = if ($env:user_scripts_path) { $env:user_scripts_path } else { "${HOME}${dirsep}user-scripts" }
# Project specific files location
$prj = if ($env:prj) { $env:prj } else { "${HOME}${dirsep}prj" }
# Cache files location
$user_config_cache = if ($env:user_config_cache) { $env:user_config_cache } else { "${HOME}${dirsep}.cache${dirsep}.user_config_cache" }

$env:PREFERRED_EDITOR = 'nvim'
$env:EDITOR = $env:PREFERRED_EDITOR
$env:VISUAL = $env:PREFERRED_EDITOR
$env:user_conf_path = "$user_conf_path"
$env:user_scripts_path = "$user_scripts_path"
$env:user_config_cache = $user_config_cache
$env:prj = "$prj"
$env:WIN_ROOT = if ($IsWindows) { "C:" } else { "" }
$env:WIN_HOME = "$HOME"
$env:HOME = if ($env:HOME) { $env:HOME } else { $HOME }

# Set true color support
$env:COLORTERM = 'truecolor'
# Set it here for now
$env:TERM = if ($env:TERM) { $env:TERM } else { 'xterm-256color' }

$WIN_HOME = $env:WIN_HOME
$WIN_ROOT = $env:WIN_ROOT
$EDITOR = $env:EDITOR
$VISUAL = $env:VISUAL
$PREFERRED_EDITOR = $env:PREFERRED_EDITOR
# Sets theme to use in bat
$env:BAT_THEME = 'OneHalfDark'

if ((Test-Command oh-my-posh) -and (Test-Path "${HOME}${dirsep}omp-theme")) {
  # Import-Module oh-my-posh
  $env:POSH_THEMES_PATH = "${HOME}${dirsep}omp-theme"
  # $global:POSH_TRANSIENT=$false

  # oh-my-posh --init --shell pwsh --config $env:POSH_THEMES_PATH/jandedobbeleer.omp.json | Invoke-Expression
  oh-my-posh init pwsh --config "${env:POSH_THEMES_PATH}${dirsep}jandedobbeleer.omp.v3.json" | Invoke-Expression
  # oh-my-posh --init --shell pwsh --config "$(scoop prefix oh-my-posh)/themes/jandedobbeleer.omp.json" | Invoke-Expression
}

if (Test-Command Set-PsFzfOption) {
  # fzf
  # $color_gruvbox = '--colot="bg+:#3c3836,bg:#32302f,spinner:#fb4934,hl:#928374,fg:#ebdbb2,header:#928374,info:#8ec07c,pointer:#fb4934,marker:#fb4934,fg+:#ebdbb2,prompt:#fb4934,hl+:#fb4934"'

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

  Import-module "$env:user_conf_path\utils\fzf-git.psm1"
  # Import-module "$env:user_conf_path\utils\rgfzf.psm1"

  # Remove alias fgs from PSFzf
  if (Test-Path Alias:fgs) {
    Remove-Item Alias:fgs
    Set-Alias -Name fgst -Value Invoke-FuzzyGitStatus
  }
}

if (Test-Command fzf) {
  $SHOME = $HOME.Replace('\', '/')
  $SCONF = $user_conf_path.Replace('\', '/')
  $env:FZF_HIST_DIR = "$SHOME/.cache/fzf-history" 

  # temporary variables
  $fzfPreviewScript = "$SCONF/utils/fzf-preview.ps1"
  $fzfFdScript = "$SCONF/fzf/ctrl_t_command.ps1"
  $fzfCopyHelper = "$SCONF/utils/copy-helper.ps1"

  if (!(Test-Path -PathType Container -Path $env:FZF_HIST_DIR -ErrorAction SilentlyContinue)) {
    New-Item -Path $env:FZF_HIST_DIR -ItemType Directory -ErrorAction SilentlyContinue
  }

  $env:FZF_DEFAULT_OPTS="--history=$env:FZF_HIST_DIR/fzf-history-default"
  $env:FZF_DEFAULT_OPTS_FILE="$SCONF/fzf/fzf-default-opts"

  $env:FZF_CTRL_R_OPTS = "
    --history=$env:FZF_HIST_DIR/fzf-history-ctrlr
    --preview 'pwsh -NoLogo -NonInteractive -NoProfile -File ${env:user_conf_path}${dirsep}utils${dirsep}log-helper.ps1 {}' --preview-window up:3:hidden:wrap
    --bind 'alt-a:select-all'
    --bind 'alt-d:deselect-all'
    --bind 'alt-f:first'
    --bind 'alt-l:last'
    --bind 'alt-c:clear-query'
    --bind 'ctrl-/:toggle-preview,ctrl-s:toggle-sort'
    --bind 'ctrl-y:execute-silent(pwsh -NoLogo -NonInteractive -NoProfile -File ${env:user_conf_path}${dirsep}utils${dirsep}copy-helper.ps1 {})+abort'
    --color header:italic
    --prompt 'History> '
    --ansi --cycle
    --header 'ctrl-y: Copy'"

  # Evaluate the use of
  # --with-shell 'pwsh -NoLogo -NonInteractive -NoProfile -C'
  # It fails in preview script with multi word files unlike current implementation
  $env:FZF_CTRL_T_OPTS = "
    --history=$env:FZF_HIST_DIR/fzf-history-ctrlt
    --multi
    --ansi --cycle
    --header 'ctrl-a: All | ctrl-d: Dirs | ctrl-f: Files | ctrl-y: Copy | ctrl-t: CWD'
    --prompt 'All> '
    --color header:italic
    --bind `"ctrl-a:change-prompt(All> )+reload($fzfFdScript)`"
    --bind `"ctrl-f:change-prompt(Files> )+reload($fzfFdScript --type file)`"
    --bind `"ctrl-d:change-prompt(Dirs> )+reload($fzfFdScript --type directory)`"
    --bind `"ctrl-t:change-prompt(CWD> )+reload(pwsh -NoLogo -NoProfile -NonInteractive -Command eza --color=always --all --dereference --oneline --group-directories-first `$PWD)`"
    --bind 'ctrl-y:execute-silent($fzfCopyHelper {+f})+abort'
    --bind `"ctrl-o:execute-silent(pwsh -NoLogo -NoProfile -NonInteractive -Command Start-Process '{}')+abort`"
    --bind 'alt-a:select-all'
    --bind 'alt-d:deselect-all'
    --bind 'alt-f:first'
    --bind 'alt-l:last'
    --bind 'alt-c:clear-query'
    --preview-window '60%'
    --preview '$fzfPreviewScript " + ". {}'
    --with-shell 'pwsh -NoLogo -NonInteractive -NoProfile -Command'
    --bind 'ctrl-/:change-preview-window(down|hidden|),alt-up:preview-page-up,alt-down:preview-page-down,ctrl-s:toggle-sort'"

  $env:FZF_ALT_C_OPTS = "
    --history=$env:FZF_HIST_DIR/fzf-history-altc
    --ansi --cycle
    --prompt 'CD> '
    --color header:italic
    --preview-window '60%'
    --preview '$fzfPreviewScript " + ". {}'
    --bind 'alt-a:select-all'
    --bind 'alt-d:deselect-all'
    --bind 'alt-f:first'
    --bind 'alt-l:last'
    --bind 'alt-c:clear-query'
    --with-shell 'pwsh -NoLogo -NonInteractive -NoProfile -Command'
    --bind `"ctrl-a:change-prompt(CD> )+reload($fzfFdScript --color=always)`"
    --bind `"ctrl-t:change-prompt(CWD> )+reload(pwsh -NoLogo -NoProfile -NonInteractive -Command eza -A --show-symlinks --color=always --only-dirs --dereference --no-quotes --oneline `$PWD)`"
    --bind 'ctrl-/:change-preview-window(down|hidden|),alt-up:preview-page-up,alt-down:preview-page-down,ctrl-s:toggle-sort'"

  Remove-Variable SHOME
  Remove-Variable SCONF
  Remove-Variable fzfPreviewScript
  Remove-Variable fzfFdScript
  Remove-Variable fzfCopyHelper
}

if (Test-Command fd) {
  # Use With-UTF8 wrapper for commands on windows. This helps files that use
  # unicode characters being displayed correctly.
  if ($IsWindows) {
    # $env:FZF_CTRL_T_COMMAND = "With-UTF8 { fd $FD_OPTIONS --color=always }"
    # $env:FZF_ALT_C_COMMAND = "With-UTF8 { fd --type directory --color=always $FD_OPTIONS }"
    $env:FZF_CTRL_T_COMMAND = "With-UTF8 { $user_conf_path/fzf/ctrl_t_command.ps1 }"
    $env:FZF_ALT_C_COMMAND = "With-UTF8 { $user_conf_path/fzf/alt_c_command.ps1 }"
  } else {
    # $env:FZF_CTRL_T_COMMAND = "fd $FD_OPTIONS --color=always"
    # $env:FZF_ALT_C_COMMAND = "fd --type directory --color=always $FD_OPTIONS"
    $env:FZF_CTRL_T_COMMAND = "$user_conf_path/fzf/ctrl_t_command.ps1"
    $env:FZF_ALT_C_COMMAND = "$user_conf_path/fzf/alt_c_command.ps1"
  }
}

if (Test-Command rg) {
  $env:FZF_DEFAULT_COMMAND = if ($IsWindows) {
    'rg --files --no-ignore --hidden --glob "!plugged" --glob "!.git" --glob "!node_modules" --follow'
  } else {
    'rg --files --no-ignore --hidden --glob !plugged --glob !.git --glob !node_modules --follow'
  }
}

# For PowerShellRun
if (Get-Command -Name Enable-PSRunEntry -ErrorAction SilentlyContinue) {
  Enable-PSRunEntry -Category All
  Set-PSReadLineKeyHandler -Chord 'ctrl+o,r' -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert('Invoke-PSRun')
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
  }
}

# Set Emacs keybindings for readline
# Set-PSReadLineOption -EditMode Emacs

# Set Prediction if PSReadLine 2.2 or above only
if ((Get-Module PSReadLine).Version -ge '2.2') {
  Set-PSReadLineOption -PredictionSource History
  Set-PSReadLineOption -Colors @{ InlinePrediction = "#B3E5FF" }
  Set-PSReadLineKeyHandler -Chord "Ctrl+RightArrow" -Function ForwardWord
  Set-PSReadLineKeyHandler -Chord "Ctrl+LeftArrow" -Function BackwardWord
  Set-PSReadLineKeyHandler -Chord "Ctrl+n" -Function HistorySearchForward
  Set-PSReadLineKeyHandler -Chord "Ctrl+p" -Function HistorySearchBackward
}

# Set colors as if gnu utils for consistency
# LS_COLORS string generated with vivid
$env:LS_COLORS = Get-Content "${env:user_conf_path}${dirsep}.ls_colors"

Import-Module DirColors -ErrorAction SilentlyContinue
if (Get-Module DirColors -ErrorAction SilentlyContinue) {
  $null = ConvertFrom-LSColors -LSColors "$env:LS_COLORS"
}

# Keybinding for lfcd
Set-PSReadLineKeyHandler -Chord 'ctrl+o,ctrl+l' -ScriptBlock {
  [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
  [Microsoft.PowerShell.PSConsoleReadLine]::Insert('lfcd')
  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

# Windows only config
if ($IsWindows) {
  # Allow to execute python scripts directly
  $env:PATHEXT += ";.py"

  # Delete word behind cursor
  Set-PSReadLineKeyHandler -Chord ctrl-backspace -Function BackwardDeleteWord
  # Delete text in front of cursor
  Set-PSReadLineKeyHandler -Chord ctrl-delete -Function ForwardDeleteLine

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
    function lfcd () {
      $cdpath = & "$env:user_scripts_path${dirsep}bin${dirsep}lfcd.ps1" @args
      if (Test-Path -Path $cdpath -PathType Container -ErrorAction SilentlyContinue) {
        Set-Location $cdpath
      } else {
        $cdpath
      }
    }

    function lf () {
      # Important to use @args and no $args to forward arguments
      lf.ps1 @args
    }
  }


# $alto = if ($IsMacOS) { 'ø' } else { 'Alt+o' }
# $ctrlo_p = @('ctrl+o', 'p')
Set-PSReadLineKeyHandler -Chord 'ctrl+o,p' -ScriptBlock {
  # $line = $cursor = $null
  # Get current content
  # [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref] $line, [ref] $cursor)
  # Clean line
  [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
  # Add call to cprj
  [Microsoft.PowerShell.PSConsoleReadLine]::Insert('cprj')
  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()

  # TODO: The logic below doesn't work because all contents in the prompt happens
  # before the AcceptLine call. Need something like 'print -z' from zsh to add content afterwards

  # Ensure line is clean after dir change
  # [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
  # $content = $line.Replace("`r", "").Replace("`t", "  ").Trim()
  # [Microsoft.PowerShell.PSConsoleReadLine]::Insert($content)
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

# Open content of prompt in editor
# It mimics bash ctrl-x ctrl-e
# Readline example: https://gist.github.com/mklement0/290ef7cdbdf0db274d6da64fade46929
# PSReadline documentation: https://learn.microsoft.com/en-us/dotnet/api/microsoft.powershell.psconsolereadline?view=powershellsdk-1.1.0&viewFallbackFrom=powershellsdk-7.4.0
Set-PSReadLineKeyHandler -Chord 'ctrl+o,e' -ScriptBlock {
  $line = $cursor = $proc = $null
  $editorArgs = @()
  $editor = if ($env:PREFERRED_EDITOR) { $env:PREFERRED_EDITOR }
    elseif ($env:EDITOR) { $env:EDITOR }
    else { 'vim' }

  try {
    $tmpf = New-TemporaryFile
    $tmp_file = $tmpf.FullName.Replace('.tmp', '.ps1')
    Move-Item $tmpf.FullName $tmp_file
    # Get current content
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref] $line, [ref] $cursor)
    # If (n)vim, start at last line
    if ( $editor -Like '*vim' ) {
      $editorArgs += '+'
    }
    # Add current content of prompt to buffer
    $line = $line.Replace("`r", "").Trim()
    [System.IO.File]::WriteAllLines($tmp_file, $line, [System.Text.UTF8Encoding]($false))

    $editorArgs += $tmp_file
    # Start editor and wait for it to close
    $proc = Start-Process $editor -NoNewWindow -PassThru -ArgumentList $editorArgs
    $proc.WaitForExit()
    $proc = $null
    # Clean prompt
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    $content = (Get-Content -Path $tmp_file -Raw -Encoding UTF8).Replace("`r","").Replace("`t", "  ").Trim()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($content)
    # [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
  } finally {
    # Cleanup
    $proc = $null
    if (Test-Path -Path $tmpf.FullName -PathType Leaf -ErrorAction SilentlyContinue) {
      Remove-Item -Force $tmpf.FullName
    }
    Remove-Item -Force $tmp_file
  }
}

# From PsFzf
# HACK: workaround for fact that PSReadLine seems to clear screen
# after keyboard shortcut action is executed, and to work around a UTF8
# PSReadLine issue (GitHub PSFZF issue #71)
function InvokePromptHack()
{
	$previousOutputEncoding = [Console]::OutputEncoding
	[Console]::OutputEncoding = [Text.Encoding]::UTF8

	try {
		[Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
	} finally {
		[Console]::OutputEncoding = $previousOutputEncoding
	}
}

Set-PSReadLineKeyHandler -Chord 'ctrl+o,i' -ScriptBlock {
  $line = $cursor = $proc = $null
  # Get current content
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref] $line, [ref] $cursor)
  $selected = emoji
  if (!$selected) { return }

  InvokePromptHack

  $emojis = if ($selected -is [system.array]) { $selected -Join '' } else { $selected }
  if ($line.Length -eq 0) {
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($emojis)
  } else {
    [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
      $cursor, # Position to start replacing
      0,       # How many characters to replace
      $emojis  # Content to add for replacement
    )
  }
}

if (Test-Command carapace) {
  # ~/.config/powershell/Microsoft.PowerShell_profile.ps1
  $env:CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
  Set-PSReadLineOption -Colors @{ "Selection" = "`e[7m" }
  Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
  carapace _carapace | Out-String | Invoke-Expression
}

$addlast = ""
$addfirst = ""
$userscriptbin = "${env:user_scripts_path}${dirsep}bin"
$userbin = "${HOME}${dirsep}bin"
$userlocalbin = "${HOME}${dirsep}.local${dirsep}bin"
[System.Collections.Generic.List[string]] $pathlist = foreach ($pathentry in ($env:PATH -Split $pathsep)) {
  if (!$pathentry) { continue }
  $pathentry
}

# Ensure userscriptbin is last entry
if ((
  Test-Path -Path $userscriptbin -ErrorAction SilentlyContinue
) -and (
  -not ($pathlist.LastIndexOf($userscriptbin) -eq ($pathentry.Count - 1))
)) {
  # Remove $HOME/user-scripts/bin from list
  while ($pathlist.Remove($userscriptbin)) { continue }
  $addlast = "${pathsep}${userscriptbin}"
}

# Ensure userbin is first entry
if ($pathlist[0] -ne $userbin) {
  # Remove $HOME/bin from list
  while ($pathlist.Remove($userbin)) { continue }
  # Remove $HOME/.local/bin from list
  while ($pathlist.Remove($userlocalbin)) { continue }
  # First paths that should appear in PATH
  $addfirst = "${userbin}${pathsep}${userlocalbin}${pathsep}"
}

$env:PATH = "${addfirst}$($pathlist -Join $pathsep)${addlast}"

# if (-not ($firstpathentries -Match ([regex]::Escape("${HOME}${dirsep}bin")))) {

# Remove temporary variables
Remove-Variable userscriptbin
Remove-Variable userbin
Remove-Variable userlocalbin
Remove-Variable addfirst
Remove-Variable addlast
Remove-Variable pathlist

# Add tab completions
foreach ($file in (Get-ChildItem "$env:user_conf_path${dirsep}completions${dirsep}pwsh")) {
  . $file
}


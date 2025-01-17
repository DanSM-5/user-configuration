# Minimal config for Windows Powershell v5

$user_conf_path = if ($env:user_conf_path) { $env:user_conf_path } else { "$HOME\.usr_conf" }
$user_scripts_path = if ($env:user_scripts_path) { $env:user_scripts_path } else { "$HOME\user-scripts" }
$prj = if ($env:prj) { $env:prj } else { "$HOME\prj" }
$user_config_cache = "$HOME\.cache\.user_config_cache"

$env:PREFERRED_EDITOR = if (Get-Command -Name 'nvim' -ErrorAction SilentlyContinue) { 'nvim' } else { 'vim' }
$env:EDITOR = $env:PREFERRED_EDITOR
$env:user_conf_path = $user_conf_path
$env:user_scripts_path = $user_scripts_path
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

function gpr { Set-Location $env:prj }
function gus { Set-Location $env:user_scripts_path }
function guc { Set-Location $env:user_conf_path }
function gvc { Set-Location "${HOME}\.SpaceVim.d" }
function goh { Set-Location "$HOME"}
function ecf () { & $env:PREFERRED_EDITOR $PROFILE }
function egc () { & $env:PREFERRED_EDITOR "$env:user_conf_path/utils/minimal_ps_conf.ps1" }

function ccd () {
  $filepath = Get-Clipboard
  $filepath = $filepath.Trim()

  if (-not "$filepath") {
    Write-Error "No path"
    return
  }

  if (Test-Path -Path $filepath -PathType Leaf -ErrorAction SilentlyContinue) {
    $filepath = [system.IO.Path]::GetDirectoryName($filepath)
  } elseif (!(Test-Path -Path $filepath -PathType Container -ErrorAction SilentlyContinue)) {
    Write-Error "Invalid path '$filepath'"
    return
  }

  Set-Location "$filepath"
}

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

  Import-module "$user_conf_path\utils\fzf-git.psm1"

  # Remove alias fgs from PSFzf
  if (Test-Path Alias:fgs) {
    Remove-Item Alias:fgs
    Set-Alias -Name fgst -Value Invoke-FuzzyGitStatus
  }

  function rfv () {
    & "${user_conf_path}\utils\rgfzf.ps1" @args
  }
}

if (-not (Test-Path env:OutputEncodingBackupSet)) {
  $OutputEncodingBackup = [Console]::OutputEncoding
  $env:OutputEncodingBackupSet = 'true'
}

function Switch-Utf8 () {
    param([switch] $Enable = $false)

  if ($Enable) {
    [Console]::OutputEncoding = New-Object System.Text.Utf8Encoding
  } else {
    [Console]::OutputEncoding = $OutputEncodingBackup
  }
}

if (Test-Path Alias:sutf8) { Remove-Item Alias:sutf8 }
Set-Alias -Name sutf8 -Value Switch-Utf8

if (Test-Path Alias:utf8) { Remove-Item Alias:utf8 }
Set-Alias -Name utf8 -Value With-UTF8

if (Get-Command -Name 'fzf' -ErrorAction SilentlyContinue) {
  $SHOME = $HOME.Replace('\', '/')
  $SCONF = $user_conf_path.Replace('\', '/')
  $env:FZF_HIST_DIR = "$SHOME/.cache/fzf-history" 

  if (!(Test-Path -PathType Container -Path $env:FZF_HIST_DIR -ErrorAction SilentlyContinue)) {
    New-Item -Path $env:FZF_HIST_DIR -ItemType Directory -ErrorAction SilentlyContinue
  }

  $env:FZF_DEFAULT_OPTS="--history=$env:FZF_HIST_DIR/fzf-history-default"
  $env:FZF_DEFAULT_OPTS_FILE="$SCONF/fzf/fzf-default-opts"

  # temporary variables
  $fzfPreviewScript = "$SCONF/utils/fzf-preview.ps1"
  $fzfFdScript = "$SCONF/fzf/ctrl_t_command.ps1"
  $fzfCopyHelper = "$SCONF/utils/copy-helper.ps1"

  $env:FZF_CTRL_R_OPTS = "
    --preview 'pwsh -NoLogo -NonInteractive -NoProfile -File ${env:user_conf_path}\utils\log-helper.ps1 {}' --preview-window up:3:hidden:wrap
    --bind 'ctrl-/:toggle-preview,ctrl-s:toggle-sort'
    --bind 'ctrl-y:execute-silent(pwsh -NoLogo -NonInteractive -NoProfile -File ${env:user_conf_path}\utils\copy-helper.ps1 {})+abort'
    --color header:italic
    --header 'ctrl-y: Copy'"

  $env:FZF_CTRL_T_OPTS = "
    --multi
    --ansi --cycle
    --header 'ctrl-a: All | ctrl-d: Dirs | ctrl-f: Files | ctrl-y: Copy | ctrl-t: CWD'
    --prompt 'All> '
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
    --with-shell 'powershell -NoLogo -NonInteractive -NoProfile -Command'
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
    --with-shell 'powershell -NoLogo -NonInteractive -NoProfile -Command'
    --bind `"ctrl-a:change-prompt(CD> )+reload($fzfFdScript --color=always)`"
    --bind `"ctrl-t:change-prompt(CWD> )+reload(pwsh -NoLogo -NoProfile -NonInteractive -Command eza -A --show-symlinks --color=always --only-dirs --dereference --no-quotes --oneline `$PWD)`"
    --bind 'ctrl-/:change-preview-window(down|hidden|),alt-up:preview-page-up,alt-down:preview-page-down,ctrl-s:toggle-sort'"

  Remove-Variable SHOME
  Remove-Variable SCONF
  Remove-Variable fzfPreviewScript
  Remove-Variable fzfFdScript
  Remove-Variable fzfCopyHelper
}

if (Get-Command -Name 'fd' -ErrorAction SilentlyContinue) {
  # $env:FZF_CTRL_T_COMMAND = "With-UTF8 { fd $FD_OPTIONS --color=always }"
  # $env:FZF_ALT_C_COMMAND = "With-UTF8 { fd --type directory --color=always $FD_OPTIONS }"
  $env:FZF_CTRL_T_COMMAND = "With-UTF8 { $user_conf_path/fzf/ctrl_t_command.ps1 }"
  $env:FZF_ALT_C_COMMAND = "With-UTF8 { $user_conf_path/fzf/alt_c_command.ps1 }"
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
  Set-PSReadLineKeyHandler -Chord "Ctrl+n" -Function HistorySearchForward
  Set-PSReadLineKeyHandler -Chord "Ctrl+p" -Function HistorySearchBackward
}

Import-Module DirColors -ErrorAction SilentlyContinue
if (Get-Module DirColors -ErrorAction SilentlyContinue) {
  # Set colors as if gnu utils for consistency
  # LS_COLORS string generated with vivid
  $env:LS_COLORS = Get-Content "${env:user_conf_path}\.ls_colors"

  $null = ConvertFrom-LSColors -LSColors "$env:LS_COLORS"
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
} else {
  function listFiles () {
    [CmdletBinding()]
    param(
      [String]
      $DirectoryName = '.',
      [String]
      [Parameter(ValueFromPipeline = $true)]
      $PathFromPipe,
      [Switch]
      $All
    )

    $path = if ($PathFromPipe) { $PathFromPipe } else { $DirectoryName }
    $path = [IO.Path]::GetFullPath([IO.Path]::Combine((Get-Location -PSProvider FileSystem).ProviderPath, $path))

    # $position = $PSCmdlet.MyInvocation.PipelinePosition
    # $length = $PSCmdlet.MyInvocation.PipelineLength

    $filesFound = Get-ChildItem -Path $path -Force:$All -ErrorAction SilentlyContinue | % {
      $fileName = $_.Name

      # Return filename as it, no need to format for pipeline
      if ($position -ne $length) {
        return $fileName
      }

      $item = [PSCustomObject] @{ Content = '' }

      # if (Test-Path -PathType Leaf -Path f) {}
      if ($_.Attributes -Band [IO.FileAttributes]::ReparsePoint) {
        $fileName = "$fileName@"
      } elseif ($_.Attributes -Band [IO.FileAttributes]::Directory) {
        $fileName = "$fileName/"
      } elseif ($_.Attributes -Band [IO.FileAttributes]::Archive) {
        $fileName = "$fileName*"
      }

      $item.Content = $fileName
        return $item
    }

    # Return object as is if not in a pipeline
    # if ($position -ne $length) {
    #   return $filesFound
    # }

    if ($filesFound.Length -eq 0) {
      return $filesFound
    }

    # Set number of columns
    $columns = if ($filesFound.Length -gt 100) { 4 } elseif ($filesFound.Length -gt 20) { 3 } else { 2 }
    # Format output to be displayed
    $filesFound |
      Sort-Object -Property Content |
      Format-Wide -Column $columns -Property Content
  }

  function ll () { Get-ChildItem @args }
  function la () { listFiles @args -All }
  function l () { listFiles @args }
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


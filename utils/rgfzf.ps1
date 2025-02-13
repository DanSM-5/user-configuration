#!/usr/bin/env pwsh

# This module is taken from PSFzf
# Ref: https://github.com/kelleyma49/PSFzf/blob/master/PSFzf.Functions.ps1

$script:FzfLocation = 'fzf'
$script:OverrideFzfDefaults = $null

function FindFzf()
{
	if ($script:IsWindows) {
		$AppNames = @('fzf-*-windows_*.exe','fzf.exe')
	} elseif ($IsMacOS) {
    $AppNames = @('fzf-*-darwin_*','fzf')
  } elseif ($IsLinux) {
    $AppNames = @('fzf-*-linux_*','fzf')
  } else {
    throw 'Unknown OS'
	}

    # find it in our path:
    $script:FzfLocation = $null
    $AppNames | ForEach-Object {
        if ($null -eq $script:FzfLocation) {
            $result = Get-Command $_ -ErrorAction Ignore
            $result | ForEach-Object {
                $script:FzfLocation = Resolve-Path $_.Source
            }
        }
    }

    if ($null -eq $script:FzfLocation) {
        throw 'Failed to find fzf binary in PATH.  You can download a binary from this page: https://github.com/junegunn/fzf/releases'
    }
}

function Get-EditorLaunchOld() {
    param($FileList, $LineNum = 0)
    # HACK to check to see if we're running under Visual Studio Code.
    # If so, reuse Visual Studio Code currently open windows:
    $editorOptions = ''
    if (-not [string]::IsNullOrEmpty($env:PSFZF_EDITOR_OPTIONS)) {
        $editorOptions += ' ' + $env:PSFZF_EDITOR_OPTIONS
    }
    if ($null -ne $env:VSCODE_PID) {
        $editor = 'code'
        $editorOptions += ' --reuse-window'
    }
    else {
        $editor = if ($env:VISUAL) { $env:VISUAL }elseif ($env:EDITOR) { $env:EDITOR }
        if ($null -eq $editor) {
            if (!$IsWindows) {
                $editor = 'vim'
            }
            else {
                $editor = 'code'
            }
        }
    }

    if ($editor -eq 'code' -or $editor -eq 'code-insiders' -or $editor -eq 'codium') {
        if ($FileList -is [array] -and $FileList.length -gt 1) {
            for ($i = 0; $i -lt $FileList.Count; $i++) {
                $FileList[$i] = '"{0}"' -f $(Resolve-Path $FileList[$i].Trim('"'))
            }
            "$editor$editorOptions {0}" -f ($FileList -join ' ')
        }
        else {
            "$editor$editorOptions --goto ""{0}:{1}""" -f $(Resolve-Path $FileList.Trim('"')), $LineNum
        }
    }
    elseif ($editor -match '[gn]?vi[m]?') {
        if ($FileList -is [array] -and $FileList.length -gt 1) {
            for ($i = 0; $i -lt $FileList.Count; $i++) {
                $FileList[$i] = '"{0}"' -f $(Resolve-Path $FileList[$i].Trim('"'))
            }
            "$editor$editorOptions {0}" -f ($FileList -join ' ')
        }
        else {
            "$editor$editorOptions ""{0}"" +{1}" -f $(Resolve-Path $FileList.Trim('"')), $LineNum
        }
    }
    elseif ($editor -eq 'nano') {
        if ($FileList -is [array] -and $FileList.length -gt 1) {
            for ($i = 0; $i -lt $FileList.Count; $i++) {
                $FileList[$i] = '"{0}"' -f $(Resolve-Path $FileList[$i].Trim('"'))
            }
            "$editor$editorOptions {0}" -f ($FileList -join ' ')
        }
        else {
            "$editor$editorOptions  +{1} ""{0}""" -f $(Resolve-Path $FileList.Trim('"')), $LineNum
        }
    }
    else {
        # select the first file as we don't know if the editor supports opening multiple files from the cmd line
        if ($FileList -is [array] -and $FileList.length -gt 1) {
            "$editor$editorOptions ""{0}""" -f $(Resolve-Path $FileList[0].Trim('"'))
        }
        else {
            "$editor$editorOptions ""{0}""" -f $(Resolve-Path $FileList.Trim('"'))
        }
    }
}

function Get-EditorLaunch() {
  # Windows temporary file requires additional quotes around template for '+f'
  $TEMP_FILE = if ($IsWindows) { '"{+f}"' } else { '{+f}' }
  $editor = $null
  $editorOptions = ''

  # HACK to check to see if we're running under Visual Studio Code.
  # If so, reuse Visual Studio Code currently open windows:
  if ($null -ne $env:VSCODE_PID) {
    $editor = 'code'
    $editorOptions += ' --reuse-window'
  }
  else {
    $editor = if ($env:PREFERRED_EDITOR) { $env:PREFERRED_EDITOR }
      elseif ($env:VISUAL) { $env:VISUAL }
      elseif ($env:EDITOR) { $env:EDITOR }
      else { 'nvim' }
  }
  if (-not [string]::IsNullOrEmpty($env:PSFZF_EDITOR_OPTIONS)) {
    $editorOptions += ' ' + $env:PSFZF_EDITOR_OPTIONS
  }

  if ($editor -match '[gn]?vi[m]?') {
    return @"
      if (`$env:FZF_SELECT_COUNT -eq 0) {
        $editor $editorOptions {1} +{2}     # No selection. Open the current line in Vim.
      } else {
        $editor $editorOptions +cw -q $TEMP_FILE  # Build quickfix list for the selected items.
      }
"@
  } elseif ($editor -eq 'code' -or $editor -eq 'code-insiders' -or $editor -eq 'codium') {
    return @"
      if (`$env:FZF_SELECT_COUNT -eq 0) {
        `$file = {1};
        `$line = {2};
        $editor $editorOptions --goto """`${file}:`${line}"""
      } else {
        # Not possible to open multiple files on a specific line
        # so call them one by one with --goto
        Get-Content $TEMP_FILE | ForEach-Object {
          `$file, `$line, `$ignore = `$_ -Split ':';
          $editor $editorOptions --goto """`${file}:`${line}"""
        }
      }
"@
  } elseif ($editor -eq 'nano') {
    return @"
      if (`$env:FZF_SELECT_COUNT -eq 0) {
        $editor $editorOptions +{2} {1}    # Lanunch nano on current line
      } else {
        `$FileList = Get-Content $TEMP_FILE | ForEach-Object {
          `$files = [System.Collections.Generic.List[string]]::new()
        } {
          `$file, `$ignore = `$_ -Split ':';
          [void]`$files.Add("""`$file""");
        } { `$files }
        $editor $editorOptions @FileList
      }
"@
  } else {
    # TODO: Handle case for nano
    return @"
      if (`$env:FZF_SELECT_COUNT -eq 0) {
        $editor $editorOptions {1}
      } else {
        `$FirstFile = Get-Content -TotalCount 1 $TEMP_FILE | ForEach-Object {
          `$file, `$ignore = `$_ -Split ':';
          """`$file"""
        }
        $editor $editorOptions "`$FirstFile"
      }
"@
  }
}

function Invoke-PsFzfRipgrep() {
    # TODO: Make $NoEditor work again
    # this function is adapted from https://github.com/junegunn/fzf/blob/master/ADVANCED.md#switching-between-ripgrep-mode-and-fzf-mode
    param([Parameter(Mandatory)]$SearchString, [switch]$NoEditor)

    # if ($script:FzfLocation -eq $null) { FindFzf }

    $RG_PREFIX = if ($env:RFV_PREFIX_COMMAND) {
      $env:RFV_PREFIX_COMMAND + ' '
    } else {
      # "rg --column --line-number --no-heading --color=always --smart-case "
      "rg --column --line-number --no-heading --color=always --smart-case --no-ignore --glob !.git --glob !node_modules --hidden "
    }
    $INITIAL_QUERY = $SearchString
    $originalFzfDefaultCommand = $env:FZF_DEFAULT_COMMAND
    # $editor = if ($PREFERRED_EDITOR) { $PREFERRED_EDITOR } elseif ($EDITOR) { $EDITOR } else { nvim }

    try {
        if ($script:IsWindows) {
            $sleepCmd = ''
            $trueCmd = 'cd .'
            # $env:FZF_DEFAULT_COMMAND = "$RG_PREFIX ""$INITIAL_QUERY"""
            # $TEMP_FILE = '"{+f}"'
        }
        else {
            $sleepCmd = 'sleep 0.1;'
            $trueCmd = 'true'
            # $env:FZF_DEFAULT_COMMAND = '{0} $(printf %q "{1}")' -f $RG_PREFIX, $INITIAL_QUERY
            # $TEMP_FILE = '{+f}'
        }

        $RELOAD = "reload:$sleepCmd $RG_PREFIX {q} || $trueCmd"
        $OPENER = Get-EditorLaunch

        & $script:FzfLocation --ansi `
          --header '╱ CTRL-R (Ripgrep mode) ╱ CTRL-F (fzf mode) ╱' `
          --disabled --ansi --multi `
          --cycle `
          --input-border `
          --with-shell 'pwsh -NoLogo -NonInteractive -NoProfile -Command' `
          --bind 'alt-up:preview-page-up,alt-down:preview-page-down' `
          --bind 'ctrl-s:toggle-sort' `
          --bind 'alt-f:first' `
          --bind 'alt-l:last' `
          --bind 'alt-c:clear-query' `
          --bind 'alt-a:select-all' `
          --bind 'alt-d:deselect-all' `
          --bind 'ctrl-^:toggle-preview' `
          --bind 'ctrl-l:toggle-preview' `
	        --bind 'ctrl-/:toggle-preview' `
          --bind "start:$RELOAD" `
          --bind "change:$RELOAD" `
          --bind "enter:become:$OPENER" `
          --bind "ctrl-o:execute:$OPENER" `
          --bind ("ctrl-r:unbind(ctrl-r)+change-prompt" + '(1. 🔎 ripgrep> )' + "+disable-search+reload($RG_PREFIX {q} || $trueCmd)+rebind(change,ctrl-f)") `
          --bind ("ctrl-f:unbind(change,ctrl-f)+change-prompt" + '(2. ✅ fzf> )' + "+enable-search+clear-query+rebind(ctrl-r)") `
          --prompt '1. 🔎 ripgrep> ' `
          --delimiter : `
          --preview 'bat --style=full --color=always --highlight-line {2} {1}' `
          --preview-window '~4,+{2}+4/3,<80(up),wrap' `
          --query "$INITIAL_QUERY"

        # & $script:FzfLocation --ansi `
        #     --color "hl:-1:underline,hl+:-1:underline:reverse" `
        #     --disabled --query "$INITIAL_QUERY" `
        #     --bind "change:reload:$sleepCmd $RG_PREFIX {q} || $trueCmd" `
        #     --bind ("ctrl-f:unbind(change,ctrl-f)+change-prompt" + '( +? fzf> )' + "+enable-search+clear-query+rebind(ctrl-r)") `
        #     --bind ("ctrl-r:unbind(ctrl-r)+change-prompt" + '(?? ripgrep> )' + "+disable-search+reload($RG_PREFIX {q} || $trueCmd)+rebind(change,ctrl-f)") `
        #     --prompt '?? ripgrep> ' `
        #     --delimiter : `
        #     --header '? CTRL-R (Ripgrep mode) ? CTRL-F (fzf mode) ?' `
        #     --preview 'bat --color=always {1} --highlight-line {2}' `
        #     --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' |
        #     ForEach-Object { $results += $_ }

        # # Cleanup the FZF_DEFAULT_COMMAND if no longer used
        # $env:FZF_DEFAULT_COMMAND = $originalFzfDefaultCommand

        # if (-not [string]::IsNullOrEmpty($results)) {
        #     # TODO: Upgrade to support multiple selections
        #     # foreach ($res in $results) {}
        #     $split = $results.Split(':')
        #     $fileList = $split[0]
        #     $lineNum = $split[1]
        #     if ($NoEditor) {
        #         Resolve-Path $fileList
        #     }
        #     else {
        #         $cmd = Get-EditorLaunch -FileList $fileList -LineNum $lineNum
        #         Write-Host "Executing '$cmd'..."
        #         Invoke-Expression -Command $cmd
        #     }
        # }
    }
    catch {
        Write-Error "Error occurred: $_"
    }
    finally {
      $env:FZF_DEFAULT_COMMAND = $originalFzfDefaultCommand
    }
}

Invoke-PsFzfRipgrep @args


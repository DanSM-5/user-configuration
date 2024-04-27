[CmdletBinding()]
param ($DirName, $Item, $PreviewScript = "")

# trim quote strings:
$DirName = $DirName.Trim("'").Trim('"')
$Item = $Item.Trim("'").Trim('"')
$PreviewScript = $PreviewScript.Trim("'").Trim('"')

$RunningInWindowsTerminal = [bool]($env:WT_Session)
$IsWindowsCheck = ($PSVersionTable.PSVersion.Major -le 5) -or $IsWindows
$ansiCompatible = $script:RunningInWindowsTerminal -or (-not $script:IsWindowsCheck)

if ([System.IO.Path]::IsPathRooted($Item)) {
    $path = $Item
}
else {
    $path = Join-Path $DirName $Item
    $path = [System.IO.Path]::GetFullPath($path)
}
# is directory?
if (Test-Path $path -PathType Container) {
    # Display fullname on top
    $fullpath = (Resolve-Path $path).Path
    Write-Output "Path: $fullpath" ""
    $addspace = $false

    # don't output anything if not a git repo
    Push-Location $path
    if ($ansiCompatible) {
        git log --color=always -1 2> $null
        $addspace = $?
    }
    else {
        git log -1 2> $null
        $addspace = $?
    }
    Pop-Location

    try {
      if (Get-Command erd -ErrorAction SilentlyContinue) {
        if ($addspace) { Write-Output "" }
        erd --layout inverted --color force --level 3 -I --suppress-size -- $path || Get-ChildItem $path
      } elseif (Get-Command eza -ErrorAction SilentlyContinue) {
        if ($addspace) { Write-Output "" }
        eza -A --tree --level=3 --color=always --icons=always --dereference $path || Get-ChildItem $path
        # eza -AF --oneline --color=always --icons --group-directories-first --dereference $path || Get-ChildItem $path
      } else {
        Get-ChildItem $path
      }
    } catch {
      Write-Error "Cannot access directory $path"
    }
}
# is file?
elseif (Test-Path $path -PathType leaf) {
    # use bat (https://github.com/sharkdp/bat) if it's available:
    if ($ansiCompatible -and $(Get-Command bat -ErrorAction SilentlyContinue)) {
        bat -p "--style=numbers,changes,header" --color always $path
    }
    else {
        Get-Content $path
    }
}
# PowerShell command?
elseif (($cmdResults = Get-Command $Item -ErrorAction SilentlyContinue)) {
    if ($cmdResults) {
        if ($cmdResults.CommandType -ne 'Application') {
            # use bat (https://github.com/sharkdp/bat) if it's available:
            if ($ansiCompatible -and $(Get-Command bat -ErrorAction SilentlyContinue)) {
                Get-Help $Item | bat -l man -p --color=always
            }
            else {
                Get-Help $Item
            }
        }
        else {
            # just output application location:
            $cmdResults.Source
        }
    }
}
elseif ($PreviewScript) {
    # Run custom preview script
    Invoke-Command -ScriptBlock ([scriptblock]::Create((Get-Content "$PreviewScript"))) -ArgumentList $Item
}


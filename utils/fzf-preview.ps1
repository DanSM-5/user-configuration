# TODO: Review https://github.com/file-go/fil as a 'file' command equivalent

# For more information review comments in fzf-preview.sh version

# Derived from: https://github.com/kelleyma49/PSFzf/blob/master/helpers/PsFzfTabExpansion-Preview.ps1

[CmdletBinding()]
param (
  [string[]]
  [Parameter(ValueFromRemainingArguments = $true)]
  $ItemName
)

# trim quote strings:
$Item = ($ItemName -Join ' ').Trim('"').Trim("'").Trim('/').Trim('\').Trim()

# PreviewScript was removed
# $PreviewScript = $PreviewScript.Trim("'").Trim('"')

$RunningInWindowsTerminal = [bool]($env:WT_Session)
$IsWindowsCheck = ($PSVersionTable.PSVersion.Major -le 5) -or $IsWindows
$ansiCompatible = $script:RunningInWindowsTerminal -or (-not $script:IsWindowsCheck)
$TEMP_DIR = "$env:TEMP/preview_files_script"

if ([System.IO.Path]::IsPathRooted($Item)) {
    $path = $Item
}
else {
    $DirName = if ($env:PREVIEW_INJECTED_DIR) { $env:PREVIEW_INJECTED_DIR } else { '.' }
    $path = Join-Path $DirName $Item
    $path = [System.IO.Path]::GetFullPath($path)
}

function preview_directory () {
  # Display fullname on top
  $fullpath = (Resolve-Path -LiteralPath $path).Path
  Write-Output "Path: $fullpath" ""
  $addspace = $false

  try {
    Push-Location -LiteralPath $path *> $null
    # don't output anything if not a git repo
    if ($ansiCompatible) {
        git log --color=always -1 2> $null
        $addspace = $?
    }
    else {
        git log -1 2> $null
        $addspace = $?
    }
    Pop-Location *> $null
  } catch {}

  try {
    if ($addspace) { Write-Output "" }
    erd --layout inverted --color force --level 3 -I --suppress-size -- $path 2> $null ||
      eza -A --tree --level=3 --color=always --icons=always --dereference $path 2> $null ||
      Get-ChildItem -LiteralPath $path
    # if (Get-Command erd -ErrorAction SilentlyContinue) {
    #   if ($addspace) { Write-Output "" }
    #   erd --layout inverted --color force --level 3 -I --suppress-size -- $path || Get-ChildItem $path
    # } elseif (Get-Command eza -ErrorAction SilentlyContinue) {
    #   if ($addspace) { Write-Output "" }
    #   eza -A --tree --level=3 --color=always --icons=always --dereference $path || Get-ChildItem $path
    #   # eza -AF --oneline --color=always --icons --group-directories-first --dereference $path || Get-ChildItem $path
    # } else {
    #   Get-ChildItem $path
    # }
  } catch {
    Write-Error "Cannot access directory $path"
  }
}

function show_image ([string] $thumbnail, [string] $ErrorMessage) {
  if ($env:FZF_PREVIEW_COLUMNS) {
    # FZF_PREVIEW_TOP     Top position of the preview window
    # FZF_PREVIEW_LEFT    Left position of the preview window
    # FZF_PREVIEW_LINES   Number of lines in the preview window
    # FZF_PREVIEW_COLUMNS Number of columns in the preview window

    # From fzf preview
    $height = $env:FZF_PREVIEW_LINES
    $width = $env:FZF_PREVIEW_COLUMNS
    $x = $env:FZF_PREVIEW_LEFT
    $y = $env:FZF_PREVIEW_TOP
    $IMAGE_SIZE = "${width}x${height}"
  } else {
    $width = if ($env:PREVIEW_WIDTH) { $env:PREVIEW_WIDTH } else { '50' }
    $height = if ($env:PREVIEW_HEIGHT) { $env:PREVIEW_HEIGHT } else { '50' }
    $x = if ($env:PREVIEW_CORDX) { $env:PREVIEW_CORDX } else { '0' }
    $y = if ($env:PREVIEW_CORDY) { $env:PREVIEW_CORDY } else { '0' }
    $IMAGE_SIZE = if ($env:PREVIEW_IMAGE_SIZE) { $env:PREVIEW_IMAGE_SIZE } else { '50x50' }
  }

  if ($env:KITTY_WINDOW_ID) {
    $IMAGE_SIZE = "${width}x${height}@${x}x${y}"

    # if ($env:TERM -Match .+kitty) {
    # 1. 'memory' is the fastest option but if you want the image to be scrollable,
    #    you have to use 'stream'.
    #
    # 2. The last line of the output is the ANSI reset code without newline.
    #    This confuses fzf and makes it render scroll offset indicator.
    #    So we remove the last line and append the reset code to its previous line.
    kitty icat --clear --transfer-mode=stream `
      --unicode-placeholder --stdin=no `
      --place="$IMAGE_SIZE" "$thumbnail" |
        sed '$d' | sed $'$s/$/\e[m/' || Write-Host $ErrorMessage

    return
  }

  # Windows terminal support sixel from v1.22
  if ($env:TERM_PROGRAM -eq 'vscode' -or $IsWindows -or $env:IS_WINDOWS -eq 'true') {
    chafa -f sixels --colors=full --polite=on --animate=off -s "$IMAGE_SIZE" "$thumbnail" ||
      chafa -s "$IMAGE_SIZE" --animate=off "$thumbnail" ||
      Write-Host $ErrorMessage
    return
  }

  chafa -f sixels -s "$IMAGE_SIZE" "$thumbnail" || Write-Host $ErrorMessage
  return
}

function show_pdf ([string] $path, [string] $thumbnail) {
  New-Item $script:TEMP_DIR -ItemType Directory -ea 0
  Write-Output "File: $path`n`n"
  # Using Ghostscript for image preview
  gs -o "$thumbnail" -sDEVICE=pngalpha -dLastPage=1 "$path" *> $null
  show_image "$thumbnail" 'Error previewing the PDF'

  $pdftotext_flags = @( '-f', '1', '-l', '10' )

  Write-Output "`n`n"
  # Pdftotext to get sample pages
  pdftotext @pdftotext_flags "$path" - | bat -p --style="header" || Write-Output 'Error previewing content pdf file'
}

# is directory?
if (Test-Path -LiteralPath $path -PathType Container) {
  preview_directory
}
# is file?
elseif ((Test-Path -LiteralPath $path -PathType leaf) -or (eza -l $path *> $null && $true)) {
  if (-not (Get-Command file -ErrorAction SilentlyContinue)) {
    # use bat (https://github.com/sharkdp/bat) if it's available:
    if ($ansiCompatible -and $(Get-Command bat -ErrorAction SilentlyContinue)) {
        bat -p "--style=numbers,changes,header" --color always $path
    }
    else {
        Get-Content $path
    }

    return
  }

  # New-Item $args -ItemType Directory -ea 0
  # Variables
  $thumbnail = "$TEMP_DIR/thumbnail.png"
  $MIME = file --dereference --mime --brief -- "$path"
  # If not using --brief, remove path manually
  # $FILE_LENGTH = $path.Length + 2
  # $CLEAN_MIME =  $MIME.Substring($FILE_LENGTH)

  switch -Regex ($MIME) {
    # directory - It can match here due to the eza check
    "^inode\/directory.*" {
      preview_directory; break
    }
    # Files
    "^(application\/javascript|application\/json|text\/troff|text\/x-shellscript|text\/html|text\/plain).*" {
      bat --color=always --style="numbers,header,changes" "$path"
      break
    }
    # SVG
    "^image\/svg\+xml.*" {
      New-Item $TEMP_DIR -ItemType Directory -ea 0
      magick "$path" "$thumbnail"
      show_image "$thumbnail" Write-Output 'Error previewing the SVG'
      break
    }
    # Images
    "^image\/.*" {
      show_image "$path" 'Error previewing the image'
      break
    }
    # PDFs
    "^application\/pdf.*" {
      show_pdf $path $thumbnail
      break
    }
    # Zip
    "^application\/zip.*" {
      7z l "$path" || unzip -l "$path" || Write-Output 'Error previewing zip archive'
      break
    }
    # Rar
    "^application\/x-rar.*" {
      7z l "$path" || unrar l "$path" || Write-Output 'Error previewing rar archive'
      break
    }
    # Iso
    "^application/x-iso9660-image.*" {
      7z l "$path" || Write-Output 'Error previewing iso archive'
      break
    }
    # 7z
    "^application\/x-7z-compressed.*" {
      7z l "$path" || Write-Output 'Error previewing 7z archive'
      break
    }
    # Database sqlite3
    "^application\/vnd.sqlite3.*" {
      Write-Output "File: $path" ""
      Write-Output "Schema: "
      sqlite3 "$path" .schema
      Write-Output "Tables: "
      sqlite3 "$path" .table
      break
    }
    # Videos
    "^video\/(x-matroska|x-ms-asf|webm|mp4).*" {
      New-Item $TEMP_DIR -ItemType Directory -ea 0
      ffmpeg -y -i "$path" -vframes 1 "$thumbnail" *> $null
      show_image "$thumbnail" 'Error previewing the video'
      break
    }
    default {
      switch -Regex ($path) {
        ".*\.(tar|tgz|tbz|tbz2)$" {
          7z l "$path" || tar tf "$path" || Write-Output 'Error previewing tar archive'
          break
        }
        ".*\.tar\.(bz|bz2|gz|xz|zst)$" {
          7z l "$path" || tar tf "$path" || Write-Output 'Error previewing tar archive'
          break
        }
        ".*\.zip$" {
          7z l "$path" || unzip -l "$path" || Write-Output 'Error previewing zip archive'
          break
        }
        ".*\.rar$" {
          7z l "$path" || unrar l "$path" || Write-Output 'Error previewing rar archive'
          break
        }
        ".*\.7z$" {
          7z l "$path" || Write-Output 'Error previewing 7z archive'
          break
        }
        ".*\.iso$" {
          7z l "$path" || Write-Output 'Error previewing iso archive'
          break
        }
        ".*\.(avi|mp4|mkv|webm|wmv)$" {
          New-Item $TEMP_DIR -ItemType Directory -ea 0
          ffmpeg -y -i "$path" -vframes 1 "$thumbnail" *> $null
          show_image "$thumbnail" 'Error previewing the video'
          break
        }
        ".*\.pdf$" {
          show_pdf $path $thumbnail
          break
        }
        ".*\.(jpg|jpeg|png|bmp)$" {
          show_image "$path" 'Error previewing the image'
          break
        }
        ".*\.svg$" {
          New-Item $TEMP_DIR -ItemType Directory -ea 0
          magick "$path" "$thumbnail"
          show_image "$thumbnail" 'Error previewing the SVG'
          break
        }
        ".*\.md$" {
          glow $path || bat --color=always --style="numbers,header,changes" "$path"
          break
        }
        ".*\.(txt|htm|html|js|jsx|ts|tsx|css|scss|sh|bat|ps1|psm1|bash|zsh|cs|json|xml)$" {
          bat --color=always --style="numbers,header,changes" "$path"
          break
        }
        default {
          # Fallback to bat
          Write-Output "Unkown MIME type:" "$MIME" "`n`n"
          bat --color=always --style="numbers,header" "$path"
          break
        }
      }
      break
    }
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
# }
# elseif ($PreviewScript) {
#     # Run custom preview script
#     Invoke-Command -ScriptBlock ([scriptblock]::Create((Get-Content "$PreviewScript"))) -ArgumentList $Item
} else {
  Write-Output "Not identified: $path"
}


# TODO: Review https://github.com/file-go/fil as a file equivalent

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

function preview_directory () {
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
    if ($addspace) { Write-Output "" }
    erd --layout inverted --color force --level 3 -I --suppress-size -- $path 2> $null ||
      eza -A --tree --level=3 --color=always --icons=always --dereference $path 2> $null ||
      Get-ChildItem $path
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

# is directory?
if (Test-Path $path -PathType Container) {
  preview_directory
}
# is file?
elseif ((Test-Path $path -PathType leaf) -or (eza -l $path *> $null && $true)) {
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
  $TEMP_DIR = "$env:TEMP/preview_files_script"
  $thumbnail = "$TEMP_DIR/thumbnail.png"
  $MIME = file --dereference --mime -- "$path"
  $FILE_LENGTH = $path.Length + 2
  $CLEAN_MIME =  $MIME.Substring($FILE_LENGTH)
  $IMAGE_SIZE = '75x75'

  switch -Regex ($CLEAN_MIME) {
    # directory - It can match here due to the eza check
    "^directory$" {
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
      magick convert "$path" "$thumbnail"
      chafa -s "$IMAGE_SIZE" "$thumbnail" || Write-Output 'Error previewing the SVG'
      break
    }
    # Images
    "^image\/.*" {
      chafa -s "$IMAGE_SIZE" "$path" || Write-Output 'Error previewing the image'
      break
    }
    # PDFs
    "^application\/pdf.*" {
      New-Item $TEMP_DIR -ItemType Directory -ea 0
      Write-Output "File: $path`n`n"
      # Using Ghostscript for image preview
      gs -o "$thumbnail" -sDEVICE=pngalpha -dLastPage=1 "$path" *> $null
      chafa -s "$IMAGE_SIZE" "$thumbnail" || Write-Output "Error previewing the PDF`n"

      Write-Output "`n`n"
      # Pdftotext to get sample pages
      pdftotext -f 1 -l 10 "$path" - | bat -p --style="header" || Write-Output 'Error previewing content pdf file'
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
      chafa -s "$IMAGE_SIZE" "$thumbnail" || Write-Output 'Error previewing the video'
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
          chafa -s "$IMAGE_SIZE" "$thumbnail" || Write-Output 'Error previewing the video'
          break
        }
        ".*\.pdf$" {
          New-Item $TEMP_DIR -ItemType Directory -ea 0
          Write-Output "File: $path`n`n"
          # Using Ghostscript for image preview
          gs -o "$thumbnail" -sDEVICE=pngalpha -dLastPage=1 "$path" *> $null
          chafa -s "$IMAGE_SIZE" "$thumbnail" || Write-Output 'Error previewing the PDF'

          Write-Output "`n`n"
          # Pdftotext to get sample pages
          pdftotext -f 1 -l 10 "$path" - | bat -p --style="header" || Write-Output 'Error previewing content pdf file'
        }
        ".*\.(jpg|jpeg|png|bmp)$" {
          chafa -s "$IMAGE_SIZE" "$path" || Write-Output 'Error previewing the image'
          break
        }
        ".*\.svg$" {
          New-Item $TEMP_DIR -ItemType Directory -ea 0
          magick convert "$path" "$thumbnail"
          chafa -s "$IMAGE_SIZE" "$thumbnail" || Write-Output 'Error previewing the SVG'
        }
        ".*\.(txt|md|htm|html|js|jsx|ts|tsx|css|scss|sh|bat|ps1|psm1|bash|zsh|cs|json|xml)$" {
          bat --color=always --style="numbers,header,changes" "$path"
          break
        }
        default {
          # Fallback to bat
          Write-Output "Unkown MIME type:" "$CLEAN_MIME" "`n`n"
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
}
elseif ($PreviewScript) {
    # Run custom preview script
    Invoke-Command -ScriptBlock ([scriptblock]::Create((Get-Content "$PreviewScript"))) -ArgumentList $Item
} else {
  Write-Output "Not identified: $path"
}


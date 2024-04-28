#!/usr/bin/env bash

# Dependencies
# - bat
# - erd
# - eza
# - pdftotext (poppler)
# - gs (ghostscript)
# - tar
# - zipinfo
# - unrar
# - 7z
# - chafa
# - git

# References
# - https://github.com/slavistan/howto-lf-image-previews
#   - https://github.com/slavistan/howto-lf-image-previews/blob/master/lf-previewer
# - https://github.com/junegunn/fzf.vim
#   - https://github.com/junegunn/fzf.vim/blob/master/bin/preview.sh

path="$@"

# NOTE: Remove ' -> ' from symlins for eza until '-X' is fixed
path="$(printf '%s' "$path" | sed 's| ->.*||')"

# Escape if any special character
# path="$(printf "%q" "$path")"

case "$(uname -a)" in
  MINGW*|MSYS*|CYGWIN*|*NT*)
    # You can arrive here from powershell
    # Consider exporting path
    # export PATH="/mingw64/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

    # NOTE: cygwin/msys/gitbash require path
    # conversion from /c/ to C:/ to be picked
    # up correctly by native windows binaries
    path="$(cygpath -am "$path")"
    ;;
esac

if [ -f "$path" ]; then
  # Variables
  TEMP_DIR="/tmp/preview_files_script"
  thumbnail="$TEMP_DIR/thumbnail.png"
  MIME=$(file --dereference --mime -- "$path")
  FILE_LENGTH=$(( ${#path} + 2 ))
  CLEAN_MIME="${MIME:FILE_LENGTH}"
  IMAGE_SIZE=75x75

  case "$CLEAN_MIME" in
    # Files
    application/javascript*) ;&
    application/json*) ;&
    text/troff*charset=us-ascii) ;&
    text/x-shellscript*) ;&
    text/html*) ;&
    text/plain*)
      bat --color=always --style="numbers,header,changes" "$path"
      ;;
    # SVG
    image/svg+xml*)
      mkdir -p "$TEMP_DIR"
      magick convert "$path" "$thumbnail"
      chafa -s "$IMAGE_SIZE" "$thumbnail" || printf '%s\n' 'Error previewing the SVG'
      ;;
    # Images
    image/*)
      chafa -s "$IMAGE_SIZE" "$path" || printf '%s\n' 'Error previewing the image'
      ;;
    # PDFs
    application/pdf*)
      mkdir -p "$TEMP_DIR"
      printf '%s\n\n' "File: $path"
      # Using Ghostscript for image preview
      gs -o "$thumbnail" -sDEVICE=pngalpha -dLastPage=1 "$path" &>/dev/null
      chafa -s "$IMAGE_SIZE" "$thumbnail" || printf '%s\n' 'Error previewing the PDF'

      printf "\n\n"
      # Pdftotext to get sample pages
      set -o pipefail
      pdftotext -f 1 -l 10 -simple "$path" - | bat -p --style="header" || printf '%s\n' 'Error previewing content pdf file'
      ;;
    # Zip
    application/zip*)
      7z l "$path" || unzip -l "$path" || printf '%s\n' 'Error previewing zip archive'
      ;;
    # Rar
    application/x-rar*)
      7z l "$path" || unrar l "$path" || printf '%s\n' 'Error previewing rar archive'
      ;;
    # Iso
    application/x-iso9660-image*)
      7z l "$path" || printf '%s\n' 'Error previewing iso archive'
      ;;
    # 7z
    application/x-7z-compressed*)
      7z l "$path" || printf '%s\n' 'Error previewing 7z archive'
      ;;
    # Database sqlite3
    application/vnd.sqlite3*)
      printf '%s\n' "File: $path"
      printf '\n'
      printf '%s' "Schema: "
      sqlite3 "$path" .schema
      printf '%s' "Tables: "
      sqlite3 "$path" .table
      ;;
    # Videos
    video/x-matroska*) ;&
    video/x-ms-asf*) ;&
    video/webm*) ;&
    video/mp4*)
      mkdir -p "$TEMP_DIR"
      ffmpeg -y -i "$path" -vframes 1 "$thumbnail" &> /dev/null
      chafa -s "$IMAGE_SIZE" "$thumbnail" || printf '%s\n' 'Error previewing the video'
      ;;
    *)
      # If mime type fails then try by file extension
      case "$path" in
        *.tar*|*.tgz|*.tbz|*.tbz2)
          7z l "$path" || tar tf "$path" || printf '%s\n' 'Error previewing tar archive'
          ;;
        *.zip)
          # zipinfo "$path"
          7z l "$path" || unzip -l "$path" || printf '%s\n' 'Error previewing zip archive'
          ;;
        *.rar)
          7z l "$path" || unrar l "$path" || printf '%s\n' 'Error previewing rar archive'
          ;;
        *.7z)
          7z l "$path" || printf '%s\n' 'Error previewing 7z archive'
          ;;
        *.iso)
          7z l "$path" || printf '%s\n' 'Error previewing iso archive'
          ;;
        *.avi|*.mp4|*.mkv|*.webm|*.wmv)
          mkdir -p "$TEMP_DIR"
          ffmpeg -y -i "$path" -vframes 1 "$thumbnail" &> /dev/null
          chafa -s "$IMAGE_SIZE" "$thumbnail" || printf '%s\n' 'Error previewing the video'
          ;;
        *.pdf)
            mkdir -p "$TEMP_DIR"
            printf '%s\n\n' "File: $path"
            # Using Ghostscript for image preview
            gs -o "$thumbnail" -sDEVICE=pngalpha -dLastPage=1 "$path" &>/dev/null
            chafa -s "$IMAGE_SIZE" "$thumbnail" || printf '%s\n' 'Error previewing the PDF'

            printf "\n\n"
            # Pdftotext to get sample pages
            set -o pipefail
            pdftotext -f 1 -l 10 -simple "$path" - | bat -p --style="header" || printf '%s\n' 'Error previewing content pdf file'
            ;;
        *.jpg|*.jpeg|*.png|*.bmp)
            chafa -s "$IMAGE_SIZE" "$path" || printf '%s\n' 'Error previewing the image'
            ;;
        *.svg)
          mkdir -p "$TEMP_DIR"
          magick convert "$path" "$thumbnail"
          chafa -s "$IMAGE_SIZE" "$thumbnail" || printf '%s\n' 'Error previewing the SVG'
          ;;
        *.txt|*.md|*.htm*|*.js|*.jsx|*.ts|*.tsx|*.css|*.scss|*.sh|*.bat|*.ps1|*.psm1|*.bash|*.zsh|*.cs|*.json|*.xml)
          bat --color=always --style="numbers,header,changes" "$path"
          ;;
        *)
          # Fallback to bat
          printf '%s\n' "Unkown MIME type:" "$CLEAN_MIME"
          printf "\n\n"
          bat --color=always --style="numbers,header" "$path"
          ;;
      esac
  esac
elif [ -d "$path" ]; then
  # Print filename
  printf "Path: $(realpath "$path" 2> /dev/null || printf '%s' "$path")\n\n"

  # Detect if on git reposiry. If so, print last commit information
  pushd "$path" &> /dev/null
  if (git rev-parse HEAD > /dev/null 2>&1); then
    git log --color=always -1 2> /dev/null
    printf "\n"
  fi
  popd &> /dev/null

  # eza -AF --oneline --color=always --icons --group-directories-first --dereference "$path" 2> /dev/null ||

  # Preview directory
  # Try erd, then eza, then ls, then fallback message
  erd --layout inverted --color force --level 3 --suppress-size -I -- "$path" 2> /dev/null ||
    eza -A --tree --level=3 --color=always --icons=always --dereference "$path" 2> /dev/null ||
    ls -AFL --color=always "$path" 2> /dev/null ||
    printf "\nCannot access directory $path"
else
  printf '%s' "Not identified: $path"
fi


#!/usr/bin/env bash

# TODO: Review https://github.com/file-go/fil as a 'file' command equivalent

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
# - glow

# References
# - https://github.com/slavistan/howto-lf-image-previews
#   - https://github.com/slavistan/howto-lf-image-previews/blob/master/lf-previewer
# - https://github.com/junegunn/fzf.vim
#   - https://github.com/junegunn/fzf.vim/blob/master/bin/preview.sh
#   - https://github.com/junegunn/fzf/blob/master/bin/fzf-preview.sh
# - https://gist.github.com/wolandark/6b138cbea468f1e4e5f697f8a9c85a68

# TODO: Support epub preview
# epub2txt2 does not run natively on windows and
# v1 does not output to stdout
#
# Example
# application/epub+zip*)
# 	# Use epub2txt for EPUB files
# 	epub2txt "$1" | head -n 1000 2>/dev/null
# 	;;

path="$*"

# NOTE: Remove ' -> ' from symlins for eza until '-X' is fixed
path="$(printf '%s' "$path" | sed 's| ->.*||')"
# Trim
path="$(printf '%s' "$path" | xargs)"

# Escape if any special character
# path="$(printf "%q" "$path")"

# Expand HOME
path=${path/#\~\//$HOME/}
# type=$(file --dereference --mime -- "$path")
# file -bL --mime-type "$path"

# Global names unless changed otherwise
TEMP_DIR="/tmp/preview_files_script"
thumbnail="$TEMP_DIR/thumbnail.png"

preview_directory () {
  path="$1"
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
}

show_image () {
  thumbnail="$1"
  IMAGE_SIZE="${PREVIEW_IMAGE_SIZE:-50x50}"

  if [[ -v KITTY_WINDOW_ID ]]; then
  # if [[ "$TERM" =~ .+kitty ]]; then
    # 1. 'memory' is the fastest option but if you want the image to be scrollable,
    #    you have to use 'stream'.
    #
    # 2. The last line of the output is the ANSI reset code without newline.
    #    This confuses fzf and makes it render scroll offset indicator.
    #    So we remove the last line and append the reset code to its previous line.

    IMAGE_SIZE="${PREVIEW_WIDTH:-50}x${PREVIEW_HEIGHT:-50}@${PREVIEW_CORDX:-0}x${PREVIEW_CORDY:-0}"

    kitty icat --clear --transfer-mode=stream \
      --unicode-placeholder --stdin=no \
      --place="$IMAGE_SIZE" "$thumbnail" |
        sed '$d' | sed $'$s/$/\e[m/'

    # TODO: Create a handler for lf?
    # Ref: https://github.com/gokcehan/lf/wiki/Previews#with-kitty-and-pistol
    # Kitty needs to use a cleaner script and do some tty redirection.
    #
    # kitty icat --clear --silent --stdin no \
    #   --unicode-placeholder \
    #   --transfer-mode stream --place "${IMAGE_SIZE}" "$thumbnail"

    return
  fi

  if [ "$TERM_PROGRAM" = 'WezTerm' ]; then
    chafa -f sixels --polite on -s "$IMAGE_SIZE" "$thumbnail" 2>/dev/null
    return
  fi

  if [ "$TERM_PROGRAM" = 'vscode' ] || [ "$IS_WINDOWS" = true ]; then
    chafa -f sixels --colors=full --polite=on --animate=off -s "$IMAGE_SIZE" "$thumbnail" 2>/dev/null ||
      chafa -s "$IMAGE_SIZE" --animate=off "$thumbnail" 2>/dev/null
    return
  fi

  chafa -f sixels -s "$IMAGE_SIZE" "$thumbnail"
}

show_7z () {
  # p7zip and 7zip
  7z l "$1" || 7zz l "$1"
}

show_pdf () {
  path="$1"
  thumbnail="$2"

  mkdir -p "$TEMP_DIR"
  printf '%s\n\n' "File: $path"
  # Using Ghostscript for image preview
  gs -o "$thumbnail" -sDEVICE=pngalpha -dLastPage=1 "$path" &>/dev/null
  show_image "$thumbnail" || printf '%s\n' 'Error previewing the PDF'

  printf "\n\n"
  # Pdftotext to get sample pages
  set -o pipefail

  pdftotext_flags=(
    '-f'
    '1'
    '-l'
    '10'
  )

  if [[ "$(uname -a)" =~ .*MSYS.*|.*MINGW.*|.*CYGWIN.*|.*NT.* ]]; then
    # MSYS version requires to add '-simple' formatter
    # for its built-in pdftotext. Other binaries do not have that option
    pdftotext_flags+=('-simple')
  fi

  pdftotext "${pdftotext_flags[@]}" "$path" - | bat -p --style="header" || printf '%s\n' 'Error previewing content pdf file'
}

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
  MIME=$(file --dereference --mime --brief -- "$path")
  # If not using --brief, remove path manually
  # FILE_LENGTH=$(( ${#path} + 2 ))
  # CLEAN_MIME="${MIME:FILE_LENGTH}"

  case "$MIME" in
    # directory - Could it arrive here?
    inode/directory*)
      preview_directory "$path"
    ;;
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
      magick "$path" "$thumbnail"
      show_image "$thumbnail" || printf '%s\n' 'Error previewing the SVG'
      ;;
    # Images
    image/*)
      show_image "$path" || printf '%s\n' 'Error previewing the image'
      ;;
    # PDFs
    application/pdf*)
      mkdir -p "$TEMP_DIR"
      show_pdf "$path" "$thumbnail"
      ;;
    # Zip
    application/zip*)
      show_7z "$path" || unzip -l "$path" || printf '%s\n' 'Error previewing zip archive'
      ;;
    # Rar
    application/x-rar*)
      show_7z "$path" || unrar l "$path" || printf '%s\n' 'Error previewing rar archive'
      ;;
    # Iso
    application/x-iso9660-image*)
      show_7z "$path" || printf '%s\n' 'Error previewing iso archive'
      ;;
    # 7z
    application/x-7z-compressed*)
      show_7z "$path" || printf '%s\n' 'Error previewing 7z archive'
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
      show_image "$thumbnail" || printf '%s\n' 'Error previewing the video'
      ;;
    *)
      # If mime type fails then try by file extension
      case "$path" in
        *.tar*|*.tgz|*.tbz|*.tbz2)
          show_7z "$path" || tar tf "$path" || printf '%s\n' 'Error previewing tar archive'
          ;;
        *.zip)
          # zipinfo "$path"
          show_7z "$path" || unzip -l "$path" || printf '%s\n' 'Error previewing zip archive'
          ;;
        *.rar)
          show_7z "$path" || unrar l "$path" || printf '%s\n' 'Error previewing rar archive'
          ;;
        *.7z)
          show_7z "$path" || printf '%s\n' 'Error previewing 7z archive'
          ;;
        *.iso)
          show_7z "$path" || printf '%s\n' 'Error previewing iso archive'
          ;;
        *.avi|*.mp4|*.mkv|*.webm|*.wmv)
          mkdir -p "$TEMP_DIR"
          ffmpeg -y -i "$path" -vframes 1 "$thumbnail" &> /dev/null
          show_image "$thumbnail" || printf '%s\n' 'Error previewing the video'
          ;;
        *.pdf)
            mkdir -p "$TEMP_DIR"
            show_pdf "$path" "$thumbnail"
            ;;
        *.jpg|*.jpeg|*.png|*.bmp)
            show_image "$path" || printf '%s\n' 'Error previewing the image'
            ;;
        *.svg)
          mkdir -p "$TEMP_DIR"
          magick "$path" "$thumbnail"
          show_image "$thumbnail" || printf '%s\n' 'Error previewing the SVG'
          ;;
        *.md)
          glow "$path" || bat --color=always --style="numbers,header,changes" "$path"
          ;;
        *.txt|*.htm*|*.js|*.jsx|*.ts|*.tsx|*.css|*.scss|*.sh|*.bat|*.ps1|*.psm1|*.bash|*.zsh|*.cs|*.json|*.xml)
          bat --color=always --style="numbers,header,changes" "$path"
          ;;
        *)
          # Fallback to bat
          printf '%s\n' "Unkown MIME type:" "$MIME"
          printf "\n\n"
          bat --color=always --style="numbers,header" "$path"
          ;;
      esac
  esac
elif [ -d "$path" ]; then
  preview_directory "$path"
else
  printf '%s' "Not identified: $path"
fi


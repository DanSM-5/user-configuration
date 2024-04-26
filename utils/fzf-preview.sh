#!/usr/bin/env bash

entry_path="$@"

# NOTE: Remove ' -> ' from symlins for eza until '-X' is fixed 
entry_path="$(printf "$entry_path" | sed 's/ ->.*//')"

case "$(uname -a)" in
  MINGW*|MSYS*|CYGWIN*|*NT*)
    # NOTE: cygwin/msys/gitbash require path
    # conversion from /c/ to C:/ to be picked
    # up correctly by native windows binaries
    entry_path="$(cygpath -am "$entry_path")"
    ;;
esac

if [ -f "$entry_path" ]; then
    # TODO: Add support for binary file types
    bat --color=always --style="numbers,header,changes" $entry_path
  else
    # Print filename
    printf "Path: $(realpath "$entry_path" 2> /dev/null || printf "$entry_path")\n\n"

    # Detect if on git reposiry. If so, print last commit information
    pushd "$entry_path" &> /dev/null
    if (git rev-parse HEAD > /dev/null 2>&1); then
      git log --color=always -1 2> /dev/null
      printf "\n"
    fi
    popd &> /dev/null

    # Preview directory
    # Try erd, then eza, then ls, then fallback message
    erd --layout inverted --color force --level 3 --suppress-size -I -- "$entry_path" 2> /dev/null ||
      eza -AF --oneline --color=always --icons --group-directories-first --dereference "$entry_path" 2> /dev/null ||
      ls -AFL --color=always "$entry_path" 2> /dev/null ||
      printf "\nCannot access directory $entry_path"
fi


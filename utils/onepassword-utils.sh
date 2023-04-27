#!/usr/bin/env bash

# Wrapper for use in WSL/Git bash
if command_exists op.exe; then
  op () {
    op.exe "$@"
  }
fi

getpass () {
  local displayRaw=false

  case "${1}" in
    [rR]aw[tT]ext|-[rR]|--[rR]aw|-+[rR]aw[tT]ext)
      displayRaw=true
      ;;
  esac

  # local name="$(op item list --format=json | jq -r '.[] | .title' | fzf)"
  local json="$(op item list --categories 'Login' --format=json |
    jq -r 'to_entries | map({ id: .value.id, title: ((.key | tostring) + " " + .value.title) })')"

  if [ -z $json ]; then
    return 1
  fi

  local index=$(echo $json | jq -r '.[] | .title' | fzf | cut -d ' ' -f 1)

  local id=$(echo $json | jq -r ".[$index] | .id")

  local keys=($(
    op item get --format json "$id" |
      jq -r '.fields | .[] | select(.id == "username" or .id == "password") | .value'
  ))

  if [ "$displayRaw" = true ]; then
    echo "${keys[@]}"
    return 0
  fi

  echo "${keys[@]:1:1}" | $clipboard_copy

  echo "${keys[@]:0:1}"
}

shownote () {
  # case "${1}" in
  #   [rR]aw[tT]ext|-[rR]|--[rR]aw|-+[rR]aw[tT]ext)
  #     displayRaw=true
  #     ;;
  # esac

  local json="$(op item list --categories 'Secure Note' --format=json |
    jq -r 'to_entries | map({ id: .value.id, title: ((.key | tostring) + " " + .value.title) })')"

  if [ -z $json ]; then
    return 1
  fi

  local index=$(echo $json | jq -r '.[] | .title' | fzf | cut -d ' ' -f 1)

  local id=$(echo $json | jq -r ".[$index] | .id")

  op item get --format=json "$id" | jq -r '.fields | .[] | .value' | bat -pp
}
# TODO: Install bash completion package
# if [ "$IS_BASH" = true ]; then
  
if [ "$IS_ZSH" = true ]; then
  eval "$(op completion zsh)"; compdef _op op
fi

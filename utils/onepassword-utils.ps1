
# Add autocompletion in poweshell
op completion powershell | Out-String | Invoke-Expression

# Get a list of passwords and copy to clipboard
function getpass ([Switch] $RawText) {
  $name = "$(op item list --format=json | jq -r '.[] | .title' | fzf)"

  if (-Not $name) {
    return
  }

  $keys = @(
    op item get --format=json "$name" |
      jq -r '.fields | .[] | select(.id == "username" or .id == "password") | .value'
  )

  if ($RawText) {
    Write-Output $keys
    return
  }

  if (Test-Command pbcopy) {
    $keys[1] | pbcopy
  } else {
    $keys[1] | clip.exe
  }

  Write-Output $keys[0]
}

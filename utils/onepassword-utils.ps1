
# Add autocompletion in poweshell
op completion powershell | Out-String | Invoke-Expression

# Get a list of passwords and copy to clipboard
function getpass ([Switch] $RawText) {
  $json = "$(op item list --categories 'Login' --format=json |
    jq -r 'to_entries | map({ id: .value.id, title: ((.key | tostring) + " " + .value.title) })')"

  if (-Not $json) {
    return
  }

  $index = $json | jq -r '.[] | .title' | fzf

  # No index selected
  if (-not $index) {
    return
  }

  $index = ($index -Split ' ')[0]

  $id = $json | jq -r ".[$index] | .id"

  $keys = @(
    op item get --format=json "$id" |
      jq -r '.fields
        | [ .[]
        | select(.id == "username" or .id == "password") ]
        | reduce .[] as $item ({}; .[$item.id] = $item.value)
        | [ .username, .password ]
        | .[]'
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

function shownote () {
  $json = "$(op item list --categories 'Secure Note' --format=json |
    jq -r 'to_entries | map({ id: .value.id, title: ((.key | tostring) + " " + .value.title) })')"

  if (-Not $json) {
    return
  }

  $index = $json | jq -r '.[] | .title' | fzf

  # No index selected
  if (-not $index) {
    return
  }

  $index = ($index -Split ' ')[0]

  $id = $json | jq -r ".[$index] | .id"

  op item get --format=json "$id" | jq -r '.fields | .[] | .value' | bat -pp
}

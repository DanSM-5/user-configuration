
# Add autocompletion in poweshell
op completion powershell | Out-String | Invoke-Expression

# Get a list of passwords and copy to clipboard
function getpass ([Switch] $RawText) {
  $json = "$(op item list --categories 'Login' --format=json |
    jq -r 'to_entries | map({ id: .value.id, title: ((.key | tostring) + " " + .value.title) })')"

  if (-Not $json) {
    return
  }

  $index = $json | jq -r '.[] | .title' | fzf | % {
    $items = $_ -Split ' '
    $items[0]
  }

  $id = $json | jq -r ".[$index] | .id"

  $keys = @(
    op item get --format=json "$id" |
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

function shownote () {
  $json = "$(op item list --categories 'Secure Note' --format=json |
    jq -r 'to_entries | map({ id: .value.id, title: ((.key | tostring) + " " + .value.title) })')"

  if (-Not $json) {
    return
  }

  $index = $json | jq -r '.[] | .title' | fzf | % {
    $items = $_ -Split ' '
    # @($items[0], ($items[1..$items.length] -Join ' '))
    $items[0]
  }

  $id = $json | jq -r ".[$index] | .id"

  op item get --format=json "$id" | jq -r '.fields | .[] | .value' | bat -pp
}

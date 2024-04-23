# Helper to copy content to clipboard

$content = "$args"

if (Test-Path -Path $content -PathType Leaf -ErrorAction SilentlyContinue) {
  (@(Get-Content $content | % { "'$_'" })) -Join ' ' | Set-Clipboard
  return
}

$args | Set-Clipboard


#!/usr/bin/env bash
set -euo pipefail

declare filename=${@:-$(</dev/stdin)}

if [ -z "$filename" ]; then
  filename="$(echo $RANDOM)"
fi

location=$(pwd | sed -nr 's/\//\\/pg')

if [[ $location =~ 'mnt'  ]]; then
  location="$(echo $location | sed -nr 's/\\mnt\\(.)/\1:/p')"
else
  if [[ $(uname -r) =~ 'WSL2' ]]; then
    # for WSL2
    location="\\\\wsl\$\\Ubuntu$location"
  else
    # for WSL1
    location="\\\\wsl.localhost\\Ubuntu$location"
  fi
fi

file="$location\\$filename.png"
echo "Creating: $file"
powershell.exe -sta "Add-Type -Assembly PresentationCore;" \
  '$img = [Windows.Clipboard]::GetImage();' \
  'if ($img -eq $null) {' \
  'echo "Clipboard does not contain image.";' \
  'Exit;' \
  '} else {' \
  'echo "Good";}' \
  '$fcb = new-object Windows.Media.Imaging.FormatConvertedBitmap($img, [Windows.Media.PixelFormats]::Rgb24, $null, 0);' \
  '$file = "' "$file" '";' \
  '$stream = [IO.File]::Open($file, "OpenOrCreate");' \
  '$encoder = New-Object Windows.Media.Imaging.PngBitmapEncoder;' \
  '$encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($fcb));' \
  '$encoder.Save($stream);$stream.Dispose();'


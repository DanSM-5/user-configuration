
param (
  [String] $filename = 'out'
)

$location = "$PWD"
$file = "$location\$filename.png";

Write-Output "Creating: $file"
Add-Type -Assembly PresentationCore
$img = [Windows.Clipboard]::GetImage()
if ($null -eq $img) {
  Write-Output "Clipboard does not contain a image.";
  Exit;
}

$fcb = new-object Windows.Media.Imaging.FormatConvertedBitmap($img, [Windows.Media.PixelFormats]::Rgb24, $null, 0)
$stream = [IO.File]::Open($file, "OpenOrCreate")
$encoder = New-Object Windows.Media.Imaging.PngBitmapEncoder
$encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($fcb))
$encoder.Save($stream)
$stream.Dispose()


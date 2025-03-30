# Helper to log content

$content = @"
$args
"@

$content.Trim() | bat -pp --color=always --language powershell


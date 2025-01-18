# Helper to log content

$content = if ($args) { "$args" } else { "" }

$content | bat -pp --color=always --language powershell


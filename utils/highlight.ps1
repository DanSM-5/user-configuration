# Helper for fzf command
#
# Highlight is an optional dependency for this script

# Get query to search
$search_query = $args[0]

# Parse path
$path_value = $args[1..$args.length]
$path_value = "$($PWD.ProviderPath.Replace('\', '/'))/$($path_value.Replace('\\','/'))"

try {
  highlight -O ansi -l "$path_value" |
    rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 "$search_query" || rg --ignore-case --pretty --context 10 "$search_query" "$path_value"
} catch {
  # Fallback to rg only if highlight is not installed
  rg --ignore-case --pretty --context 10 "$search_query" "$path_value"
}


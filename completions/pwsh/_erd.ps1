
using namespace System.Management.Automation
using namespace System.Management.Automation.Language

Register-ArgumentCompleter -Native -CommandName 'erd' -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

    $commandElements = $commandAst.CommandElements
    $command = @(
        'erd'
        for ($i = 1; $i -lt $commandElements.Count; $i++) {
            $element = $commandElements[$i]
            if ($element -isnot [StringConstantExpressionAst] -or
                $element.StringConstantType -ne [StringConstantType]::BareWord -or
                $element.Value.StartsWith('-') -or
                $element.Value -eq $wordToComplete) {
                break
        }
        $element.Value
    }) -join ';'

    $completions = @(switch ($command) {
        'erd' {
            [CompletionResult]::new('-c', 'c', [CompletionResultType]::ParameterName, 'Use configuration of named table rather than the top-level table in .erdtree.toml')
            [CompletionResult]::new('--config', 'config', [CompletionResultType]::ParameterName, 'Use configuration of named table rather than the top-level table in .erdtree.toml')
            [CompletionResult]::new('-C', 'C', [CompletionResultType]::ParameterName, 'Mode of coloring output')
            [CompletionResult]::new('--color', 'color', [CompletionResultType]::ParameterName, 'Mode of coloring output')
            [CompletionResult]::new('-d', 'd', [CompletionResultType]::ParameterName, 'Print physical or logical file size')
            [CompletionResult]::new('--disk-usage', 'disk-usage', [CompletionResultType]::ParameterName, 'Print physical or logical file size')
            [CompletionResult]::new('--time', 'time', [CompletionResultType]::ParameterName, 'Which kind of timestamp to use; modified by default')
            [CompletionResult]::new('--time-format', 'time-format', [CompletionResultType]::ParameterName, 'Which format to use for the timestamp; default by default')
            [CompletionResult]::new('-L', 'L', [CompletionResultType]::ParameterName, 'Maximum depth to display')
            [CompletionResult]::new('--level', 'level', [CompletionResultType]::ParameterName, 'Maximum depth to display')
            [CompletionResult]::new('-p', 'p', [CompletionResultType]::ParameterName, 'Regular expression (or glob if ''--glob'' or ''--iglob'' is used) used to match files')
            [CompletionResult]::new('--pattern', 'pattern', [CompletionResultType]::ParameterName, 'Regular expression (or glob if ''--glob'' or ''--iglob'' is used) used to match files')
            [CompletionResult]::new('-t', 't', [CompletionResultType]::ParameterName, 'Restrict regex or glob search to a particular file-type')
            [CompletionResult]::new('--file-type', 'file-type', [CompletionResultType]::ParameterName, 'Restrict regex or glob search to a particular file-type')
            [CompletionResult]::new('-s', 's', [CompletionResultType]::ParameterName, 'How to sort entries')
            [CompletionResult]::new('--sort', 'sort', [CompletionResultType]::ParameterName, 'How to sort entries')
            [CompletionResult]::new('--dir-order', 'dir-order', [CompletionResultType]::ParameterName, 'Sort directories before or after all other file types')
            [CompletionResult]::new('-T', 'T', [CompletionResultType]::ParameterName, 'Number of threads to use')
            [CompletionResult]::new('--threads', 'threads', [CompletionResultType]::ParameterName, 'Number of threads to use')
            [CompletionResult]::new('-u', 'u', [CompletionResultType]::ParameterName, 'Report disk usage in binary or SI units')
            [CompletionResult]::new('--unit', 'unit', [CompletionResultType]::ParameterName, 'Report disk usage in binary or SI units')
            [CompletionResult]::new('-y', 'y', [CompletionResultType]::ParameterName, 'Which kind of layout to use when rendering the output')
            [CompletionResult]::new('--layout', 'layout', [CompletionResultType]::ParameterName, 'Which kind of layout to use when rendering the output')
            [CompletionResult]::new('--completions', 'completions', [CompletionResultType]::ParameterName, 'Print completions for a given shell to stdout')
            [CompletionResult]::new('-f', 'f', [CompletionResultType]::ParameterName, 'Follow symlinks')
            [CompletionResult]::new('--follow', 'follow', [CompletionResultType]::ParameterName, 'Follow symlinks')
            [CompletionResult]::new('-H', 'H', [CompletionResultType]::ParameterName, 'Print disk usage in human-readable format')
            [CompletionResult]::new('--human', 'human', [CompletionResultType]::ParameterName, 'Print disk usage in human-readable format')
            [CompletionResult]::new('-i', 'i', [CompletionResultType]::ParameterName, 'Do not respect .gitignore files')
            [CompletionResult]::new('--no-ignore', 'no-ignore', [CompletionResultType]::ParameterName, 'Do not respect .gitignore files')
            [CompletionResult]::new('-I', 'I', [CompletionResultType]::ParameterName, 'Display file icons')
            [CompletionResult]::new('--icons', 'icons', [CompletionResultType]::ParameterName, 'Display file icons')
            [CompletionResult]::new('-l', 'l', [CompletionResultType]::ParameterName, 'Show extended metadata and attributes')
            [CompletionResult]::new('--long', 'long', [CompletionResultType]::ParameterName, 'Show extended metadata and attributes')
            [CompletionResult]::new('--group', 'group', [CompletionResultType]::ParameterName, 'Show file''s groups')
            [CompletionResult]::new('--ino', 'ino', [CompletionResultType]::ParameterName, 'Show each file''s ino')
            [CompletionResult]::new('--nlink', 'nlink', [CompletionResultType]::ParameterName, 'Show the total number of hardlinks to the underlying inode')
            [CompletionResult]::new('--octal', 'octal', [CompletionResultType]::ParameterName, 'Show permissions in numeric octal format instead of symbolic')
            [CompletionResult]::new('--glob', 'glob', [CompletionResultType]::ParameterName, 'Enables glob based searching')
            [CompletionResult]::new('--iglob', 'iglob', [CompletionResultType]::ParameterName, 'Enables case-insensitive glob based searching')
            [CompletionResult]::new('-P', 'P', [CompletionResultType]::ParameterName, 'Remove empty directories from output')
            [CompletionResult]::new('--prune', 'prune', [CompletionResultType]::ParameterName, 'Remove empty directories from output')
            [CompletionResult]::new('-x', 'x', [CompletionResultType]::ParameterName, 'Prevent traversal into directories that are on different filesystems')
            [CompletionResult]::new('--one-file-system', 'one-file-system', [CompletionResultType]::ParameterName, 'Prevent traversal into directories that are on different filesystems')
            [CompletionResult]::new('-.', '.', [CompletionResultType]::ParameterName, 'Show hidden files')
            [CompletionResult]::new('--hidden', 'hidden', [CompletionResultType]::ParameterName, 'Show hidden files')
            [CompletionResult]::new('--no-git', 'no-git', [CompletionResultType]::ParameterName, 'Disable traversal of .git directory when traversing hidden files')
            [CompletionResult]::new('--dirs-only', 'dirs-only', [CompletionResultType]::ParameterName, 'Only print directories')
            [CompletionResult]::new('--no-config', 'no-config', [CompletionResultType]::ParameterName, 'Don''t read configuration file')
            [CompletionResult]::new('--no-progress', 'no-progress', [CompletionResultType]::ParameterName, 'Hides the progress indicator')
            [CompletionResult]::new('--suppress-size', 'suppress-size', [CompletionResultType]::ParameterName, 'Omit disk usage from output')
            [CompletionResult]::new('--truncate', 'truncate', [CompletionResultType]::ParameterName, 'Truncate output to fit terminal emulator window')
            [CompletionResult]::new('-h', 'h', [CompletionResultType]::ParameterName, 'Print help (see more with ''--help'')')
            [CompletionResult]::new('--help', 'help', [CompletionResultType]::ParameterName, 'Print help (see more with ''--help'')')
            [CompletionResult]::new('-V', 'V', [CompletionResultType]::ParameterName, 'Print version')
            [CompletionResult]::new('--version', 'version', [CompletionResultType]::ParameterName, 'Print version')
            break
        }
    })

    $completions.Where{ $_.CompletionText -like "$wordToComplete*" } |
        Sort-Object -Property ListItemText
}

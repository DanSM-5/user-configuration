#!/usr/bin/env pwsh

[CmdletBinding()]
Param (
  [Switch]
  $Help,
  [Switch]
  $Locations,
  [Switch]
  $Directories,
  [String[]]
  [Alias('f')]
  $FileLocations,
  [String[]]
  [Alias('b')]
  $FileDirectories,
  [String[]]
  [Alias('i', 'Include')]
  $Included,
  [String[]]
  [Alias('p', 'Path')]
  $Paths,
  [String]
  $Source = $null,
  [Switch]
  $Unique
)

$scriptName = $MyInvocation.MyCommand.Name
$all_directories = [System.Collections.ArrayList]::new()


function help () {

  Write-Output @"

  Get projects script

	Usage:
    ${scriptName}
    ${scriptName} [-h|--help]
    ${scriptName} [-l|--locations] [-d|--directories]
    ${scriptName} [-f|--file-locations] [/path/to/file]
    ${scriptName} [-b|--file-directories] [/path/to/file]
    ${scriptName} [-i|--include] [/path/to/directory]
    ${scriptName} [-p|--path] [/path/to/directory]
    ${scriptName} [-s|--source] [/path/to/directory]
    ${scriptName} [-u|--unique]

	Options:
    -h | --help                   Print this message
    -l | --locations              Print the content from "locations" file
    -d | --directories            Print the content from "directories" file
    -f | --file-locations         Get "locations" from the specific file provided
    -b | --file-directories       Get "directories" from the specific file provided
    -i | --include                Return "location" in the list
    -p | --path                   Get "directories" from specific path (using fd internally)
    -s | --source                 Use source path as base directory to search for "locations" and "directories" files
    -u | --unique                 Get a list of unique items

  Arguments:
    help                          Print this message

  Environment variables:
    PROJECTS_LOCATION             Path to use to search for "locations" and "directories" file

"@
}

$dirsep = if ($IsWindows) { '\' } else { '/' }

$base_dir = if ($Source) { $Source }
  elseif ($env:PROJECTS_LOCATION) { $env:PROJECTS_LOCATION }
  elseif ($user_conf_path) { "$user_conf_path/prj" }
  else { $HOME }

function expand_path ([string] $string_path) {
  $expanded = Invoke-Expression "Write-Output $string_path"
  $expanded = $expanded.Replace('~', $HOME)
  $expanded = $expanded.Replace('/', $dirsep)
  return $expanded.Replace('\', $dirsep).Trim()
}

# Get single directories
function get_locations ([String] $FilePath, [Switch] $RquiredPath) {
  if ($RquiredPath -and (-not $FilePath)) { return }
  $locations_file = if ($FilePath) { $FilePath } else { "$base_dir/locations" }
  if (Test-Path -PathType Leaf -Path "$locations_file" -ErrorAction SilentlyContinue) {
    Get-Content "$locations_file" | % {
      if ($_) {
        if ($_.StartsWith('#')) { return }
        $dir_path = expand_path $_
        if (Test-Path -PathType Container -Path $dir_path -ErrorAction SilentlyContinue) {
          $dir_path = $dir_path -Replace '\\$', ''
          $dir_path = $dir_path -Replace '/$', ''
          $null = $script:all_directories.Add($dir_path)
        }
      }
    }
  }
}

# Get content from listed directories
function get_directories ([String] $FilePath, [Switch] $RquiredPath) {
  if ($RquiredPath -and (-not $FilePath)) { return }
  $directories_file = if ($FilePath) { $FilePath } else { "$base_dir/directories" }
  if (Test-Path -PathType Leaf -Path "$directories_file" -ErrorAction SilentlyContinue) {
    Get-Content "$directories_file" | % {
      if ($_) {
        if ($_.StartsWith('#')) { return }
        $dir_path = expand_path $_
        if (-not (Test-Path -PathType Container -Path $dir_path -ErrorAction SilentlyContinue)) { return }
        $locations = @( fd --type 'directory' --type 'symlink' --max-depth 1 . "$dir_path" )
        foreach ($lock in $locations) {
          if (Test-Path -PathType Container -Path $lock -ErrorAction SilentlyContinue) {
            $lock = $lock -Replace '\\$', ''
            $lock = $lock -Replace '/$', ''
            $null = $script:all_directories.Add($lock)
          }
        }
      }
    }
  }
}

function get_directories_from_path ([String] $DirPath) {
  $target_path = $DirPath.Replace('~', $HOME).Replace('\\', $dirsep).Replace('/', $dirsep).Trim()
  if (-not (Test-Path -PathType Container -Path $target_path -ErrorAction SilentlyContinue)) { return }
  $locations = @( fd --type 'directory' --type 'symlink' --max-depth 1 . "$target_path" )
  foreach ($lock in $locations) {
    if (Test-Path -PathType Container -Path $lock -ErrorAction SilentlyContinue) {
      $lock = $lock -Replace '\\$', ''
      $lock = $lock -Replace '/$', ''
      $null = $script:all_directories.Add($lock)
    }
  }
}

if ($Help) {
  help
  exit
}

# Default behavior - Unique list of items from files
if ($PSBoundParameters.Count -eq 0) {
  get_locations
  get_directories

  return $all_directories | Sort -Unique
}

if ($Locations) {
  get_locations
}

if ($Directories) {
  get_directories
}

if ($FileLocations) {
  foreach ($location in $FileLocations) {
    get_locations $location -RquiredPath
  }
}

if ($FileDirectories) {
  foreach ($directory in $FileDirectories) {
    get_directories $directory -RquiredPath
  }
}

if ($Included) {
  foreach ($include in $Included) {
    $include = $include -Replace '\\$', ''
    $include = $include -Replace '/$', ''
    $null = $all_directories.Add($include)
  }
}

if ($Paths) {
  foreach ($path in $Paths) {
    get_directories_from_path $path
  }
}

if ($Unique) {
  return $all_directories | Sort -Unique
} else {
  return $all_directories
}


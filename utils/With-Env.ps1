
$ori = @{}
Try {
  $i = 0
  # $proc = $null

  # Loading .env files
  if(Test-Path $args[0]) {
    foreach($line in (Get-Content $args[0])) {
      if($line -Match '^\s*$' -Or $line -Match '^#') {
        continue
      }

      $key, $val = $line.Split("=")
      $ori[$key] = if(Test-Path Env:\$key) { (Get-Item Env:\$key).Value } else { "" }
      New-Item -Name $key -Value $val -ItemType Variable -Path Env: -Force > $null
    }

    $i++
  }

  while(1) {
    if($i -ge $args.length) {
      exit
    }

    # Stop look  on first argument without '=' sign
    # if(!($args[$i] -Match '^[^ ]+=[^ ]+$')) {
    if(!($args[$i] -Match '.+=.*')) {
      break
    }

    $index = $args[$i].IndexOf('=')
    $key = $args[$i].Substring(0, $index)
    $val = $args[$i].Substring($index + 1)
    # $key, $val = $args[$i].Split("=")
    # $val = if ($val) { $val } else { "" }
    $ori[$key] = if(Test-Path Env:\$key) { (Get-Item Env:\$key).Value } else { "" }
    New-Item -Name $key -Value $val -ItemType Variable -Path Env: -Force > $null

    $i++
  }

  $command = $args[$i..$args.length] | % {
    if ($_.Contains(' ')) {
      "'$_'"
    } else { $_ }
  }
  # Invoke-Expression ($command -Join " ")
  Invoke-Expression "$command"

  # $command = $args[$i]
  # $command_args = $args[($i + 1)..$args.length]
  # $std_out = New-Temporaryfile
  # echo "Process: $command_args"
  # $proc = Start-Process -FilePath $command -ArgumentList $command_args -NoNewWindow -PassThru -RedirectStandardOutput $std_out.FullName
  # # Wait for lf to exit
  # $proc.WaitForExit()
  # # Clean process reference
  # $proc = $null
  # Get-Content $std_out
} Finally {
  # $proc = $null
  foreach($key in $ori.Keys) {
    New-Item -Name $key -Value $ori.Item($key) -ItemType Variable -Path Env: -Force > $null
  }
}

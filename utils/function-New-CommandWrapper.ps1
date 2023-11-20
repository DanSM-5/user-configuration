
function New-CommandWrapper () {
  [CmdletBinding()]
  param(
      [Parameter(Mandatory=$true, Position=0)]
      [System.Object]
      ${Name},

      [Parameter(Position=1)]
      [scriptblock]
      ${Begin},

      [Parameter(Position=2)]
      [scriptblock]
      ${Process},

      [Parameter(Position=3)]
      [scriptblock]
      ${End},

      [Parameter(Position=4)]
      [hashtable]
      ${AddParameter})

  begin
  {
      try {
          $outBuffer = $null
          if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
          {
              $PSBoundParameters['OutBuffer'] = 1
          }

          $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand("$env:user_conf_path\utils\New-CommandWrapper.ps1", [System.Management.Automation.CommandTypes]::ExternalScript)
          $scriptCmd = {& $wrappedCmd @PSBoundParameters }

          $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
          $steppablePipeline.Begin($PSCmdlet)
      } catch {
          throw
      }
  }

  process
  {
      try {
          $steppablePipeline.Process($_)
      } catch {
          throw
      }
  }

  end
  {
      try {
          $steppablePipeline.End()
      } catch {
          throw
      }
  }

  clean
  {
      if ($null -ne $steppablePipeline) {
          $steppablePipeline.Clean()
      }
  }
<#

.ForwardHelpTargetName $env:user_conf_path\utils\New-CommandWrapper.ps1
.ForwardHelpCategory ExternalScript

#>
}

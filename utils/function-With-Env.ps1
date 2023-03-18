
# Mimic env.exe to include env variables to call a ps1 script
# E.g. With-Env VAR=VAL script.ps1
# Ref: https://devblogs.microsoft.com/scripting/proxy-functions-spice-up-your-powershell-core-cmdlets/
# PS > $MetaData = New-Object System.Management.Automation.CommandMetaData (Get-Command  Some-Command)
# PS > [System.Management.Automation.ProxyCommand]::Create($MetaData)
function With-Env () {
  param()

  begin
  {
      try {
          $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand("$env:user_conf_path\utils\With-Env.ps1", [System.Management.Automation.CommandTypes]::ExternalScript)
          $PSBoundParameters.Add('$args', $args)
          $scriptCmd = {& $wrappedCmd @PSBoundParameters }

          $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
          $steppablePipeline.Begin($myInvocation.ExpectingInput, $ExecutionContext)
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
  <#
    .ForwardHelpTargetName $env:user_conf_path\utils\With-Env.ps1
    .ForwardHelpCategory ExternalScript
  #>
}

# Alias to Set-Env
if (Test-Path Alias:Set-Env) { Remove-Item Alias:Set-Env }
Set-Alias -Name Set-Env -Value With-Env


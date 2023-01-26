<#
    .SYNOPSIS
    Get the current set DevOps Context.

    .DESCRIPTION
    Get the current set DevOps Context.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Organization or Projectname of the current Context.


    .EXAMPLE

    Gets the Current-Context Organization:

    PS> Get-DevOpsCurrentContext -Organization

    .EXAMPLE

    Gets the Current-Context Project:

    PS> Get-DevOpsCurrentContext -Project
    
    .LINK
        
#>
function Get-DevOpsCurrentContext {

    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'proj')]
        [switch]
        $Project,

        [Parameter(ParameterSetName = 'org')]
        [switch]
        $Organization
    )

    $Context = Get-Content -Path "$PSScriptRoot/.context.current.json" -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue

    if (!$Context) {
        Write-Warning 'No Context Set! Setting Default Context!'
        $Context = Set-DevOpsCurrentContext -Default
    }
    
    if ($Project) {
        return $Context.Project
    }
    elseif ($Organization) {
        return $Context.Organization
    }
}
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

    PS> Get-DevOpsContext -Organization

    .EXAMPLE

    Gets the Current-Context Project:

    PS> Get-DevOpsContext -Project
    
    .LINK
        
#>
function Get-DevOpsContext {

    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'proj')]
        [switch]
        $Project,

        [Parameter(ParameterSetName = 'org')]
        [switch]
        $Organization
    )

    $Context = Get-UtilsCache -Type Context -Identifier DevOps

    if (!$Context) {
        Write-Warning 'No Context Set! Setting Default Context!'
        $Context = Set-DevOpsContext -Default
    }
    
    if ($Project) {
        return $Context.Project
    }
    elseif ($Organization) {
        return $Context.Organization
    }
}
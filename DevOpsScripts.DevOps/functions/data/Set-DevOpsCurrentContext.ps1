<#
    .SYNOPSIS
    Set the Current DevOps Context. Use Switch-Project and Switch-Organization instead.

    .DESCRIPTION
    Set the Current DevOps Context. Use Switch-Project and Switch-Organization instead.
    
    .LINK
        
#>
function Set-DevOpsCurrentContext {

    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'set')]
        [System.String]
        $Project,

        [Parameter(ParameterSetName = 'set')]
        [System.String]
        $Organization,

        [Parameter(ParameterSetName = 'default')]
        [switch]
        $Default
    )    

    if ($Default) {
        $Context = @{
            Project      = 'DC Azure Migration' #TeamsBuilder
            Organization = 'baugruppe' 
        }     
    }
    else {

        $Context = @{
            Project      = [System.String]::IsNullOrEmpty($Project) ? (Get-DevOpsCurrentContext -Project) : $Project
            Organization = [System.String]::IsNullOrEmpty($Organization) ? (Get-DevOpsCurrentContext -Organization) : $Organization
        } 
    }

    $Context | ConvertTo-Json -Depth 2 | Out-File "$PSScriptRoot/.context.current.json"
    return $Context
    
}

<#
    .SYNOPSIS
    Set the Current DevOps Context. Use Switch-Project and Switch-Organization instead.

    .DESCRIPTION
    Set the Current DevOps Context. Use Switch-Project and Switch-Organization instead.
    
    .LINK
        
#>
function Set-DevOpsContext {

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
            Project      = $null # 'DC Azure Migration' #TeamsBuilder
            Organization = $null # 'baugruppe' 
        }     
    }
    else {

        $Context = @{
            Project      = [System.String]::IsNullOrEmpty($Project) ? (Get-DevOpsContext -Project) : $Project
            Organization = [System.String]::IsNullOrEmpty($Organization) ? (Get-DevOpsContext -Organization) : $Organization
        } 
    }

    return Set-UtilsCache -Object $Context -Type Context -Identifier DevOps -Forever
    
}

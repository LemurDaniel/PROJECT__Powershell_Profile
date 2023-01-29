<#
    .SYNOPSIS
    Add a new Quick-Context with an organization and a Projectname. 

    .DESCRIPTION
    Add a new Quick-Context with an organization and a Projectname.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Hashtable of all set Quick-Context.


    .EXAMPLE

    Add the Current Context as a Quick-Context:

    PS> Add-QuickContext -ContextName <Context_name>


    .EXAMPLE

    Add a new Quick-Context by Name:

    PS> Add-QuickContext -ContextName <Context_name> -Organization <Organization> -Project <Project_Name>


    .LINK
        
#>
function Add-QuickContext {

    [CmdletBinding()]
    param (
        # The Name of the Quick Context to be added. If both Organization and Project is not set, will default to current-context.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = 'Current'
        )]
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Custom'
        )]
        [System.String]
        $ContextName,

        # The Organization-Part of the Added Quick-Context. 
        [Parameter(
            Position = 1,
            Mandatory = $true,
            ParameterSetName = 'Custom'
        )]
        [System.String]
        $Organization,

        # The Project-Part of the Added Quick-Context.
        [Parameter(
            Position = 2,
            Mandatory = $true,
            ParameterSetName = 'Custom'
        )]
        [System.String]
        $Project,


        [Parameter(

        )]
        [switch]
        $Force
    )

    $contexts = Get-QuickContexts
    if (!$Force -AND $contexts[$ContextName]) {
        throw 'Context with same name already exists'
    }
    $contexts[$ContextName] = @{
        ContextName  = $ContextName
        Organization = [System.String]::IsNullOrEmpty($Organization) ? (Get-DevOpsCurrentContext -Organization) : $Organization 
        Project      = [System.String]::IsNullOrEmpty($Project) ? (Get-DevOpsCurrentContext -Project) : $Project   
    }

    return Set-UtilsCache -Object $contexts -Type Context -Identifier quick -Forever
}
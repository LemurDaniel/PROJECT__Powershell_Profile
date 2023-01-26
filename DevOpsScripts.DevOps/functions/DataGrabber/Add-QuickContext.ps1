
function Add-QuickContext {

    [CmdletBinding()]
    param (
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

        [Parameter(
            Position = 1,
            Mandatory = $true,
            ParameterSetName = 'Custom'
        )]
        [System.String]
        $Organization,

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
    if(!$Force -AND $contexts[$ContextName]) {
        throw 'Context with same name already exists'
    }
    $contexts[$ContextName] = @{
        ContextName  = $ContextName
        Organization = [System.String]::IsNullOrEmpty($Organization) ? (Get-DevOpsCurrentContext -Organization) : $Organization 
        Project      = [System.String]::IsNullOrEmpty($Project) ? (Get-DevOpsCurrentContext -Project) : $Project   
    }

    return Set-UtilsCache -Object $contexts -Type Context -Identifier quick
}
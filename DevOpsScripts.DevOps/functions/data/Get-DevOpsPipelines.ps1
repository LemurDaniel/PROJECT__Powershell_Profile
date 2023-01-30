<#
    .SYNOPSIS
    Gets all DevOps Pipelines in the Current Project.

    .DESCRIPTION
    Gets all DevOps Pipelines in the Current Project.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The DevOps Pipelines of the Current Project.


    .EXAMPLE

    Gets all Names of the DevOps Pipelines of the Current Project.

    PS> Get-DevOpsPipelines 'name'
    
    .LINK
        
#>
function Get-DevOpsPipelines {

    [cmdletbinding()]
    param(
        # The return Property
        [Parameter()]
        [System.String]
        $Property,

        # Switch to refresh the cache.
        [Parameter()]
        [switch]
        $refresh
    )

    $projectId = Get-ProjectInfo 'id'
    $Pipelines = Get-AzureDevOpsCache -Type Pipeline -Identifier $projectId

    if (!$Pipelines -OR $refresh) {
        # Get Pipelines.
        $Request = @{
            Method = 'GET'
            Domain = 'dev.azure'
            SCOPE  = 'PROJ'
            API    = '_apis/pipelines?api-version=7.0'
        }
        $Pipelines = Invoke-DevOpsRest @Request -Property 'value'
        $Pipelines = Set-AzureDevOpsCache -Object $Pipelines -Type Pipeline -Identifier $projectId
    }

    return Get-Property -Object $Pipelines -Property $Property
}
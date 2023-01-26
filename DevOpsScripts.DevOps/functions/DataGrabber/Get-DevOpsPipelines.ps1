
function Get-DevOpsPipelines {

    [cmdletbinding()]
    param(
        [Parameter()]
        [System.String]
        $Property,

        [Parameter()]
        [switch]
        $refresh
    )

    $Pipelines = Get-AzureDevOpsCache -Type Pipeline -Identifier (Get-ProjectInfo 'name')

    if (!$Pipelines -OR $refresh) {
        # Get Pipelines.
        $Request = @{
            Method = 'GET'
            Domain = 'dev.azure'
            SCOPE  = 'PROJ'
            API    = '_apis/pipelines?api-version=7.0'
        }
        $Pipelines = Invoke-DevOpsRest @Request -Property 'value'
    }

    $null = Set-AzureDevOpsCache -Object $Pipelines -Type Pipeline -Identifier (Get-ProjectInfo 'name')
    return Get-Property -Object $Pipelines -Property $Property
}
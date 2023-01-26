

function Open-BuildInBrowser {
    
    [cmdletbinding()]
    param (
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'pipeLineId'
        )]
        [System.String]
        $pipeLineId,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'buildId'
        )]
        [System.String]
        $buildId
    )


    # Get Latest Build for Pipeline
    if ($pipeLineId) {
        $Request = @{
            Method = 'GET'
            Domain = 'dev.azure'
            SCOPE  = 'PROJ'
            API    = "/_apis/build/latest/$($pipeLineId)?api-version=7.0-preview.1"
        }
        $buildId = Invoke-DevOpsRest @Request -return 'id'
    }

    $Organization = Get-DevOpsCurrentContext -Organization
    $projectNameUrlEncoded = (Get-ProjectInfo 'name') -replace ' ', '%20'

    # Open in Browser.
    $pipelineUrl = "https://dev.azure.com/$Organization/$projectNameUrlEncoded/_build/results?buildId=$($buildId)&view=logs"
    Start-Process $pipelineUrl

    return $pipelineUrl
}

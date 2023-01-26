

function Open-BuildInBrowser {
    
    [cmdletbinding()]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = 'pipeLineName'
        )]
        [ValidateScript(
            {
                $_ -in (Get-DevOpsPipelines 'name')
            }
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = Get-DevOpsPipelines 'name'
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        $Name,

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

    if (!$PipelineId) {
        $pipeLineId = Search-In (Get-DevOpsPipelines) -where name -is $name -return id
    }

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

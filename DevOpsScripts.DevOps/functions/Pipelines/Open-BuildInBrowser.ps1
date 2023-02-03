
<#
    .SYNOPSIS
    Open a specific build or the latest build by pipeline name or id in the Browser.

    .DESCRIPTION
    Open a specific build or the latest build by pipeline name or id in the Browser. 

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Open the latest build for a Pipeline in the current Project-Context:

    PS> Open-BuildInBrowser '<Pipeline_name>'

    .EXAMPLE

    Open the latest build for a Pipeline in the current Project-Context:

    PS> Open-BuildInBrowser -pipelineId '<Pipeline_id>'

    .EXAMPLE

    Open the latest build for a Pipeline in the current Project-Context:

    PS> Open-BuildInBrowser -buildId '<Build_id>'


    .LINK
        
#>
function Open-BuildInBrowser {
    
    [cmdletbinding()]
    param (
        # The Pipeline name in the current Project autocompleted.
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

        # The Pipeline-Id in the Current-Project.
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'pipeLineId'
        )]
        [System.String]
        $pipeLineId,

        # The Build-Id in the current-Project.
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'buildId'
        )]
        [System.String]
        $buildId
    )

    if ([System.String]::IsNullOrEmpty($buildId)) {
        if ([System.String]::IsNullOrEmpty($pipeLineId)) {
            $pipeLineId = Search-In (Get-DevOpsPipelines) -where name -has $name -return id
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
    }

    $Organization = Get-DevOpsContext -Organization
    $projectNameUrlEncoded = (Get-ProjectInfo 'name') -replace ' ', '%20'

    # Open in Browser.
    $pipelineUrl = "https://dev.azure.com/$Organization/$projectNameUrlEncoded/_build/results?buildId=$($buildId)&view=logs"
    Start-Process $pipelineUrl

    return $pipelineUrl
}

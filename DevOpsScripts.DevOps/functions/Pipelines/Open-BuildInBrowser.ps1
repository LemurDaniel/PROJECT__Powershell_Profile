
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
        # The name of the Project to swtich to in which you want to open a repository. Will default to curren tproject context.
        [Parameter(
            ParameterSetName = 'Projectspecific',
            Mandatory = $true,
            Position = 1
        )] 
        [Parameter(
            ParameterSetName = 'ProjectspecificBuildId',
            Mandatory = $true,
            Position = 1
        )]   
        [Parameter(
            ParameterSetName = 'ProjectspecificPipeLineId',
            Mandatory = $true,
            Position = 1
        )]     
        [ValidateScript(
            { 
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-DevOpsProjects).name
            },
            ErrorMessage = 'Please specify a correct Projectname.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-DevOpsProjects).name 
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Project,

        # The Pipeline name in the current Project autocompleted.
        [Parameter(
            ParameterSetName = 'Projectspecific',
            Mandatory = $true,
            Position = 0
        )]
        [Parameter(
            ParameterSetName = 'currentContext',
            Mandatory = $false,
            Position = 0
        )]   
        [ValidateScript(
            { 
                # NOTE cannot access Project when changes dynamically with tab-completion
                $true 
            },
            ErrorMessage = 'Please specify an correct Name.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = Get-DevOpsPipelines -Project $fakeBoundParameters['Project']
                
                $validValues.name | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Name,


        # The Pipeline name in the current Project autocompleted.
        [Parameter(
            ParameterSetName = 'ProjectspecificPipeLineId',
            Mandatory = $true
        )]
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'pipeLineId'
        )]
        [System.String]
        $pipeLineId,

        # The Pipeline name in the current Project autocompleted.
        [Parameter(
            ParameterSetName = 'ProjectspecificBuildId',
            Mandatory = $true
        )]
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'buildId'
        )]
        [System.String]
        $buildId
    )

    if ([System.String]::IsNullOrEmpty($buildId)) {
        if ([System.String]::IsNullOrEmpty($pipeLineId)) {
            $pipeLineId = Get-DevOpsPipelines -Project $Project | Where-Object -Property Name -EQ $Name | Select-Object -ExpandProperty id
        }

        # Get Latest Build for Pipeline
        if ($pipeLineId) {
            $Request = @{
                Project = $Project
                Method  = 'GET'
                Domain  = 'dev.azure'
                SCOPE   = 'PROJ'
                API     = "/_apis/build/latest/$($pipeLineId)?api-version=7.0-preview.1"
            }
            $buildId = Invoke-DevOpsRest @Request -return 'id'
        }
    }

    $Organization = Get-DevOpsContext -Organization
    $projectNameUrlEncoded = (Get-ProjectInfo -Name $Project).name -replace ' ', '%20'

    # Open in Browser.
    $pipelineUrl = "https://dev.azure.com/$Organization/$projectNameUrlEncoded/_build/results?buildId=$($buildId)&view=logs"
    Start-Process $pipelineUrl

    return $pipelineUrl
}

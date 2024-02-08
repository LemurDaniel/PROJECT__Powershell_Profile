<#
    .SYNOPSIS
    Creates a new disptach event for a workflow on any branch.

    .DESCRIPTION
    Creates a new disptach event for a workflow on any branch.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Invoke a dispatch event for a workflow for the current repository:

    PS> Invoke-WorkflowDispatchEvent <autocompleted_workflow> -Dispatch


    .EXAMPLE

    Invoke a dispatch event for a workflow for another repository:

    PS> Invoke-WorkflowDispatchEvent -Repository <autocomplete_repo> <autocompleted_workflow> -Dispatch


    .LINK
        
#>

function Invoke-WorkflowDispatchEvent {

    [CmdletBinding()]
    [Alias('git-wf')]
    param (
        [Parameter(
            Position = 3,
            Mandatory = $false
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-GithubAccountContext -ListAvailable).name
                
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [validateScript(
            {
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-GithubAccountContext -ListAvailable).name
            }
        )]
        [Alias('a')]
        $Account,

        # The Name of the Github Context to use. Defaults to current Context.
        [Parameter(
            Mandatory = $false,
            Position = 2
        )]
        [ValidateScript(
            { 
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-GithubContexts -Account $PSBoundParameters['Account']).login
            },
            ErrorMessage = 'Please specify an correct Context.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)
                $validValues = (Get-GithubContexts -Account $fakeBoundParameters['Account']).login
        
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        [Alias('c')]
        $Context,

        
        # The Name of the Github Repository.
        [Parameter(
            Mandatory = $false,
            Position = 1
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)
                $Context = Get-GithubContextInfo -Account $fakeBoundParameters['Account'] -Context $fakeBoundParameters['Context']
                $validValues = $Context.repositories.Name

                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        [Alias('r')]
        $Repository,

        # The filename of the workflow.
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)
                
                $Repository = @{
                    Repository = $fakeBoundParameters['Repository']
                    Context    = $fakeBoundParameters['Context']
                    Account    = $fakeBoundParameters['Account']
                }
                $validValues = Get-GithubWorkflow @Repository
                | Select-Object -ExpandProperty file_name
                
                $validValues
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Name,

        # The ref-name for the dispatch event. Either a tag or branch. Defaults to defaukt branch.
        [Parameter(
            Mandatory = $false
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)
                $Repository = @{
                    Repository = $fakeBoundParameters['Repository']
                    Context    = $fakeBoundParameters['Context']
                    Account    = $fakeBoundParameters['Account']
                }
                $validValues = Get-GithubBranches @Repository
                | Select-Object -ExpandProperty name

                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Ref,

        # A dictionary of inputs for the workflow.
        [Parameter(
            Mandatory = $false
        )]
        [System.Collections.Hashtable]
        $Inputs = @{},

        # Prevent opening the workflow in the browser.
        [Parameter()]
        [switch]
        $NoBrowserLaunch,

        # Create a workflow dispatch event.
        [Parameter()]
        [switch]
        $Dispatch
    )

    
    $repositoryData = Get-GithubRepositoryInfo -Account $Account -Context $Context -Name $Repository
    $repositoryIdentifier = @{
        Account    = $repositoryData.Account
        Context    = $RepositoryData.Context
        Repository = $repositoryData.Name
    }

    $workflow = Get-GithubWorkflow @repositoryIdentifier -Name $Name

    if ($Dispatch) {
        $Request = @{
            Method  = "POST"
            Account = $repositoryData.Account
            API     = "/repos/$($repositoryData.full_name)/actions/workflows/$($workflow.id)/dispatches"
            Body    = @{
                ref    = [System.String]::IsNullOrEmpty($ref) ? $repositoryData.default_branch : $ref
                inputs = @{}
            }
        }
        $null = Invoke-GithubRest @Request
    }

    if (!$NoBrowserLaunch) {
        if ($Dispatch) {
            Start-Sleep -Milliseconds 1500
        }
        Start-Process -FilePath "$($RepositoryData.html_url)/actions/workflows/$($workflow.file_name)"
    }
}
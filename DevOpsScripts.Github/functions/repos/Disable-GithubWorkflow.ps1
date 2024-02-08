<#
    .SYNOPSIS
    Enables a workflow.

    .DESCRIPTION
    Enables a workflow.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Enable a workflow for the current repository:

    PS> Disable-GithubWorkflow <autocompleted_workflow>

    .EXAMPLE

    Enable a workflow for the another repository:

    PS> Disable-GithubWorkflow -Repository <autocomplete_repo> <autocompleted_workflow>

    .EXAMPLE

    Enable a workflow for the a repository in another account:

    PS> Disable-GithubWorkflow -Account <autocompleted_account> <autocomplete_repo> <autocompleted_workflow>


    .EXAMPLE

    Enable a workflow for the a repository in another account and context:

    PS> Disable-GithubWorkflow -Account <autocompleted_account> -Context <autocomplete_context> <autocomplete_repo> <autocompleted_workflow>
    


    .LINK
        
#>

function Disable-GithubWorkflow {

    [CmdletBinding()]
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
            Mandatory = $false,
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
        $Name
    )

    
    $repositoryData = Get-GithubRepositoryInfo -Account $Account -Context $Context -Name $Repository
    $repositoryIdentifier = @{
        Account    = $repositoryData.Account
        Context    = $RepositoryData.Context
        Repository = $repositoryData.Name
    }

    $workflow = Get-GithubWorkflow @repositoryIdentifier -Name $Name

    $Request = @{
        Method  = "PUT"
        Account = $repositoryData.Account
        API     = "/repos/$($repositoryData.full_name)/actions/workflows/$($workflow.id)/disable"
        Body    = @{
            ref    = [System.String]::IsNullOrEmpty($ref) ? $repositoryData.default_branch : $ref
            inputs = @{}
        }
    }

    return Invoke-GithubRest @Request
}
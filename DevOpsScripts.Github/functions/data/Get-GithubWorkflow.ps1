<#
    .SYNOPSIS
    Retrieves a list of all workflows for that repository.

    .DESCRIPTION
    Retrieves a list of all workflows for that repository.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Get a list of workflows for the repository on the current path:

    PS> Get-GithubWorkflow


    .EXAMPLE

    Get a list of workflows of a specific repository in another account:

    PS> Get-GithubWorkflow -Account <autocompleted_account> <autocomplete_repo>


    .EXAMPLE

    Get a list of workflows in another Account and another Context:

    PS> Get-GithubWorkflow -Account <autocompleted_account> -Context <autocomplete_context> <autocomplete_repo>
    


    .LINK
        
#>

function Get-GithubWorkflow {

    [CmdletBinding()]
    param (
        # The name of the github account to use. Defaults to current Account.
        [Parameter(
            Position = 3,
            Mandatory = $false
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Account' })]
        [System.String]
        [Alias('a')]
        $Account,

        # The Name of the Github Context to use. Defaults to current Context.
        [Parameter(
            Mandatory = $false,
            Position = 2
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Context' })]
        [System.String]
        [Alias('c')]
        $Context,

        # The Name of the Github Repository. Defaults to current Repository.
        [Parameter(
            Mandatory = $false,
            Position = 1
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Repository' })]
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
        $Name,

        [Parameter()]
        [switch]
        $Refresh
    )

    
    $repositoryData = Get-GithubRepositoryInfo -Account $Account -Context $Context -Name $Repository
    $repositoryIdentifier = @{
        Account    = $repositoryData.Account
        Context    = $RepositoryData.Context
        Repository = $repositoryData.Name
    }

    $data = Get-GithubCache @repositoryIdentifier -Identifier "workflows"

    if ($null -EQ $data -OR $Refresh) {
        $Request = @{
            Method  = "GET"
            API     = "/repos/$($repositoryData.full_name)/actions/workflows"
            Account = $repositoryData.Account
        }
        $data = Invoke-GithubRest @Request
        
        $data = $null -EQ $data ? @() : $data.workflows
        | Select-Object *, @{
            Name       = "file_name" 
            Expression = { $_.path -split '/' | Select-Object -Last 1 }
        }

        $data = Set-GithubCache -Object $data @repositoryIdentifier -Identifier "workflows"
    }

    if (![System.String]::IsNullOrEmpty($Name)) {
        return $data | Where-Object -Property file_name -EQ $Name
    }

    return $data
}
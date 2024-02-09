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

    Get workflows for the current repository:

    PS> Get-GithubWorkflow


    .EXAMPLE

    Get workflows for another repository:

    PS> Get-GithubWorkflow <autocomplete_repo>


    .EXAMPLE

    Get workflows for other accounts, contexts, etc:
    
    PS> Get-GithubWorkflow -Context <autocomplete_context> <autocomplete_repo>

    PS> Get-GithubWorkflow -Account <autocompleted_account> <autocomplete_repo>

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
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Workflow' })]
        [System.String]
        [Alias('Name')]
        $Workflow,

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

    if (![System.String]::IsNullOrEmpty($Workflow)) {
        return $data | Where-Object -Property file_name -EQ $Workflow
    }

    return $data
}
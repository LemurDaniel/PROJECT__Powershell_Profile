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

    PS> Get-GitWorkflow


    .EXAMPLE

    Get workflows for another repository:

    PS> Get-GitWorkflow <autocomplete_repo>


    .EXAMPLE

    Get workflows for other accounts, contexts, etc:
    
    PS> Get-GitWorkflow -Context <autocomplete_context> <autocomplete_repo>

    PS> Get-GitWorkflow -Account <autocompleted_account> <autocomplete_repo>

    PS> Get-GitWorkflow -Account <autocompleted_account> -Context <autocomplete_context> <autocomplete_repo>
    


    .LINK
        
#>

function Get-GitWorkflow {

    [CmdletBinding()]
    param (
        # The name of the Git account to use. Defaults to current Account.
        [Parameter(
            Position = 3,
            Mandatory = $false
        )]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Account' })]
        [System.String]
        [Alias('a')]
        $Account,

        # The Name of the Git Context to use. Defaults to current Context.
        [Parameter(
            Mandatory = $false,
            Position = 2
        )]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Context' })]
        [System.String]
        [Alias('c')]
        $Context,

        # The Name of the Git Repository. Defaults to current Repository.
        [Parameter(
            Mandatory = $false,
            Position = 1
        )]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Repository' })]
        [System.String]
        [Alias('r')]
        $Repository,
        

        # The filename of the workflow.
        [Parameter(
            Mandatory = $false,
            Position = 0
        )]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Workflow' })]
        [System.String]
        [Alias('Name')]
        $Workflow,

        [Parameter()]
        [switch]
        $Refresh
    )

    $repositoryData = Get-GitRepositoryInfo -Account $Account -Context $Context -Name $Repository
    $repositoryIdentifier = @{
        Account    = $repositoryData.Account
        Context    = $RepositoryData.Context
        Repository = $repositoryData.Name
    }

    $data = Get-GitCache @repositoryIdentifier -Identifier "workflows"

    if ($null -EQ $data -OR $Refresh) {
        $Request = @{
            Method  = "GET"
            API     = "/repos/$($repositoryData.full_name)/actions/workflows"
            Account = $repositoryData.Account
        }
        $data = Invoke-GitRest @Request
        
        $data = $null -EQ $data ? @() : $data.workflows
        | Select-Object *, @{
            Name       = "file_name" 
            Expression = { $_.path -split '/' | Select-Object -Last 1 }
        }

        $data = Set-GitCache -Object $data @repositoryIdentifier -Identifier "workflows"
    }

    if (![System.String]::IsNullOrEmpty($Workflow)) {
        return $data | Where-Object -Property file_name -EQ $Workflow
    }

    return $data
}
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

    PS> Enable-GithubWorkflow <autocompleted_workflow>

    .EXAMPLE

    Enable a workflow for the another repository:

    PS> Enable-GithubWorkflow -Repository <autocomplete_repo> <autocompleted_workflow>

    .EXAMPLE

    Enable a workflow for the a repository in another account:

    PS> Enable-GithubWorkflow -Account <autocompleted_account> <autocomplete_repo> <autocompleted_workflow>


    .EXAMPLE

    Enable a workflow for the a repository in another account and context:

    PS> Enable-GithubWorkflow -Account <autocompleted_account> -Context <autocomplete_context> <autocomplete_repo> <autocompleted_workflow>
    


    .LINK
        
#>

function Enable-GithubWorkflow {

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
        $Workflow
    )

    
    $repositoryData = Get-GithubRepositoryInfo -Account $Account -Context $Context -Name $Repository
    $repositoryIdentifier = @{
        Account    = $repositoryData.Account
        Context    = $RepositoryData.Context
        Repository = $repositoryData.Name
    }

    $workflowObject = Get-GithubWorkflow @repositoryIdentifier -Name $Workflow

    $Request = @{
        Method  = "PUT"
        Account = $repositoryData.Account
        API     = "/repos/$($repositoryData.full_name)/actions/workflows/$($workflowObject.id)/enable"
        Body    = @{
            ref    = [System.String]::IsNullOrEmpty($ref) ? $repositoryData.default_branch : $ref
            inputs = @{}
        }
    }

    return Invoke-GithubRest @Request -Verbose
}
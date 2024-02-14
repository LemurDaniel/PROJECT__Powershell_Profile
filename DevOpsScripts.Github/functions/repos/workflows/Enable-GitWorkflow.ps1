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

    PS> Enable-GitWorkflow <autocompleted_workflow>

    .EXAMPLE

    Enable a workflow for the another repository:

    PS> Enable-GitWorkflow -Repository <autocomplete_repo> <autocompleted_workflow>

    .EXAMPLE

    Enable a workflow for the a repository in another account:

    PS> Enable-GitWorkflow -Account <autocompleted_account> <autocomplete_repo> <autocompleted_workflow>


    .EXAMPLE

    Enable a workflow for the a repository in another account and context:

    PS> Enable-GitWorkflow -Account <autocompleted_account> -Context <autocomplete_context> <autocomplete_repo> <autocompleted_workflow>
    


    .LINK
        
#>

function Enable-GitWorkflow {

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
        $Workflow
    )

    
    $repositoryData = Get-GitRepositoryInfo -Account $Account -Context $Context -Name $Repository
    $repositoryIdentifier = @{
        Account    = $repositoryData.Account
        Context    = $RepositoryData.Context
        Repository = $repositoryData.Name
    }

    $workflowObject = Get-GitWorkflow @repositoryIdentifier -Name $Workflow

    $Request = @{
        Method  = "PUT"
        Account = $repositoryData.Account
        API     = "/repos/$($repositoryData.full_name)/actions/workflows/$($workflowObject.id)/enable"
        Body    = @{
            ref    = [System.String]::IsNullOrEmpty($ref) ? $repositoryData.default_branch : $ref
            inputs = @{}
        }
    }

    return Invoke-GitRest @Request -Verbose
}
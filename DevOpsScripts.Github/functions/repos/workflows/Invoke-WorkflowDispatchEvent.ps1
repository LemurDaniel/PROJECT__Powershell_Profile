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

        # The ref-name for the dispatch event. Either a tag or branch. Defaults to defaukt branch.
        [Parameter(
            Mandatory = $false
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Ref' })]
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

    $workflowObject = Get-GithubWorkflow @repositoryIdentifier -Name $Workflow

    if ($Dispatch) {
        $Request = @{
            Method  = "POST"
            Account = $repositoryData.Account
            API     = "/repos/$($repositoryData.full_name)/actions/workflows/$($workflowObject.id)/dispatches"
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
        Start-Process -FilePath "$($RepositoryData.html_url)/actions/workflows/$($workflowObject.file_name)"
    }
}
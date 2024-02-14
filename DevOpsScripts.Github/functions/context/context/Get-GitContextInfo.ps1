<#
    .SYNOPSIS
    Get Information about a Git a Context.

    .DESCRIPTION
    Get Information about a Git a Context.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Information about the Repository.

    .EXAMPLE

    Get Info about the current Context:

    PS> Get-GitContextInfo

    .EXAMPLE

    Get Info about another Context:

    PS> Get-GitContextInfo <autocomplete_context>

    .LINK
        
#>

function Get-GitContextInfo {

    param(
        # The name of the Git account to use. Defaults to current Account.
        [Parameter(
            Position = 1,
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
            Position = 0
        )]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Context' })]
        [System.String]
        [Alias('c')]
        $Context,

        [Parameter()]
        [switch]
        $Refresh
    )

    $Context = [System.String]::IsNullOrEmpty($Context) ? (Get-GitContext -Account $Account) : $Context

    return Get-GitContexts -Account $Account -Refresh:$Refresh
    | Where-Object -Property login -EQ $Context
    | Select-Object *, @{
        Name       = 'repositories';
        Expression = {
            Get-GitRepositories -Account $Account -Context $Context -Refresh:$Refresh
        }
    }

}

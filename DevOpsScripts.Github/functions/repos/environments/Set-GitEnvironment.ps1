<#
    .SYNOPSIS
    Adds or Updates an environment to a Git-Repository.

    .DESCRIPTION
    Adds or Updates a environment to a Git-Repository.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Adding/Updating a secret to the repository on the current path:

    PS> Set-GitSecret -Name "Secret" -Value "SecretValue"

    .EXAMPLE

    Adding/Updating a multiple secrets to the repository on the current path:

    PS> Set-GitSecret -Secrets @{
        Secret1 = "SecretValue"
        Secret2 = "SecretValue"
    }


    .LINK
        
#>

function Set-GitEnvironment {

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
            Position = 0
        )]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Repository' })]
        [System.String]
        [Alias('r')]
        $Repository,

        # The Name of the environment.
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Name
    )

    $repositoryData = Get-GitRepositoryInfo -Account $Account -Context $Context -Name $Repository

    $Request = @{
        METHOD  = "PUT"
        API     = "/repos/$($repositoryData.full_name)/environments/$Name"
        Account = $repositoryData.Account
        Body    = @{

        }
    }

    return Invoke-GitRest @Request
    
}
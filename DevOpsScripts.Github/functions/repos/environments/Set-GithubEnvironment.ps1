<#
    .SYNOPSIS
    Adds or Updates an environment to a Github-Repository.

    .DESCRIPTION
    Adds or Updates a environment to a Github-Repository.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Adding/Updating a secret to the repository on the current path:

    PS> Set-GithubSecret -Name "Secret" -Value "SecretValue"

    .EXAMPLE

    Adding/Updating a multiple secrets to the repository on the current path:

    PS> Set-GithubSecret -Secrets @{
        Secret1 = "SecretValue"
        Secret2 = "SecretValue"
    }


    .LINK
        
#>

function Set-GithubEnvironment {

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
            Position = 0
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Repository' })]
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

    $repositoryData = Get-GithubRepositoryInfo -Account $Account -Context $Context -Name $Repository

    $Request = @{
        METHOD  = "PUT"
        API     = "/repos/$($repositoryData.full_name)/environments/$Name"
        Account = $repositoryData.Account
        Body    = @{

        }
    }

    return Invoke-GithubRest @Request
    
}
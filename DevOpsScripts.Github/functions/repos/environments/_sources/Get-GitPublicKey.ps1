<#
    .SYNOPSIS
    Get the public key for a repository.

    .DESCRIPTION
    Get the public key for a repository. This is needed for encryption. Secrets need to encrypted this way before sending them via the API.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None

    .EXAMPLE

    Get public key for the repository on the current path:

    PS> Get-GitPublicKey



    .LINK
        
#>

function Get-GitPublicKey {

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
        

        # If provided returns the public encryption key for that environment.
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Environment
    )

    $repositoryData = Get-GitRepositoryInfo -Account $Account -Context $Context -Name $Repository
    $repositoryIdentifier = @{
        Account    = $repositoryData.Account
        Context    = $repositoryData.Context
        Repository = $repositoryData.Repository
    }

    $Identifier = $null
    $remoteUrl = $null

    if ([System.String]::IsNullOrEmpty($Environment)) {
        $Identifier = "publickey"
        $remoteUrl = "/repos/$($repositoryData.full_name)/actions/secrets/public-key"    
    }
    else {
        $Identifier = "publickey.$environment"
        $remoteUrl = "/repositories/$($repositoryData.id)/environments/$environment/secrets/public-key"
    }

    $data = Get-GitCache -Identifier $Identifier @repositoryIdentifier

    if ($null -EQ $data) {
        $data = Invoke-GitRest -Method GET -API $remoteUrl -Account $repositoryData.Account
        $data = Set-GitCache -Object $data -Identifier $Identifier @repositoryIdentifier
    }

    return $data
}
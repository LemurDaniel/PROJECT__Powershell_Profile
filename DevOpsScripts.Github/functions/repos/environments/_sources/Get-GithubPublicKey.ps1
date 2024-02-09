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

    PS> Get-GithubPublicKey



    .LINK
        
#>

function Get-GithubPublicKey {

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
        

        # If provided returns the public encryption key for that environment.
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Environment
    )

    $repositoryData = Get-GithubRepositoryInfo -Account $Account -Context $Context -Name $Repository

    $Identifier = $null
    $remoteUrl = $null

    if ([System.String]::IsNullOrEmpty($Environment)) {
        $Identifier = "publickey.$($repositoryData.Context).$($repositoryData.name)"
        $remoteUrl = "/repos/$($repositoryData.full_name)/actions/secrets/public-key"    
    }
    else {
        $Identifier = "publickey.$($repositoryData.Context).$($repositoryData.name).$environment"
        $remoteUrl = "/repositories/$($repositoryData.id)/environments/$environment/secrets/public-key"
    }

    $data = Get-GithubCache -Identifier $Identifier -Account $repositoryData.Account

    if ($null -EQ $data) {
        $data = Invoke-GithubRest -Method GET -API $remoteUrl -Account $repositoryData.Account
        $data = Set-GithubCache -Object $data -Identifier $Identifier -Account $repositoryData.Account
    }

    return $data
}
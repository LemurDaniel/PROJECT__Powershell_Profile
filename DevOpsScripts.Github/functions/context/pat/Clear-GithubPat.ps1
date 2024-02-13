
<#
    .SYNOPSIS
    Clear the encrypted Git pat stored for Windows user.

    .DESCRIPTION
    Clear the encrypted Git pat stored for Windows user.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Github Pat

    
    .LINK
        
#>
function Clear-GithubPAT {

    param(
        # The name of the github account to use. Defaults to current Account.
        [Parameter(
            Position = 0,
            Mandatory = $false
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Account' })]
        [System.String]
        [Alias('a')]
        $Account,

        # clear it without setting a new pat
        [Parameter()]
        [switch]
        $Clear
    )
    

    $AccountContext = Get-GithubAccountContext -Account $Account
    Clear-SecureStringFromFile -Identifier "git.pat.$($AccountContext.patRef)"
    if (!$Clear) {
        Get-GithubUser -Account $Account -Refresh
    }
}
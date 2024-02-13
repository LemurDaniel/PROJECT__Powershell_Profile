
<#
    .SYNOPSIS
    Get the encrypted Git pat stored for Windows user.

    .DESCRIPTION
    Get the encrypted Git pat stored for Windows user.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Github Pat

    
    .LINK
        
#>
function Get-GithubPAT {

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

        # Retrives as Plain text rather than a secure string.
        [Parameter()]
        [switch]
        $AsPlainText
    )
    

    $AccountContext = Get-GithubAccountContext -Account $Account
    $identifier = "git.pat.$($AccountContext.patRef)"
    # Authentication
    $GIT_PAT = Read-SecureStringFromFile -Identifier $identifier -AsPlainText:$AsPlainText

    if ([System.String]::isNullOrEmpty($GIT_PAT)) {
        $GIT_PAT = Read-Host -AsSecureString -Prompt "Please Enter PAT for '$($AccountContext.name)'"
        Save-SecureStringToFile -SecureString $GIT_PAT -Identifier "git.pat.$($AccountContext.patRef)"

        if ($AsPlainText) {
            $GIT_PAT = $GIT_PAT | ConvertFrom-SecureString -AsPlainText
        }
    }

    return $GIT_PAT
}
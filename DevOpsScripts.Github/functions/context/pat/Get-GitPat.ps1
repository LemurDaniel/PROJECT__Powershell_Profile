
<#
    .SYNOPSIS
    Get the encrypted Git pat stored for Windows user.

    .DESCRIPTION
    Get the encrypted Git pat stored for Windows user.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Git Pat

    
    .LINK
        
#>
function Get-GitPAT {

    param(
        # The name of the Git account to use. Defaults to current Account.
        [Parameter(
            Position = 0,
            Mandatory = $false
        )]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Account' })]
        [System.String]
        [Alias('a')]
        $Account,

        # Retrives as Plain text rather than a secure string.
        [Parameter()]
        [switch]
        $AsPlainText
    )
    

    $AccountContext = Get-GitAccountContext -Account $Account
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
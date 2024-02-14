
<#
    .SYNOPSIS
    Clear the encrypted Git pat stored for Windows user.

    .DESCRIPTION
    Clear the encrypted Git pat stored for Windows user.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Git Pat

    
    .LINK
        
#>
function Clear-GitPAT {

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

        # clear it without setting a new pat
        [Parameter()]
        [switch]
        $Clear
    )
    

    $AccountContext = Get-GitAccountContext -Account $Account
    Clear-SecureStringFromFile -Identifier "git.pat.$($AccountContext.patRef)"
    if (!$Clear) {
        Get-GitUser -Account $Account -Refresh
    }
}
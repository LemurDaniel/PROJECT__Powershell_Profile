
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
        # Clear old credential Info and replace with new one.
        [Parameter()]
        [switch]
        $Clear,

        # Retrives as Plain text rather than a secure string.
        [Parameter()]
        [switch]
        $AsPlainText
    )
    
    # Authentication
    $GIT_PAT = Read-SecureStringFromFile -Identifier GitPersonalPAT -AsPlainText:$AsPlainText

    if ($Clear -OR [System.String]::isNullOrEmpty($GIT_PAT)) {
        $GIT_PAT = Read-Host -AsSecureString -Prompt 'Please Enter your Personal Git PAT'
        Save-SecureStringToFile -SecureString $GIT_PAT -Identifier GitPersonalPAT

        if ($AsPlainText) {
            $GIT_PAT = $GIT_PAT | ConvertFrom-SecureString -AsPlainText
        }
    }

    return $GIT_PAT
}
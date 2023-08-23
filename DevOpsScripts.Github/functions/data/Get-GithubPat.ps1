
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
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-UtilsCache -Identifier context.accounts.all -AsHashTable).keys
                    
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        $Account,

        # Clear old credential Info and replace with new one.
        [Parameter()]
        [switch]
        $Clear,

        # Retrives as Plain text rather than a secure string.
        [Parameter()]
        [switch]
        $AsPlainText
    )
    

    $AccountContext = Get-GithubAccountContext -Account $Account
    $identifier = "git.pat.$($AccountContext.patRef)"
    # Authentication
    $GIT_PAT = Read-SecureStringFromFile -Identifier $identifier -AsPlainText:$AsPlainText

    if ($Clear -OR [System.String]::isNullOrEmpty($GIT_PAT)) {
        $GIT_PAT = Read-Host -AsSecureString -Prompt "Please Enter PAT for '$($AccountContext.name)'"
        Save-SecureStringToFile -SecureString $GIT_PAT -Identifier "git.pat.$($AccountContext.patRef)"

        if ($AsPlainText) {
            $GIT_PAT = $GIT_PAT | ConvertFrom-SecureString -AsPlainText
        }
    }

    return $GIT_PAT
}
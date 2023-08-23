
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
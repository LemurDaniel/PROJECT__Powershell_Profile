
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
        $Clear
    )
    

    $AccountContext = Get-GithubAccountContext -Account $Account
    Clear-SecureStringFromFile -Path "git.pat.$($AccountContext.patRef)"
    
}
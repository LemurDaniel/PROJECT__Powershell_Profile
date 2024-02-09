<#
    .SYNOPSIS
    Get the current github account context.

    .DESCRIPTION
    Get the current github account context.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Current github account context in use.

    .LINK
        
#>
function Get-GithubAccountContext {

    [CmdletBinding(
        DefaultParameterSetName = "Specific"
    )]
    param(
        [Parameter(
            ParameterSetName = "listAvailable"
        )]
        [switch]
        $ListAvailable,

        [Parameter(
            Position = 0,
            Mandatory = $false,
            ParameterSetName = "Specific"
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Read-SecureStringFromFile -Identifier git.accounts.all -AsHashTable).keys
                
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [ValidateScript(
            {
                [System.String]::IsNullOrEmpty( $_) -OR $_ -in (Read-SecureStringFromFile -Identifier git.accounts.all -AsHashTable).keys
            },
            ErrorMessage = 'Not a valid account.'
        )]
        $Account
    )

    if ($ListAvailable) {
        return (Read-SecureStringFromFile -Identifier git.accounts.all -AsHashTable).values
    }

    $oldData = Get-UtilsCache -Identifier context.accounts.all -AsHashtable
    if ($oldData) {
        Save-SecureStringToFile -Identifier git.accounts.all -Object $oldData
        Clear-UtilsCache -Identifier context.accounts.all
    }

    $CurrentAccount = ![System.String]::IsNullOrEmpty($Account) ? $Account : (Get-UtilsCache -Identifier context.accounts.current)
    $Accounts = Read-SecureStringFromFile -Identifier git.accounts.all -AsHashTable
    
    if ($Accounts.Length -EQ 0 ) {
        Write-Host -ForegroundColor red "Create a Account Context First"
        return Add-GithubAccountContext
    }
    elseif ([System.String]::IsNullOrEmpty($CurrentAccount)) {
        Write-Host -ForegroundColor red "   Not Account Context is set."
        Write-Host -ForegroundColor red "   Switched to '$($Accounts.keys[0])'"

        $null = Set-UtilsCache -Identifier context.accounts.current -Object $Accounts.keys[0] -Forever
        return $Accounts.values[0]
    }
    elseif (!$Accounts.containsKey($CurrentAccount)) {
        Write-Host -ForegroundColor red "   '$CurrentAccount' not present anymore."
        Write-Host -ForegroundColor red "   Switched to '$($Accounts.keys[0])'"

        $null = Set-UtilsCache -Identifier context.accounts.current -Object $Accounts.keys[0] -Forever
        return $Accounts.values[0]
    }

    return $Accounts[$CurrentAccount]

}
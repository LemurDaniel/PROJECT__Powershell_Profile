<#
    .SYNOPSIS
    Remove an github account context and its associated pat.

    .DESCRIPTION
    Remove an github account context and its associated pat.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Current github Context in use.

    .LINK
        
#>
function Clear-GithubAccountContext {

    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'high'
    )]
    param(
        [Parameter(
            Mandatory = $false
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
        [ValidateScript(
            {
                [System.String]::IsNullOrEmpty( $_) -OR $_ -in (Get-UtilsCache -Identifier context.accounts.all -AsHashTable).keys
            },
            ErrorMessage = 'Not a valid account.'
        )]
        $Account
    )

    $Accounts = Get-UtilsCache -Identifier context.accounts.all -AsHashTable

    if ($PSCmdlet.ShouldProcess($Account, "Clear")) {
        Clear-GithubPAT -Account $Account -Clear
        $Accounts.Remove($Account)
    }

    return Set-UtilsCache -Identifier context.accounts.all -Object $Accounts -Forever
}
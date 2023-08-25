<#
    .SYNOPSIS
    Update or renamce an existing account context.

    .DESCRIPTION
    Update or renamce an existing account context.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Current github Context in use.

    .LINK
        
#>
function Update-GithubAccountContext {

    param(
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-GithubAccountContext -ListAvailable).name
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [ValidateScript(
            {
                $_ -in (Get-GithubAccountContext -ListAvailable).name
            },
            ErrorMessage = 'Not a valid account.'
        )]
        $Account
    )

    $Accounts = Get-UtilsCache -Identifier context.accounts.all -AsHashTable

    Write-Host -ForegroundColor Magenta "Configure you account context: "
    Write-Host -ForegroundColor Magenta "Leave custom domain empty for github.com!"
    $name = Read-Host -Prompt   '   Account-Context Name'
    if ($name.Length -lt 3) {
        throw "Name must be at least 3 characters."
    }

    $domain = Read-Host -Prompt '   Custom domain'
    $useSSH = Read-Host -Prompt '   clone via SSH [yes/no]'

    $Accounts[$name] = [ordered]@{
        useSSH   = $useSSH.toLower() -eq "yes" ?  $true : $false
        name     = $name
        domain   = ![System.String]::IsNullOrEmpty($domain) ? "$domain/api/v3" : "api.github.com"
        patRef   = $Accounts[$Account].patRef
        cacheRef = $Accounts[$Account].cacheRef
    }

    if ($Account -NE $name) {
        $Accounts.Remove($Account)
    }

    $null = Set-UtilsCache -Identifier context.accounts.all -Object $Accounts -Forever

    return Get-GithubAccountContext -Account $Account
}
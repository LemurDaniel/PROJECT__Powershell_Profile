<#
    .SYNOPSIS
    Add a account context with a pat and custom domain. defaults to api.github.com

    .DESCRIPTION
    Add a account context with a pat and custom domain. defaults to api.github.com
    Path should have access to user and repo.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Current github Context in use.

    .LINK
        
#>
function Add-GithubAccountContext {

    param()

    $Accounts = Read-SecureStringFromFile -Identifier git.accounts.all -AsHashTable

    if ($null -eq $Accounts) {
        $Accounts = [System.Collections.Hashtable]::new()
    }

    # Read-Host -AsSecureString -Prompt 'Please Enter your Personal Git PAT'
    Write-Host -ForegroundColor Magenta "Configure you account context: "
    Write-Host -ForegroundColor Magenta "Leave custom domain empty for github.com!"
    $name = Read-UserInput -Prompt   '   Account-Context Name:' -Minimum 3

    $domain = Read-UserInput -Prompt '   Custom domain:' -Placeholder 'api.github.com'
    $useSSH = Read-UserInput -Prompt '   clone via SSH [yes/no]:'

    $Accounts[$name] = [ordered]@{
        useSSH   = $useSSH.toLower() -eq "yes" ?  $true : $false
        name     = $name
        domain   = $domain -ne 'api.github.com' ? "$domain/api/v3" : "api.github.com"
        patRef   = $Accounts.ContainsKey($name) ? $Accounts[$name].patRef : (new-RandomBytes Hex 16)
        cacheRef = $Accounts.ContainsKey($name) ? $Accounts[$name].cacheRef : (new-RandomBytes Hex 16)
    }

    return Save-SecureStringToFile -Identifier git.accounts.all -Object $Accounts # -Forever
}
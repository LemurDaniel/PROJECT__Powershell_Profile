<#
    .SYNOPSIS
    Add a account context with a pat and custom domain. defaults to api.github.com

    .DESCRIPTION
    Add a account context with a pat and custom domain. defaults to api.github.com

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Current github Context in use.

    .LINK
        
#>
function Add-GithubAccountContext {

    param()

    $Accounts = Get-UtilsCache -Identifier context.accounts.all -AsHashTable

    if ($null -eq $Accounts) {
        $Accounts = [System.Collections.Hashtable]::new()
    }

    # Read-Host -AsSecureString -Prompt 'Please Enter your Personal Git PAT'
    Write-Host -ForegroundColor Magenta "Configure you account context: "
    Write-Host -ForegroundColor Magenta "Leave custom domain empty for github.com!"
    $name = Read-Host -Prompt   '   Account-Context Name'
    $domain = Read-Host -Prompt '   Custom domain'
    $useSSH = Read-Host -Prompt '   clone via SSH [yes/no]'

    $Accounts[$name] = @{
        name     = $name
        domain   = ![System.String]::IsNullOrEmpty($domain) ? "$domain/api/v3" : "api.github.com"
        patRef   = $Accounts.ContainsKey($name) ? $Accounts[$name].patRef : (new-RandomBytes Hex 16)
        cacheRef = $Accounts.ContainsKey($name) ? $Accounts[$name].cacheRef : (new-RandomBytes Hex 16)
        useSSH   = $useSSH.toLower() -eq "yes" ?  $true : $false
    }

    return Set-UtilsCache -Identifier context.accounts.all -Object $Accounts -Forever
}
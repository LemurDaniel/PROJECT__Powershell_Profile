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
        # The name of the github account to use. Defaults to current Account.
        [Parameter(
            Position = 3,
            Mandatory = $false
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Account' })]
        [System.String]
        [Alias('a')]
        $Account
    )

    $Accounts = Read-SecureStringFromFile -Identifier git.accounts.all -AsHashTable

    Write-Host -ForegroundColor Magenta "Configure you account context: "
    Write-Host -ForegroundColor Magenta "Leave custom domain empty for github.com!"
    $name = Read-UserInput -Prompt   '   Account-Context Name:' -Placeholder $Accounts[$Account].name -Minimum 3

    $domain = Read-UserInput -Prompt '   Custom domain:' -Placeholder ($Accounts[$Account].domain -replace '/api/v3', '')
    $useSSH = Read-UserInput -Prompt '   clone via SSH [yes/no]:'
    $signCommit = Read-UserInput -Prompt '   sign commits [yes/no]:'

    $Accounts[$name] = [ordered]@{
        useSSH        = $useSSH.toLower() -eq "yes" ?  $true : $false
        name          = $name
        domain        = $domain -ne 'api.github.com' ? "$domain/api/v3" : "api.github.com"
        commitSigning = $signCommit.toLower() -eq "yes" ?  $true : $false
        patRef        = $Accounts[$Account].patRef
        cacheRef      = $Accounts[$Account].cacheRef
    }

    if ($Account -NE $name) {
        $Accounts.Remove($Account)
    }

    $null = Save-SecureStringToFile -Identifier git.accounts.all -Object $Accounts # -Forever

    return Get-GithubAccountContext -Account $Account
}
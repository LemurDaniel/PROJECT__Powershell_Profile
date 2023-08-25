<#
    .SYNOPSIS
    Add a github account and a PAT associated with it.

    .DESCRIPTION
    Add a github account and a PAT associated with it.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Current github Context in use.

    .LINK
        
#>
function Get-GithubContext {

    param(
        [Parameter(
            Mandatory = $false
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
        [validateScript(
            {
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-GithubAccountContext -ListAvailable).name
            }
        )]
        $Account
    )

    $Context = Get-GithubCache -Identifier git.context -Account $Account

    if ($null -eq $Context) {
        $Context = Switch-GithubContext -Account $Account -Context (Get-GithubUser -Account $Account).login
    }

    return $Context
}
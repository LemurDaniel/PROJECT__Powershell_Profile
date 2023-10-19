<#
    .SYNOPSIS
    Get Github repositories for a context.

    .DESCRIPTION
    Get Github repositories for a context.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Repositories

    
    .LINK
        
#>
function Get-GithubRepositories {

    param(
        [Parameter(
            Position = 1,
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
        $Account,

        # The specific Context to use
        [parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = (Get-GithubContexts -Account $fakeBoundParameters['Account']).login
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [validateScript(
            {
                $_ -in (Get-GithubContexts -Account $PSBoundParameters['Account']).login
            }
        )]
        [System.String]
        $Context,

        [Parameter()]
        [switch]
        $Refresh
    )

    $Cache = Get-GithubCache -Identifier "repositories.$Context" -Account $Account
    if ($null -eq $Cache -OR $Refresh) {
       
        $Account = (Get-GithubAccountContext -Account $Account).name
        if ($Context -eq (Get-GithubUser -Account $Account).login) {
            $Request = @{
                Method      = 'GET'
                API         = '/user/repos'
                affiliation = 'owner'
                visibility  = 'all'
            }
        }
        else {
            $Request = @{
                Method  = 'GET'
                Context = $Context
                API     = '/orgs/{org}/repos'
            }
        }

        $gitRepositories = Invoke-GithubRest @Request -Account $Account
        | Select-Object *, 
        @{
            Name       = 'Account';
            Expression = {
                $Account
            }
        },
        @{
            Name       = 'Context'; 
            Expression = { 
                $_.owner.login 
            }
        },
        @{
            Name       = 'LocalPath';
            Expression = {
                $Context = Get-GithubContexts -Account $Account 
                | Where-Object -Property login -EQ $_.owner.login
                return Join-Path -Path $Context.LocalPath -ChildPath $_.Name
            }
        }

        $Cache = Set-GithubCache -Object ($gitRepositories ?? @{}) -Identifier "repositories.$Context" -Account $Account

    }

    return $Cache
}

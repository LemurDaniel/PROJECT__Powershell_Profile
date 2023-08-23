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
        # The specific Context to use
        [parameter(
            Mandatory = $true
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = (Get-GithubContexts).login
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [validateScript(
            {
                $_ -in (Get-GithubContexts).login
            }
        )]
        [System.String]
        $Context,

        [Parameter()]
        [switch]
        $Refresh
    )

    $Cache = Get-GithubCache -Identifier "repositories.$Context"
    if ($null -eq $Cache -OR $Refresh) {
       
        if ($Context -eq (Get-GithubUser).login) {
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

        $gitRepositories = Invoke-GithubRest @Request 
        | Select-Object *, @{
            Name       = 'Context'; 
            Expression = { 
                $_.owner.login 
            }
        },
        @{
            Name       = 'LocalPath';
            Expression = {
                $Context = Get-GithubContexts | Where-Object -Property login -EQ $_.owner.login
                return Join-Path -Path $Context.LocalPath -ChildPath $_.Name
            }
        }

        $Cache = Set-GithubCache -Object $gitRepositories -Identifier "repositories.$Context"

    }

    return $Cache
}

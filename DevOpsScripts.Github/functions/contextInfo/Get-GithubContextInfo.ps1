<#
    .SYNOPSIS
    Get Information about a Github a Context.

    .DESCRIPTION
    Get Information about a Github a Context.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Information about the Repository.

    .EXAMPLE

    Get Info about the current Context:

    PS> Get-GithubContextInfo

    .EXAMPLE

    Get Info about another Context:

    PS> Get-GithubContextInfo <autocomplete_context>

    .LINK
        
#>

function Get-GithubContextInfo {

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
            Mandatory = $false
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
        #[validateScript(
        #    {
        #        [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-GithubContexts).login
        #    }
        #)]
        [System.String]
        $Context,

        [Parameter()]
        [switch]
        $Refresh
    )

    $Context = [System.String]::IsNullOrEmpty($Context) ? (Get-GithubContext -Account $Account) : $Context

    return Get-GithubContexts -Account $Account -Refresh:$Refresh
    | Where-Object -Property login -EQ $Context
    | Select-Object *, @{
        Name       = 'repositories';
        Expression = {
            Get-GithubRepositories -Account $Account -Context $Context -Refresh:$Refresh
        }
    }

}

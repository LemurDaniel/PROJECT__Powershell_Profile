<#
    .SYNOPSIS
    Get the Useraccount and Organzations connected to login

    .DESCRIPTION
    Get the Useraccount and Organzations connected to login

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    github contexts

    
    .LINK
        
#>

function Get-GithubContexts {

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
        $Account,

        [Parameter()]
        [switch]
        $Refresh
    )

    # Location where to download repositories.
    $basePath = [System.String]::IsNullOrEmpty($env:GIT_RepositoryPath) ? "$env:USERPROFILE\git\repos" : $env:GIT_RepositoryPath

    $Cache = Get-GithubCache -Identifier org.all -Account $Account
    if ($null -eq $Cache -OR $Refresh) {

        $AccountContext = Get-GithubAccountContext -Account $Account

        $gitContexts = @()
        $gitContexts += Get-GithubUser -Refresh:$Refresh -Account $Account
        | Select-Object *, @{
            Name       = 'IsUserContext';
            Expression = { $true }
        },
        @{
            Name       = 'IsOrgContext';
            Expression = { $false }
        }

        $gitContexts += Invoke-GithubRest -Method GET -API 'user/orgs' -Account $Account
        | ForEach-Object { $_ }
        | Select-Object *, @{
            Name       = 'IsUserContext';
            Expression = { $false }
        },
        @{
            Name       = 'IsOrgContext';
            Expression = { $true }
        }

        $gitContexts = $gitContexts | Select-Object *, @{
            Name       = 'LocalPath';
            Expression = {
                "$basePath\GITHUB\$($AccountContext.name)\$($_.login)"
            }
        }
        $gitContexts | ForEach-Object {
            if (!(Test-Path $_.LocalPath)) {
                $null = New-Item -ItemType Directory -Path $_.LocalPath
            }
        }
        $Cache = Set-GithubCache -Object $gitContexts -Identifier org.all -Account $Account
    }

    return $Cache
}

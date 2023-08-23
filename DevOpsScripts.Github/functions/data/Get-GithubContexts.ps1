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
        [Parameter()]
        [switch]
        $Refresh
    )

    # Location where to download repositories.
    $basePath = [System.String]::IsNullOrEmpty($env:GIT_RepositoryPath) ? "$env:USERPROFILE\git\repos" : $env:GIT_RepositoryPath

    $Cache = Get-GithubCache -Identifier org.all
    if ($null -eq $Cache -OR $Refresh) {

        $AccountContext = Get-GithubAccountContext

        $gitContexts = @()
        $gitContexts += Get-GithubUser -Refresh:$Refresh 
        | Select-Object *, @{
            Name       = 'IsUserContext';
            Expression = { $true }
        },
        @{
            Name       = 'IsOrgContext';
            Expression = { $false }
        }

        $gitContexts += Invoke-GithubRest -Method GET -API 'user/orgs'
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
        $Cache = Set-GithubCache -Object $gitContexts -Identifier org.all
    }

    return $Cache
}

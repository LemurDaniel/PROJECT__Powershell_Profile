function Get-GithubContexts {

    param(
        [Parameter()]
        [switch]
        $Refresh
    )

    # Location where to download repositories.
    $basePath = [System.String]::IsNullOrEmpty($env:GIT_RepositoryPath) ? "$env:USERPROFILE\git\repos" : $env:GIT_RepositoryPath

    $Cache = Get-GithubCache -Type Orgs -Identifier all
    if ($null -eq $Cache -OR $Refresh) {

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

        $gitContexts += Invoke-GitRest -Method GET -API 'user/orgs'
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
                "$basePath\__GITHUB\$($_.login)"
            }
        }
        $gitContexts | ForEach-Object {
            if (!(Test-Path $_.LocalPath)) {
                $null = New-Item -ItemType Directory -Path $_.LocalPath
            }
        }
        $Cache = Set-GithubCache -Object $gitContexts -Type Orgs -Identifier all
    }

    return $Cache
}

function Get-GithubData {

    param(
        [Parameter()]
        [System.String]
        $Property,

        [Parameter()]
        [switch]
        $Refresh
    )

    $userName = Get-GitUser | Get-Property login
    $Cache = Get-UtilsCache -Type Github -Identifier $userName

    if ($Cache -AND !$Refresh) {
        return Get-Property -Object $Cache -Property $Property
    }

    $repositories = Invoke-GitRest -Method GET -API 'user/repos'
    $githubData = @{
        owners       = $repositories.owner | Get-Unique -AsString
        repositories = $repositories | `
            Select-Object -Property @{
            Name = 'login'; 
            Expression = { 
                $_.owner.login 
            }
        },@{
            Name = 'LocalPath';
            Expression = {
                "$([System.String]::IsNullOrEmpty($env:GIT_RepositoryPath) ? "$env:USERPROFILE\git\repos" : $env:GIT_RepositoryPath)\$($_.owner.login)\$($_.name)"
            }
        }, id, permissions, default_branch, name, full_name, description, private, visibility, html_url, url, clone_url, created_at, updated_at, pushed_at
    }

    $null = Set-UtilsCache -Object $githubData -Type Github -Identifier $userName
    return Get-Property -Object $githubData -Property $Property
}

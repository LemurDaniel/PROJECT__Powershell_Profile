function Get-GithubData {

    param(
        [Parameter()]
        [System.String]
        $Property,

        [Parameter()]
        [switch]
        $Refresh
    )

    $Cache = Get-UtilsCache -Type Github -Identifier 'data'

    if ($Cache -AND !$Refresh) {
        return Get-Property -Object $Cache -Property $Property
    }

    $repositories = Invoke-GitRest -Method GET -apiEndpoint repos
    $githubData = @{
        owners       = $repositories.owner | Get-Unique -AsString
        repositories = $repositories | `
            Select-Object -Property @{
            Name = 'login'; Expression = { $_.owner.login }
        }, id, permissions, default_branch, name, full_name, description, private, visibility, html_url, url, clone_url, created_at, updated_at, pushed_at
    }

    $null = Set-UtilsCache -Object $githubData -Type Github -Identifier 'data'
    return Get-Property -Object $githubData -Property $Property
}

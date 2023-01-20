function Get-AllRepositories {

    param()

    $repositories = Invoke-GitRest -Method GET -apiEndpoint repos

    $githubData = @{
        owners       = $repositories.owner | Get-Unique -AsString
        repositories = $repositories | `
            Select-Object -Property @{
            Name = 'login'; Expression = { $_.owner.login }
        }, id, permissions, default_branch, name, full_name, description, private, visibility, html_url, url, clone_url, created_at, updated_at, pushed_at
    }

    return Set-UtilsCache -Object $githubData -Type Github -Identifier 'data'
}
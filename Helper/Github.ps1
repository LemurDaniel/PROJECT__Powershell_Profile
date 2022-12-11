

function Invoke-ApiGit {

    param(
        [parameter(Mandatory = $true)]
        [validateSet([HTTPMethods])]
        $Method,

        [parameter()]
        [validateSet('user', 'users', 'org', 'orgs', 'organizations', 'issues', 'hub', 'events', 'search')]
        $apiGroup = 'user',

        [parameter()]
        [System.String]
        $apiEndpoint,

        [parameter()]
        [System.String]
        $contentType = 'application/vnd.github+json',

        [parameter()]
        [System.String]
        $apiVersion = '2022-11-28',


        [parameter()]
        [validateSet('all', 'public', 'private')]
        $visibility = 'all'
    )

    $queryParams = @{
        affiliation = 'owner,collaborator'  #'owner,collaborator,organization_member'
        visibility  = $visibility
        per_page    = 100
    }

    $queryString = ''
    foreach($param in $queryParams.Keys) {
        $queryString += '&' + $param + '=' + $queryParams[$param]
    }

    $joinedPath = (Join-Path -Path $apiGroup -ChildPath $apiEndpoint).replace('\', '/')
    $joinedPath = $joinedPath[-1] -eq '/' ? $joinedPath.Substring(0, $joinedPath.length - 2) : $joinedPath
    $Request = @{
        Method = $Method
        header = @{
            Accept                 = $contentType
            'X-GitHub-Api-Version' = $apiVersion
            Authorization          = "Bearer $env:GIT_PAT"
        }
        uri    = 'https://api.github.com/' + $joinedPath + '?' + $queryString.Substring(1)
    }

    Invoke-RestMethod @Request
}


function Get-AllRepositories {

    param()

    $repositories = Invoke-ApiGit -Method GET -apiEndpoint repos

    $githubData = @{
        owners = $repositories.owner | Get-Unique -AsString
        repositories = $repositories | `
            Select-Object -Property @{Name='login'; Expression={$_.owner.login}}, id, permissions, default_branch, name, full_name, description, private, visibility, html_url, url, clone_url, created_at, updated_at, pushed_at
    }

    
    #$repositories | `
     #Select-Object -Property @{Name='login'; Expression={$_.owner.login}}, id, permissions, default_branch, name, full_name, description, private, visibility, html_url, url, clone_url, created_at, updated_at, pushed_at| `
     #'Group-Object -Property 'login' | `
     #ForEach-Object { $repositoryOwners[$_.Name] | Add-Member -MemberType NoteProperty -Name 'Repositories' -Value ($_.Group) -Force }

    Update-SecretStore PERSONAL -SecretPath CACHE.GITHUB -SecretValue $githubData

}
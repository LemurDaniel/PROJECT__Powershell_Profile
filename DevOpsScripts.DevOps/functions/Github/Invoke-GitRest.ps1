function Invoke-GitRest {

    param(
        [parameter(Mandatory = $true)]
        [Microsoft.PowerShell.Commands.WebRequestMethod]
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

    $Query = @{
        affiliation = 'owner,collaborator'  #'owner,collaborator,organization_member'
        visibility  = $visibility
        per_page    = 100
    }

    $Query = $null -ne $Query ? $Query : [System.Collections.Hashtable]::new()
    $QueryString = ($Query.GetEnumerator() | `
            ForEach-Object { "$($_.Name)=$($_.Value)" }) -join '&'


    $Request = @{
        Method = $Method
        header = @{
            Accept                 = $contentType
            'X-GitHub-Api-Version' = $apiVersion
            Authorization          = "Bearer $env:GIT_PAT"
        }
        uri    = "https://api.github.com/$apiGroup/$apiEndpoint`?$QueryString"
    }

    Invoke-RestMethod @Request
}
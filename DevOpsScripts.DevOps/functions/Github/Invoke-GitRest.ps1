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

    $GIT_PATH = Read-SecureStringFromFile -Identifier GitPersonalPAT -AsPlainText
    $GIT_PATH = [System.String]::isNullOrEmpty($env:GIT_PAT) ? $GIT_PATH : $env:GIT_PAT

    if ([System.String]::isNullOrEmpty($GIT_PATH)) {
        $GIT_PATH = Read-Host -AsSecureString -Prompt 'Please Enter your Personal Git PAT'
        Save-SecureStringToFile -SecureString $GIT_PATH -Identifier GitPersonalPAT
        $GIT_PATH = $GIT_PATH | ConvertFrom-SecureString -AsPlainText
    }

    $Request = @{
        Method = $Method
        header = @{
            Accept                 = $contentType
            'X-GitHub-Api-Version' = $apiVersion
            Authorization          = "Bearer $GIT_PATH"
        }
        uri    = "https://api.github.com/$apiGroup/$apiEndpoint`?$QueryString"
    }

    Invoke-RestMethod @Request
}

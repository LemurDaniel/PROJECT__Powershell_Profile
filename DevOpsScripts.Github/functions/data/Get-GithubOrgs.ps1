function Get-GithubOrgs {

    param(
        [Parameter()]
        [switch]
        $Refresh
    )

    $Cache = Get-GithubCache -Type Orgs -Identifier all
    if ($null -eq $Cache -OR $Refresh) {
       
        $gitOrgs = @()
        $gitOrgs += Get-GithubUser -Refresh:$Refresh
        $gitOrgs += Invoke-GitRest -Method GET -API 'user/orgs'

        $Cache = Set-GithubCache -Object $gitOrgs -Type Orgs -Identifier all

    }

    return $Cache
}

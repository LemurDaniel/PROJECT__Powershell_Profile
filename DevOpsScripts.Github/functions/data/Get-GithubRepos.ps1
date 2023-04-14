function Get-GithubRepos {

    param(
        [Parameter()]
        [switch]
        $Refresh
    )

    $CurrentContext = (Get-GithubOrgs)[0] # TODO
    $Cache = Get-GithubCache -Type repositories -Identifier $CurrentContext.login
    if ($null -eq $Cache -OR $Refresh) {
       
        if ($CurrentContext.login -eq (Get-GithubUser).login) {
            $Request = @{
                Method      = 'GET'
                API         = '/user/repos'
                affiliation = 'owner'
                visibility  = 'all'
            }
        }
        else {
            $Request = @{
                Method       = 'GET'
                Organization = $CurrentContext.login
                API          = '/orgs/{org}/repos'
            }
        }

        $response = Invoke-GitRest @Request

        $Cache = Set-GithubCache -Object $response -Type repositories -Identifier $CurrentContext.login

    }

    return $Cache
}

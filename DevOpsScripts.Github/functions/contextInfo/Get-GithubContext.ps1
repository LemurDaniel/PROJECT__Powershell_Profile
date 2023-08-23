<#
    .SYNOPSIS
    Add a github account and a PAT associated with it.

    .DESCRIPTION
    Add a github account and a PAT associated with it.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Current github Context in use.

    .LINK
        
#>
function Get-GithubAccount {

    param()

    $Context = Get-GithubCache -Identifier git.context 
    if ($null -eq $Context) {
        $Context = Switch-GithubContext -Context (Get-GithubUser).login
    }

    return $Context
}
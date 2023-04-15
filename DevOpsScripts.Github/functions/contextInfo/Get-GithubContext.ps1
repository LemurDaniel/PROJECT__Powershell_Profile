<#
    .SYNOPSIS
    Get Information about a Repository in a Context.

    .DESCRIPTION
    Get Information about a Repository in a Context.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Current github Context in use.

    .LINK
        
#>
function Get-GithubContext {

    param()

    $Context = Get-UtilsCache -Type Context -Identifier git
    if ($null -eq $Context) {
        $Context = Switch-GithubContext -Context (Get-GithubUser).login
    }

    return $Context
}
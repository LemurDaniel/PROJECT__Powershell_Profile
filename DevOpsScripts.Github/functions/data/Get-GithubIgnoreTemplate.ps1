<#
    .SYNOPSIS
    Gets a list of all .gitignore templates on github.

    .DESCRIPTION
    Gets a list of all .gitignore templates on github.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None

    .LINK
        
#>

function Get-GithubIgnoreTemplate {

    [CmdletBinding()]
    param (
        # The name of the .gitignore-Template. Lists all, if not specified.
        [Parameter(
            Position = 0,
            Mandatory = $false
        )] 
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Gitignore' })]
        [System.String]
        [Alias('Name')]
        $Gitignore
    )

    $data = Get-GithubCache -Identifier "gitignore.$Gitignore"

    if ($null -EQ $data -OR $Refresh) {
        if ([System.String]::IsNullOrEmpty($Gitignore)) {
            $data = Invoke-GithubRest -URL "https://api.github.com/gitignore/templates"
        }
        else {
            $data = Invoke-GithubRest -URL "https://api.github.com/gitignore/templates/$Gitignore"
        }
        $data = Set-GithubCache -Object $data -Identifier "gitignore.$Gitignore"
    }

    return $data
}
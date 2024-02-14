<#
    .SYNOPSIS
    Gets a list of all .gitignore templates on Git.

    .DESCRIPTION
    Gets a list of all .gitignore templates on Git.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None

    .LINK
        
#>

function Get-GitIgnoreTemplate {

    [CmdletBinding()]
    param (
        # The name of the .gitignore-Template. Lists all, if not specified.
        [Parameter(
            Position = 0,
            Mandatory = $false
        )] 
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Gitignore' })]
        [System.String]
        [Alias('Name')]
        $Gitignore
    )

    $data = Get-GitCache -Identifier "gitignore.$Gitignore"

    if ($null -EQ $data -OR $Refresh) {
        if ([System.String]::IsNullOrEmpty($Gitignore)) {
            $data = Invoke-GitRest -URL "https://api.Github.com/gitignore/templates"
        }
        else {
            $data = Invoke-GitRest -URL "https://api.Github.com/gitignore/templates/$Gitignore"
        }
        $data = Set-GitCache -Object $data -Identifier "gitignore.$Gitignore"
    }

    return $data
}
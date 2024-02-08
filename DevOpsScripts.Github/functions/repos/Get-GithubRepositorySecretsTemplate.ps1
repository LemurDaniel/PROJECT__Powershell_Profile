<#
    .SYNOPSIS
    Gets an encrypted template for secrets to deploy on a repository.

    .DESCRIPTION
    Get an encrypted template for secrets to deploy on a repository.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None

    .LINK
#>

function Get-GithubRepositorySecretsTemplate {

    [CmdletBinding(
        DefaultParameterSetName = "specfic"
    )]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = "specfic"
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = Get-GithubRepositorySecretsTemplate -ListAvailable
                
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [validateScript(
            {
                $_ -in (Get-GithubRepositorySecretsTemplate -ListAvailable)
            }
        )]
        [System.String]
        $Name,

        # Retrives as Plain text rather than a secure string.
        [Parameter(
            ParameterSetName = "specfic"
        )]
        [switch]
        $AsPlainText,

        # List all encrypted template files.
        [Parameter(
            ParameterSetName = "ListAvailable"
        )]
        [switch]
        $ListAvailable
    )

    $templates = Get-UtilsConfiguration -Identifier "github.secrets_templates.all" -AsHashtable
    if ($null -EQ $templates) {
        $templates = [System.Collections.Hashtable]::new()
    }

    if ($ListAvailable) {
        return $templates.Keys
    }
    elseif ($PSBoundParameters.ContainsKey('Name')) {
        return Read-SecureStringFromFile -Identifier "github.$($templates[$Name])" -AsPlainText:$AsPlainText
    }

}

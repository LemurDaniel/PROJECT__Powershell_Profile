
<#
    .SYNOPSIS
    Retrieves the openAI API-Key used for the Requests.

    .DESCRIPTION
    Retrieves the openAI API-Key used for the Requests.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS
    An unencrypted object or string.


    .LINK
        
#>

function Get-OpenAIAPIAuthentication {

    [CmdletBinding()]
    param (
        # Switch to delete current api key.
        [Parameter()]
        [switch]
        $delete
    )

    if (![System.String]::isNullOrEmpty($env:OPEN_AI_API_KEY)) {
        return @{
            OpenAIapiKey   = $env:OPEN_AI_API_KEY
            OpenAIapiOrgId = $env:OPEN_AI_ORD_ID
        }
    }

    $OpenAIapiKey = Read-SecureStringFromFile -Identifier OpenAIapiKey
    $OpenAIapiOrgId = Read-SecureStringFromFile -Identifier OpenAIapiOrgId

    if ($delete -OR $null -eq $OpenAIapiKey) {

        $OpenAIapiKey = Read-Host -AsSecureString -Prompt 'Please Enter your OpenAI API Token'
        $OpenAIapiOrgId = Read-Host -AsSecureString -Prompt 'Please Enter the Organization ID (Leave Empty if not applicaple)'
 

        Save-SecureStringToFile -SecureString $OpenAIapiKey -Identifier OpenAIapiKey
        if ($OpenAIapiOrgId.Length -gt 0) {
            Save-SecureStringToFile -SecureString $OpenAIapiOrgId -Identifier OpenAIapiOrgId
        }
    }

    return @{
        OpenAIapiKey   = $OpenAIapiKey | ConvertFrom-SecureString -AsPlainText
        OpenAIapiOrgId = $null -ne $OpenAIapiOrgId -AND $OpenAIapiOrgId.Length -gt 0 ? ($OpenAIapiOrgId | ConvertFrom-SecureString -AsPlainText) : $null
    }

}

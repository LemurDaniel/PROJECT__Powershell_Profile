<#
    .SYNOPSIS
    Call Fresh Service API for Ticket-System Integration.

    .DESCRIPTION
     Call Fresh Service API for Ticket-System Integration.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    return the API-Response.

        
#>
function Invoke-FreshApi {

    [CmdletBinding()]
    param (
        # The Rest-Method to use.
        [Parameter(Mandatory = $true)]
        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $METHOD,

        [Parameter(
            Mandatory = $true
        )]
        [ValidateSet('tickets', 'groups', 'agents')]
        [System.String]
        $ApiEndpoint,

        [Parameter()]
        [System.String]
        $ApiResource = '',

        [Parameter()]
        [PSCustomObject]
        $Body,

        [Parameter()]
        [System.String]
        $FullUrl
    )


    $FreshApiHost = Read-SecureStringFromFile -Identifier FreshApiHost -AsPlainText
    $FreshApiKey = Read-SecureStringFromFile -Identifier FreshApiKey -AsPlainText

    if ([System.String]::isNullOrEmpty($FreshApiHost) -OR [System.String]::isNullOrEmpty($FreshApiKey)) {
        $FreshApiHost = Read-Host -AsSecureString -Prompt 'Please Enter the Fresh Api Host'
        $FreshApiKey = Read-Host -AsSecureString -Prompt 'Please Enter your Fresh Api Key'
        Save-SecureStringToFile -SecureString $FreshApiHost -Identifier FreshApiHost
        Save-SecureStringToFile -SecureString $FreshApiKey -Identifier FreshApiKey
        $FreshApiKey = $FreshApiKey | ConvertFrom-SecureString -AsPlainText
        $FreshApiHost = $FreshApiHost | ConvertFrom-SecureString -AsPlainText
    }

    $apiKey = [Convert]::ToBase64String(([System.Text.Encoding]::UTF8).GetBytes("$FreshApiKey`:X"))

    $RequestParams = @{
        Uri         = $PSBoundParameters.ContainsKey('FullUrl') ? $FullUrl : ("$FreshApiHost/$ApiEndpoint/$ApiResource".Replace('\', '/'))
        Method      = $Method
        Headers     = @{
            'Authorization' = "Basic $apiKey"
        }
        ContentType = 'application/json; charset=utf-8'
        Body        = $Body | ConvertTo-Json -Compress
    }
    
    try {
        Write-Host ($RequestParams | ConvertTo-Json)
        return Invoke-RestMethod @RequestParams -Verbose
    }
    catch {
        $_
        throw $_
    }

}
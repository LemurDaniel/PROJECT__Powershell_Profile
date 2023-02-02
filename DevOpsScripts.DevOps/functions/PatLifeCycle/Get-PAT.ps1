
<#
    .SYNOPSIS
    Retrieves an PAT-Token with an ID and a scope. If as same token has been created and not expired, will return it again.

    .DESCRIPTION
    Retrieves an PAT-Token with an ID and a scope. If as same token has been created and not expired, will return it again.
    The token ist saved securly on the disk with SercureString using the underlying Windows Data Protection API.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Username and Pat as a Credential-Object.


    .EXAMPLE

    Get a new or token saved on the disk for 'baugruppe' to read Artifact-Feeds and provide a custom path where to search/save the Pat:

    Get-PAT -Organization 'baugruppe' -patScope vso.Packaging -path ./creds


    .LINK
        
#>

function Get-PAT {
    param (
        # The Organozation in which the PAT shoul be created. Defaults to current Context.
        [Parameter()]
        [System.String]
        $Organization,

        # A list of permission scopes for the PAT.
        [Parameter()]
        [System.String[]]
        $patScopes = @(),

       # How many Hours the generated PAT will be valid.
        [Parameter()]
        [System.Int32]
        $HoursValid = 1,

        # An optional custom path to determine where to save/search existing PATs
        [Parameter()]
        [System.String]
        $Path = "$PSScriptRoot/.local"
    )


    if(!(Test-Path -Path $path)){
        $null = New-Item -ItemType Directory -Path $path
    }

    $bytes = [System.Text.Encoding]::GetEncoding('UTF-8').GetBytes($patScopes) 
    $hex = [System.Convert]::ToHexString($bytes)

    $Organization = [System.String]::IsNullOrEmpty($Organization) ? (Get-DevOpsCurrentContext -Organization) : $Organization
    $localPat = Read-SecureStringFromFile -Identifier "$hex.$Organization.pat" -AsPlainText -Path $Path | ConvertFrom-Json

    if ($null -eq $localPat -OR $localPat.validTo -lt [DateTime]::now) {
        $localPat = New-PAT -Organization $Organization -patScopes $patScopes -HoursValid $HoursValid | `
            Select-Object -Property displayName, validTo, scope, authorizationId, @{
                Name = 'pass';
                Expression = {
                    $_.token | ConvertTo-SecureString -AsPlainText | ConvertFrom-SecureString
                }
            }, @{
                Name = 'user';
                Expression = {
                    (Get-AzContext).Account.id
                }
            }

        Save-SecureStringToFile -PlainText ($localPat | ConvertTo-Json -Compress) -Identifier "$hex.$Organization.pat" -Path $Path
    }

    $localPat.pass = $localPat.pass | ConvertTo-SecureString
    return New-Object System.Management.Automation.PSCredential($localPat.user, $localPat.pass)
}

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
        # The optional Name of the retrieved or newly created pat.
        [Parameter(
          Mandatory = $false
        )]
        [System.String]
        $Name = "",

        # The Organozation in which the PAT shoul be created. Defaults to current Context.
        [Parameter(
          Mandatory = $true
        )]
        [System.String]
        $Organization,

        # A list of permission scopes for the PAT.
        [Parameter(
          Mandatory = $true
        )]
        [System.String[]]
        $PatScopes,

        # How many Hours the generated PAT will be valid.
        [Parameter()]
        [System.Int32]
        $HoursValid = 1,

        # An optional custom path to determine where to save/search existing PATs
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Path,

        # Optional Parameter to return null if not PAT is found or expired, instead of creating a new one.
        [Parameter()]
        [switch]
        $OnlyRead
    )

    $Path = [System.String]::IsNullOrEmpty($Path) ? "$PSScriptRoot/.local" : $Path

    if(!(Test-Path -Path $Path)){
        $null = New-Item -ItemType Directory -Path $Path
    }

    $bytes = [System.Text.Encoding]::GetEncoding('UTF-8').GetBytes(@(
        ($PatScopes | Sort-Object | ForEach-Object { $_ }), $name, $Organization
    )) 
    $identifier = [System.Convert]::ToHexString($bytes)
    
    $localPat = Read-SecureStringFromFile -Identifier "$identifier.pat" -AsPlainText -Path $Path | ConvertFrom-Json

    if ($null -eq $localPat -OR $localPat.validTo -lt [DateTime]::now.ToUniversalTime()) {

        if($OnlyRead){
            return $null
        }

        Write-Verbose 'Generating new PAT'

        $localPat = New-PAT -Name $Name -Organization $Organization -PatScopes $PatScopes -HoursValid $HoursValid | `
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

        Save-SecureStringToFile -PlainText ($localPat | ConvertTo-Json -Compress) -Identifier "$identifier.pat" -Path $Path
    }

    $localPat.pass = $localPat.pass | ConvertTo-SecureString
    return [System.Management.Automation.PSCredential]::new($localPat.user, $localPat.pass)
}
<#
    .SYNOPSIS
    Gets a list of all current terraform versions.

    .DESCRIPTION
    Gets a list of all current terraform versions.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    List of terraform versions

    
    .LINK
        
#>


function Get-TerraformVersions {
    param(
        # Include alpha and beta versions
        [Parameter()]
        [switch]
        $Alphas
    ) 


    $Source = 'https://releases.hashicorp.com/terraform'
    $Matcher = $Alphas ?   "^[\d\S]*$" : "^[\d\.]*$"

    $data = Get-UtilsCache -Identifier terraform.versions
    if (!$data) {
        $data = Invoke-WebRequest -Uri $Source 
        | Select-Object -ExpandProperty Links
        | Where-Object -Property href -match "^/terraform/[\d\S]*/$" 
        | Select-Object @{
            Name       = 'Version';
            Expression = { 
            ($_.href -replace 'terraform' -replace '/', '')
            }
        }
        | Select-Object *, @{
            Name       = 'windows_amd64';
            Expression = {
                "$Source/$($_.Version)/terraform_$($_.Version)_windows_amd64.zip"
            }
        }

        $data = Set-UtilsCache -Object $versions -Identifier terraform.versions -Alive 10
    }

    return $data | Where-Object -Property version -match $Matcher
}

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
    param() {}

    $Source = 'https://releases.hashicorp.com/terraform'

    return Invoke-WebRequest -Uri $Source
    | Select-Object -ExpandProperty Links
    | Where-Object -Property href -match "^/terraform/[\d\.]*/$"
    | Select-Object @{
        Name       = 'Version';
        Expression = { 
            [System.Version]::Parse(($_.href -replace 'terraform' -replace '/', '')) 
        }
    }
    | Select-Object *, @{
        Name       = 'windows_amd64';
        Expression = {
            "$Source/$($_.Version)/terraform_$($_.Version)_windows_amd64.zip"
        }
    }
}

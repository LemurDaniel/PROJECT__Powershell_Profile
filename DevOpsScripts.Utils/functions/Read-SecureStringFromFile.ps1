<#
    .SYNOPSIS
    Reads a Secure String encrypted by the Windows Data Protection API from a File.

    .DESCRIPTION
    Reads a Secure String encrypted by the Windows Data Protection API from a File.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS
    The Secure String from the File.

    .LINK
        
#>
function Read-SecureStringFromFile {

    [CmdletBinding()]
    param (
        # An identifier for the data.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Identifier,

        # A switch to return the data as an unencrypted string.
        [Parameter(Mandatory = $false)]
        [switch]
        $AsPlainText
    )

    $filename = ".$Identifier.secure" | Get-CleanFilename
    $filePath = Join-Path -Path "$env:USERPROFILE/.devopsscripts/" -ChildPath $filename
    $Content = Get-Content -Path $filePath -ErrorAction SilentlyContinue | ConvertTo-SecureString -ErrorAction SilentlyContinue 
    if ($Content -AND $AsPlainText) {
        return $Content | ConvertFrom-SecureString -AsPlainText
    }
    else {
        return $Content
    }
     
}
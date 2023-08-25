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

    src: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.security/convertfrom-securestring?view=powershell-7.3#description

    If an encryption key is specified by using the Key or SecureKey parameters, the Advanced Encryption Standard (AES) encryption algorithm is used. 
    The specified key must have a length of 128, 192, or 256 bits because those are the key lengths supported by the AES encryption algorithm. 
    If no key is specified, the Windows Data Protection API (DPAPI) is used to encrypt the standard string representation.
        
#>
function Read-SecureStringFromFile {

    [CmdletBinding(
        DefaultParameterSetName = "SecureString"
    )]
    param (
        # An identifier for the data.
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $Identifier,
    
        # A switch to return the data as an secure string.
        [Parameter(
            Mandatory = $false,
            ParameterSetName = "SecureString"
        )]
        [switch]
        $AsSecureString,

        # A switch to return the data as an unencrypted string.
        [Parameter(
            Mandatory = $false,
            ParameterSetName = "PlainText"
        )]
        [switch]
        $AsPlainText,

        # A switch to return the data as a hastable.Will fail if saved data is not a valid json.
        [Parameter(
            Mandatory = $false,
            ParameterSetName = "Hashtable"
        )]
        [switch]
        $AsHashtable,

        # A switch to return the data as a object. Will fail if saved data is not a valid json.
        [Alias('AsJSON')]
        [Parameter(
            Mandatory = $false,
            ParameterSetName = "Object"
        )]
        [switch]
        $AsObject,

        # Path to specify where to save the file. If not specified defaults to userProfile
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Path
    )

    $directory = [System.String]::IsNullOrEmpty($Path) ? "$env:USERPROFILE/.secure_devopsscripts/" : $Path
    $filename = ".$Identifier.secure" | Get-CleanFilename
    $filePath = Join-Path -Path $directory -ChildPath $filename


    $Content = Get-Content -Path $filePath -ErrorAction SilentlyContinue | ConvertTo-SecureString -ErrorAction SilentlyContinue 
    
    if ($Content -AND $AsObject) {
        return $Content | ConvertFrom-SecureString -AsPlainText | ConvertFrom-Json
    }
    if ($Content -AND $AsHashtable) {
        return $Content | ConvertFrom-SecureString -AsPlainText | ConvertFrom-Json -AsHashtable
    }
    elseif ($Content -AND $AsPlainText) {
        return $Content | ConvertFrom-SecureString -AsPlainText
    }
    else {
        return $Content
    }
     
}
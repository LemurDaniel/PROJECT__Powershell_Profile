
<#
    .SYNOPSIS
    Save a Plaintext or Secure String encrypted by the Windows Data Protection API to a File.

    .DESCRIPTION
    Save a Plaintext or Secure String encrypted by the Windows Data Protection API to a File.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS
    None

    .LINK

    src: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.security/convertfrom-securestring?view=powershell-7.3#description

    If an encryption key is specified by using the Key or SecureKey parameters, the Advanced Encryption Standard (AES) encryption algorithm is used. 
    The specified key must have a length of 128, 192, or 256 bits because those are the key lengths supported by the AES encryption algorithm. 
    If no key is specified, the Windows Data Protection API (DPAPI) is used to encrypt the standard string representation.
        
#>
function Save-SecureStringToFile {

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Plaintext'
        )]
        [System.String]
        $PlainText,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'SecureString'
        )]
        [System.Security.SecureString]
        $SecureString,

        # An identifier for the data.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Identifier,

        # Path to specify where to save the file. If not specified defaults to userProfile
        [Parameter(Mandatory = $false)]
        [System.String]
        $Path
    )

    $directory = [System.String]::IsNullOrEmpty($Path) ? "$env:USERPROFILE/.secure_devopsscripts/" : $Path
    $filename = ".$Identifier.secure" | Get-CleanFilename
    $filePath = Join-Path -Path $directory -ChildPath $filename

    if (!(Test-Path -Path $directory)) {
        $null = New-Item -ItemType Directory -Path $directory
    }


    if (![System.String]::isNullOrEmpty($PlainText)) {
        $PlainText | ConvertTo-SecureString -AsPlainText | ConvertFrom-SecureString | Out-File $filePath
    }
    else {
        $SecureString | ConvertFrom-SecureString | Out-File -FilePath $filePath
    }

}
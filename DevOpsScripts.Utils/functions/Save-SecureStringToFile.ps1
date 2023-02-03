
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

    $Path = [System.String]::IsNullOrEmpty($Path) ? $env:USERPROFILE : $Path
    $directory = "$Path/.secure_devopsscripts/"
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
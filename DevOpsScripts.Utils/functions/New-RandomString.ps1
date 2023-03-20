<#
    .SYNOPSIS
    Creates a random byte array as specifed.

    .DESCRIPTION
    Creates a random byte array as specifed.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS
    The plain random byte array or a hex, base64 conversion.

    .EXAMPLE

    Create a random base64-String from a 8-Byte-Array:

    PS> New-RandomBytes Base64 8

#>

function New-RandomBytes {

    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0
        )]
        [ValidateSet('ByteArray', 'Hex', 'Base64')]
        [System.String]
        $Type = 'Hex',

        [Parameter(
            Position = 1
        )]
        [System.int32]
        $Bytes = 2
    )

    [System.Byte[]]$byteArray = 1..$Bytes | ForEach-Object { Get-Random -Max 255 }

    switch ($Type) {
        
        Hex {
            return [System.Convert]::ToHexString($byteArray)
        }
        Base64 {
            return [System.Convert]::ToBase64String($byteArray)
        }
        ByteArray {
            return $byteArray
        }

        default {
            throw 'Type Not Supported!'
        }
    }
}
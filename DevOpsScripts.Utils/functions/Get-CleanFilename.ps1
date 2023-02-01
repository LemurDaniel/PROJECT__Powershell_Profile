<#
    .SYNOPSIS
    Replaces any invalid characters in a Filename.

    .DESCRIPTION
    Replaces any invalid characters in a Filename.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS
    The cleaned filename.

    .LINK
        
#>
function Get-CleanFilename {

    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [System.String]
        $Filename
    )

    BEGIN {
        $invalidChars = [IO.Path]::GetInvalidFileNameChars() -join ''
        $regex = [System.String]::Format('[{0}]', [regex]::Escape( $invalidChars))
    }
    PROCESS {
        [regex]::Replace($Filename, $regex, '_')
    }
    END {}
}
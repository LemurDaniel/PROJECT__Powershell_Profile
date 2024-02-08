
<#
    .SYNOPSIS
    Get a chache by a type and a specified identifier.

    .DESCRIPTION
    Get a chache by a type and a specified identifier.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Returns the Property or Array of Properties if found.

    .LINK
        
#>
function Get-UtilsConfiguration {

    [CmdletBinding()]
    param (
        # The type of the cache.
        [Parameter(Mandatory = $false)]
        [System.String]
        $Type,

        # An identifier for the cache.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Identifier,

        # Return the cache as a hashtable.
        [Parameter()]
        [Switch]
        $AsHashtable,

        [Parameter(Mandatory = $false)]
        [System.String]
        $Path
    )

    try {
        $CacheFolderPath = Get-UtilsCachePath -Path $Path -Source "Configurationdata"
        $filename = ($($type, $Identifier, "json") | Where-Object { $_ }) -join '.' | Get-CleanFilename
        $CacheFilePath = Join-Path -Path $CacheFolderPath -ChildPath  $filename.toLower()

        Write-Verbose $CacheFilePath

        return Get-Content $CacheFilePath 
        | ConvertFrom-Json -AsHashtable:$AsHashtable     
        | Select-Object -ExpandProperty Content
    }
    catch {
        return $null
    }

}
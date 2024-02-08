
<#
    .SYNOPSIS
    Clear cache file at identifier.

    .DESCRIPTION
    Clear cache file at identifier.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS

    
    .LINK
        
#>
function Clear-UtilsCache {

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

        [Parameter(Mandatory = $false)]
        [System.String]
        $Path
    )

    try {
        $CacheFolderPath = Get-UtilsCachePath -Path $Path -Source "Utilscache"
        $filename = ($($type, $Identifier, "json") | Where-Object { $_ }) -join '.' | Get-CleanFilename
        $CacheFilePath = Join-Path -Path $CacheFolderPath -ChildPath  $filename.toLower()

        Write-Verbose $CacheFilePath

        Remove-Item -Path $CacheFilePath  
    }
    catch {
        return $null
    }

}


<#
    .SYNOPSIS
    Set a chache by a type and a specified identifier.

    .DESCRIPTION
    Set a chache by a type and a specified identifier.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Return the cached object.


    .EXAMPLE

    Cache a value for 3 Minutes:

    PS> Get-UtilsCache -object $value -Type value -Identifier current -Alive 3

        .EXAMPLE

    Cache the all pim-profiles forever:

    PS> Get-UtilsCache -Object $profiles -Type PIM_Profiles -Identifier all -Forever
    
    .LINK
        
#>
function Set-UtilsCache {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [PSCustomObject]
        $Object = @{},

        [Parameter(Mandatory = $true)]
        [System.String]
        $Type,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Identifier,

        [Parameter(Mandatory = $false)]
        [System.Int32]
        $Alive = 720,

        [Parameter(Mandatory = $false)]
        [Switch]
        $Forever,

        [Parameter(Mandatory = $false)]
        [System.String]
        $Path
    )

    $CacheFolderPath = ![System.String]::IsNullOrEmpty($Path) ? $Path : $env:UTILS_CACHE_PATH ?? "$([System.IO.Path]::GetTempPath())/.cache/"
    $CacheFilePath = Join-Path -Path $CacheFolderPath -ChildPath (".$Type.$Identifier.json".toLower() -replace '[\/\\\s]+', '_') 
    
    if (-not (Test-Path -Path $CacheFolderPath)) {
        $null = New-Item -Path $CacheFolderPath -ItemType Directory -Force
    }
    
    $Alive = $Forever ? [System.Int32]::MaxValue : $Alive
    @{
        Date    = ([DateTime]::Now).AddMinutes($Alive)
        Content = $Object
    } | ConvertTo-Json -Depth 16 | Out-File -Path $CacheFilePath
   
    return $Object

}
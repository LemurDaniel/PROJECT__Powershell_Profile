

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

    [CmdletBinding( )]
    param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true
        )]
        [PSCustomObject]
        $Object = @{},

        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Type,

        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $Identifier,

        [Parameter(
            Mandatory = $false
        )]
        [System.Int32]
        $Alive = 720,

        [Parameter(
            Mandatory = $false
        )]
        [System.Int32]
        $AliveMilli = 3000,

        [Parameter(
            Mandatory = $false
        )]
        [Switch]
        $Forever,

        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Path
    )

    BEGIN {

        $CacheFolderPath = ![System.String]::IsNullOrEmpty($Path) ? $Path : $env:UTILS_CACHE_PATH ?? "$([System.IO.Path]::GetTempPath())/.cache/"
        $filename = ($($type, $Identifier, "json") | Where-Object { $_ }) -join '.' | Get-CleanFilename
        $CacheFilePath = Join-Path -Path $CacheFolderPath -ChildPath  $filename.toLower()
    
        if (-not (Test-Path -Path $CacheFolderPath)) {
            $null = New-Item -Path $CacheFolderPath -ItemType Directory -Force
        }
    
        $Date = $null
        if ($Forever) {
            $Date = ([DateTime]::Now).AddMilliseconds([System.Int32]::MaxValue)
        }
        elseif ($PSBoundParameters.ContainsKey('Alive')) {
            $Date = ([DateTime]::Now).AddMinutes($Alive)
        }
        else {
            $Date = ([DateTime]::Now).AddMilliseconds($AliveMilli)
        }
    
        $inputList = [System.Collections.ArrayList]::new()

    }

    PROCESS {
        $null = $inputList.Add($Object)
    }
    
    END {
        $cacheContent = $inputList

        if($inputList.Count -EQ 1) {
            $cacheContent = $inputList[0]
        }

        @{
            Date    = $Date
            Content = $cacheContent
        }  
        | ConvertTo-Json -Depth 16 
        | Out-File -Path $CacheFilePath
   
        return $cacheContent
    }

}
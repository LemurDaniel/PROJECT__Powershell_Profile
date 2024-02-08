

<#
    .SYNOPSIS
    Set a chache by a type and a specified identifier.

    .DESCRIPTION
    Set a chache by a type and a specified identifier.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Return the cached object.


    .LINK
        
#>
function Set-UtilsConfiguration {

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
        [System.String]
        $Path
    )

    BEGIN {

        $CacheFolderPath = Get-UtilsCachePath -Path $Path -Source "Configurationdata"
        $filename = ($($type, $Identifier, "json") | Where-Object { $_ }) -join '.' | Get-CleanFilename
        $CacheFilePath = Join-Path -Path $CacheFolderPath -ChildPath  $filename.toLower()
    
        if (-not (Test-Path -Path $CacheFolderPath)) {
            $null = New-Item -Path $CacheFolderPath -ItemType Directory -Force
        }
    
        $inputList = [System.Collections.ArrayList]::new()

    }

    PROCESS {
        $null = $inputList.Add($Object)
    }
    
    END {
        $cacheContent = $inputList

        if ($inputList.Count -EQ 1) {
            $cacheContent = $inputList[0]
        }

        @{
            Content = $cacheContent
        }  
        | ConvertTo-Json -Depth 16 
        | Out-File -Path $CacheFilePath
   
        return $cacheContent
    }

}
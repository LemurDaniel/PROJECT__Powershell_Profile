function Add-EnvPaths {

    param (
        [Parameter()]
        [System.String]
        $AdditionalPath,

        [Parameter()]
        [System.String]
        $AdditionalValue
    )

    $global:DefaultEnvPaths[$AdditionalPath] = $AdditionalValue
    $UniquePathsMap = [System.Collections.Hashtable]::new()
    $processedPaths + $global:DefaultEnvPaths.Values | Where-Object -Property Length -GT 0 | ForEach-Object { $UniquePathsMap[$_] = $_ } 
    $env:Path = ($UniquePathsMap.Values -join ';')
}

$global:DefaultEnvPaths = @{}
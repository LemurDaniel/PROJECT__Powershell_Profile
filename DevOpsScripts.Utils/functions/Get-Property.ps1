function Get-Property {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Object,

        [Alias('Property')]
        [Parameter(Mandatory = $false)]
        [System.String]
        $PropertyPath
    )

    if ([System.String]::isNullOrEmpty($PropertyPath)) {
        return $Object
    }


    $segmented = '.' + $PropertyPath.toLower() -replace '[\/\.]+', '.'

    while ($segmented) {

        Write-Verbose '_----------------------------_'
        Write-Verbose ($Object.GetType().BaseType ?? $Object.GetType().Name)

        $objectProperties = $Object.PSObject.Properties
        if ($Object.GetType().BaseType -eq [System.Array]) {
            $objectProperties = $Object[0].PSObject.Properties
        }

        Write-Verbose ($objectProperties.Name | ConvertTo-Json)

        $Target = $objectProperties | `
            Where-Object { $segmented.Contains('.' + $_.Name.toLower()) } | `
            Sort-Object -Property @{ Expression = { $segmented.IndexOf('.' + $_.Name.toLower()) } } | `
            Select-Object -First 1

        if ($null -eq $Target) {
            Throw "Path: '$PropertyPath' - Error at '$segmented' - is NULL"
        }

        Write-Verbose "$segmented, $($Target.name.toLower())"
        $segmented = $segmented -replace "\.$($Target.name.toLower())", ''
        Write-Verbose "$segmented, $($Target.name.toLower())"
        $Object = $Object."$($Target.name)" # Don't use Target Value, in case $object is Array and multiple need to be returned
    }

    return $Object
}
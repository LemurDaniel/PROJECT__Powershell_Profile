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


    $segmented = $PropertyPath.toLower() -replace '[\/\.]+', '.'

    while ($segmented) {

         Write-Verbose "_----------------------------_"
        Write-Verbose ($Object.GetType().BaseType)

        $objectProperties = $Object.PSObject.Properties
        if ($Object.GetType().BaseType -eq [System.Array]) {
            $objectProperties = $Object[0].PSObject.Properties
        }

        Write-Verbose ($objectProperties.Name | ConvertTo-Json)

        $Target = $objectProperties | `
         Where-Object { $segmented.Contains($_.Name.toLower()) } | `
         Sort-Object -Property @{ Expression = { $segmented.IndexOf($_.Name.toLower()) } } | `
         Select-Object -First 1

        if ($null -eq $Target) {
            Throw "Path: '$PropertyPath' - Error at '$segmented' - is NULL"
        }

        Write-Verbose "$segmented, $($Target.name.toLower())"
        $segmented = $segmented -replace "\.*$($Target.name.toLower())\.*", ''
         Write-Verbose "$segmented, $($Target.name.toLower())"
        $Object = $Object."$($Target.name)" # Don't use Target Value, in case $object is Array and multiple need to be returned
    }

    <#
    foreach ($segment in $splitPath) {

        $segment = $segment -replace '[()]+', ''
        Write-Verbose $segment
        if ($null -eq $Object) {
            Throw "Path: $PropertyPath - Error at Segment $segment - Object is NULL"
        }

        #if ($Object.GetType().Name -notin @('PSObject', 'PSCustomObject') ) {
        #    Throw "Path: $PropertyPath - Error at Segment $segment - Object is $($Object.GetType().Name)"
        #}

        if ($null -eq $Object."$segment") {
            Throw "Path: $PropertyPath - Error at Segment $segment - Segment does not exist "
        }

        $Object = $Object."$segment"
    }
    #>

    return $Object
}
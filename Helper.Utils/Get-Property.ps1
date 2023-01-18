function Get-Property {
    param (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Object,

        [Alias('Property')]
        [Parameter(Mandatory = $false)]
        [System.String]
        $PropertyPath
    )

    if([System.String]::isNullOrEmpty($PropertyPath)){
        return $Object
    }

    $splitPath = $PropertyPath -split '[\/\.]+'
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

    return $Object
}
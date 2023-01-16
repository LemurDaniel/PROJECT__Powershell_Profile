function Search-PreferencedObject {

    [cmdletbinding()]
    [Alias('Search-In')]
    param (
        [Parameter(Mandatory = $true)]
        [System.Object[]]
        $SearchObjects,

        [Alias('is')]
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $SearchTags,

        [Alias('not')]
        [Parameter(Mandatory = $false)]
        [System.String[]]
        $ExcludeSearchTags,

        [Alias('where')]
        [Parameter()]
        [System.String]
        $SearchProperty = 'name',

        [Alias('return')]
        [Parameter()]
        [System.String]
        $returnProperty,

        [Parameter()]
        [Switch]
        $Multiple
    )


    $ExcludeSearchTags = $ExcludeSearchTags ?? @()
    $ChosenObjects = $SearchObjects | ForEach-Object {
    
        Write-Verbose "Search Property: $SearchProperty"
        $Property = $_."$SearchProperty"
        Write-Verbose $Property
        Write-Verbose ($SearchTags -join ',')
        Write-Verbose ($ExcludeSearchTags -join ',')
        $positiveHits = ($SearchTags | Where-Object { $Property.toLower().contains($_.toLower()) } | Measure-Object).Count
        $negativeHits = ($ExcludeSearchTags | Where-Object { !($Property.toLower().contains($_.toLower())) } | Measure-Object).Count

        $returnValue = [String]::IsNullOrEmpty($returnProperty) ? $_ : $_."$returnProperty"

        return [PSCustomObject]@{
            Hits     = $positiveHits - $negativeHits
            Property = $returnValue
            Object   = $_
        }
    } | `
        Where-Object { $_.Hits -gt 0 } | `
        Sort-Object -Property Hits -Descending

    if ($ChosenObjects.Count -eq 0) {
        return
    }
    if ($Multiple) {
        return  $ChosenObjects.Property
    }
    else {
        return $ChosenObjects.GetType().BaseType -eq [System.Array] ? $ChosenObjects[0].Property : $ChosenObjects.Property
    }
   
}
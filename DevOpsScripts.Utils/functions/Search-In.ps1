

<#
    .SYNOPSIS
    Searches an Object with most hits.

    .DESCRIPTION
    Searches an object with most hits by search tags.
    The Property to search can be specfied.
    The return Property can be specifed.
    Wether to return multiple or single values can be specified.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None.


    .EXAMPLE

    Get All Projects in the current organization containing the name containig BRZ and 365:
    
    PS> Search-in (Get-DevOpsProjects) -where 'name' -is BZR,365 -return name -Multiple

    .EXAMPLE

    Get All the LocalPath of repositories in the current Project containing the word terraform:
    
    PS> Search-in (Get-ProjectInfo 'repositories') -where 'name' -is terraform -return LocalPath -Multiple

    .LINK
        
#>
function Search-In {

    [cmdletbinding()]
    [Alias('Search-PreferencedObject')]
    param (
        [Parameter(Mandatory = $false)]
        [System.Object[]]
        $SearchObjects = @(),

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

    if ($SearchTags -eq '*') {
        $ChosenObjects = @{
            Property = Get-Property -Object $SearchObjects -Property $returnProperty
        }
    }
    else {

        $ExcludeSearchTags = $ExcludeSearchTags ?? @()
        $ChosenObjects = $SearchObjects | ForEach-Object {
    
            Write-Verbose "Search Property: $SearchProperty"
            $Property = (Get-Property -Object $_ -Property $SearchProperty)
            Write-Verbose $Property
            Write-Verbose ($SearchTags -join ',')
            Write-Verbose ($ExcludeSearchTags -join ',')
            $positiveHits = ($SearchTags | Where-Object { $Property.toLower().contains($_.toLower()) } | Measure-Object).Count
            $negativeHits = ($ExcludeSearchTags | Where-Object { !($Property.toLower().contains($_.toLower())) } | Measure-Object).Count

            $returnValue = [String]::IsNullOrEmpty($returnProperty) ? $_ : (Get-Property -Object $_ -Property $returnProperty)

            return [PSCustomObject]@{
                Hits     = $positiveHits - $negativeHits
                Property = $returnValue
                Object   = $_
            }
        } | `
            Where-Object -Property Hits -GT -Value 0 | `
            Sort-Object -Property Hits -Descending

    }


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
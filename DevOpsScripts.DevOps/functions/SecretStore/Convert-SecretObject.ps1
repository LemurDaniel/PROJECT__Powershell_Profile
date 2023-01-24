enum SecretScope {
    ALL
    ORG
    PERSONAL
}

function Convert-SecretObject {
    param (
        [parameter()]
        [PSObject]
        $SecretObject,

        [parameter()]
        [System.String]
        $indendation,

        [parameter()]
        [System.String]
        $SecretPrefixGlobal,

        [parameter()]
        [switch]
        $envFlaggedGlobal,

        [parameter()]
        [switch]
        $loadFlaggedGlobal,

        [parameter()]
        [Switch]
        $show,

        [Parameter()]
        [System.int32]
        $recursionDepth = 0
    )


    $_OMITPREFIX = $SecretObject.'_OMITPREFIX' ?? @() 
    $_ORDER = $SecretObject.'_ORDER' ?? @() #TODO Order nit working anymore when merging secret stores
    $_SILENT = $SecretObject.'_SILENT' ?? @()
    $_LOAD = $_ORDER + $_SILENT 
    $SecretObject = $SecretObject | Sort-Object -Property { $_ORDER.IndexOf($_.Name) } 


    $verbosing = ''

    foreach ($Secret in $SecretObject.PSObject.Properties) {

        if ($null -eq $Secret.Value ) {
            continue;
        }

        if (@('_ORDER', '_SILENT').contains($Secret.Name.ToUpper())) {
            continue;
        }

        $envFlaggedLocal = $Secret.name.length -gt 5 -AND $Secret.name.substring(0, 5).ToUpper() -eq '$ENV:'
        $enumFlagged = $Secret.name.length -gt 6 -AND $Secret.name.substring(0, 6).ToUpper() -eq '$ENUM:'

        $cleanedName = $secret.name
        if ($envFlaggedLocal) {
            $cleanedName = $Secret.name.substring(5)
        }
        elseif ($enumFlagged) {
            $cleanedName = $Secret.name.substring(6)
        }

        $secretPrefixedName = $SecretPrefixGlobal + $cleanedName
        $envFlagged = $envFlaggedGlobal -OR $envFlaggedLocal

        # A load flag sets load for all subobjects, and searches for envs
        $loadFlagged = $_LOAD.contains($Secret.Name) -OR $loadFlaggedGlobal

        # $Secret.value.GetType() -eq [PSCustomObject] doesn't work
        # Search all Subsequent Objects if load or env flagged
        if ($Secret.value.GetType().Name -eq 'PSCustomObject' -AND ($envFlagged -OR $loadFlagged)) {
            $SecretPrefix = $SecretPrefixGlobal + ($_OMITPREFIX.contains($cleanedName) ? '' : "$cleanedName`_")
            $verboseStuff = Convert-SecretObject -show:$($show) -recursionDepth ($recursionDepth + 1) -envFlagged:$($envFlagged) -loadFlaggedGlobal:$($loadFlagged) `
                -SecretObject $Secret.value -SecretPrefix ($SecretPrefix ) -indendation ($indendation + '   ')

            if ($verboseStuff.length -gt 0) {
                $verbosing = $verbosing + "`n$indendation + Loading '$($secretPrefixedName)'" + $verboseStuff
            }

        }
        # If env-flagged and string convert to env
        elseif ($envFlagged -AND $Secret.value.GetType() -eq [System.String]) {
            $SecretValue = $Secret.value[0] -eq '´' ? (Invoke-Expression -Command $Secret.value.substring(1)) : $Secret.value
            $null = New-Item -Path "env:$secretPrefixedName" -Value $SecretValue -Force  
            $verbosing += "`n$indendation + Loading 'ENV:$($secretPrefixedName)'"
        }
        # If env-flagged and valutetype convert to env string (Like Dates will throw Errors)
        elseif ($envFlagged -AND $Secret.value.GetType().BaseType -eq [System.ValueType]) {
            $SecretValue = $Secret.value.toString()
            $null = New-Item -Path "env:$secretPrefixedName" -Value $SecretValue -Force  
            $verbosing += "`n$indendation + Loading 'ENV:$($secretPrefixedName)'"
        }
        elseif ($envFlagged -AND $Secret.value.GetType().BaseType -eq [System.Array]) {
            Throw "Can't Load 'System.Array' to ENV"
        }
        elseif ($enumFlagged -AND $Secret.value.GetType().BaseType -eq [System.Array]) {
            $verbosing += "`n$indendation + Loading 'ENUM:$($cleanedName)'"

            Add-Type -TypeDefinition @"
    public enum $($cleanedName) {
        $($Secret.Value -join ', ') 
    }
"@

        }
        if ($recursionDepth -eq 0 -AND $verbosing.Length -gt 0 -AND $show) {
            Write-Host $verbosing.Substring(1)
            $verbosing = ''
        }
    }

    return $show ? $verbosing : '' 
}
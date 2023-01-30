<#
.Synopsis
    Formats content in a Standardized way for sending via Sendgrid
 
.DESCRIPTION
    
 
.EXAMPLE
 
#>


. "$PSScriptRoot/classes/Stylesheet.ps1"
. "$PSScriptRoot/classes/SendGridHTMLFormat.ps1"

function Format-SendGridContent {

    param(
        [Parameter(
            Mandatory = $false
        )]
        [SendGridHTMLFormat]
        $SendGridHTMLFormat,

        # The Content to turn into HTML-Email.
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [PSObject[]]
        $ContentObjects,

        # Parameter for defining which Property gets interpreted as a Link. If the key is Found, will use elements from the Key as LinkNames.
        [Parameter(Mandatory = $false)]
        [System.Collections.Hashtable]
        $PropertiesAsLink = @{
            Name = 'URL'
        },

        [Parameter(Mandatory = $false)]
        [System.String]
        $ContentInsert = '$1',

        [Parameter(Mandatory = $false)]
        [System.String[]]
        $Order = '*',

        [Parameter(Mandatory = $false)]
        [System.String[]]
        $ExcludeProperty = '',

        [Parameter()]
        [System.String]
        [ValidateSet([Stylesheet])] 
        $CSS_STYLE
    )


    Begin {

        $SendGridHTMLFormat = $SendGridHTMLFormat ?? [SendGridHTMLFormat]::new()
        $collection = [System.Collections.ArrayList]::new()
    }
    Process {

        ForEach ($Object in $ContentObjects) {

            $convertedResult = $Object | ConvertTo-Json | ConvertFrom-Json -Depth 8
            $PropertiesAsLink.GetEnumerator() | ForEach-Object {
                $linkSource = $_.Value
                $linkSource = $convertedResult."$linkSource"
                $linkName = $_.Key
                $linkName = [System.String]::IsNullOrEmpty($convertedResult."$linkName") ? $linkName : $convertedResult."$linkName"

                # Because ConvertTo-HTML messes with the <a href link...
                $linkPrototype = "[HREF_START]$linkSource[HREF_MIDDLE]$linkName[HREF_END]"

                $convertedResult = $convertedResult | Select-Object -ExcludeProperty $linkName, $linkSource
                $null = $convertedResult | Add-Member NoteProperty $_.Key $linkPrototype -Force
            }

            $convertedResult = $convertedResult | Select-Object -Property $Order -ExcludeProperty $ExcludeProperty
            $null = $collection.Add($convertedResult)
        }

    }

    End {

        $htmlFragment = $collection | ConvertTo-Html -Fragment
        $htmlFragment = $htmlFragment -replace '\[HREF_START\]', '<a href="' -replace '\[HREF_MIDDLE\]', '"> ' -replace '\[HREF_END\]', ' </a>'
        $null = $SendGridHTMLFormat.AddElement($CSS_STYLE, $htmlFragment, $ContentInsert)

        return $SendGridHTMLFormat
    }

}
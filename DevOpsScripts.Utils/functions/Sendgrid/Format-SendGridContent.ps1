<#
.Synopsis
    Formats Content into an HTML-Table with some custom CSS and ability to create href-links.
 
.DESCRIPTION
    Formats Content into an HTML-Table with some custom CSS and ability to create href-links.
    Primarly used for sending a HTML-Formatted Table via SendGrid.

.EXAMPLE

    Get recently created Disks and format it into a HTML-Table with some CSS:

    PS> $createdDisks = Get-AzResourceGraphChangesCreate `
            -ResourceType 'microsoft.compute/disks' `
            -ResourceAttributes @{
                diskSizeBytes     = 'format_bytes(tolong(properties.diskSizeBytes))'
                skuName           = 'sku.name'
                skuTier           = 'sku.tier'
            }

   PS> $order = @('Operation', 'TimeStamp', 'Name', 'diskSizeBytes', 'skuName', 'skuTier', 'ResourceGroup')        
   PS> $sendGridFormat = $createdDisks | `
            Format-SendGridContent `
            -PropertiesAsLink @{ Name = 'resourceUrl' } `
            -Order $order `
            -CSS_STYLE 'TABLE_STYLE_BLUE' `
            -ContentInsert "<h3>List of Created Disks:</h3>`$1"

   PS> $sendGridFormat.toHTMLString() | Out-File createdDisks.html

#>

function Format-SendGridContent {

    param(
        # A special class when the function is called several times with different lists.
        [Parameter(
            Mandatory = $false
        )]
        [ValidateScript(
            {
                $null -eq $_ -OR ($_.GetType() -eq (New-SendGridHtmlFormat).GetType())
            },
            ErrorMessage = 'Must be an instance of SendGridHtmlFormat'
        )]
        [AllowNull()]
        [PSObject]
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
        $PropertiesAsLink = @{},

        # Some outer html, where $1 defines the insertion of the HTML-Table.
        [Parameter(Mandatory = $false)]
        [System.String]
        $ContentInsert = '$1',

        # Which Properties to keep in which Order in the created Table.
        [Parameter(Mandatory = $false)]
        [System.String[]]
        $Order = '*',

        # Which Properties to exclude from the created Table.
        [Parameter(Mandatory = $false)]
        [System.String[]]
        $ExcludeProperty = '',

        # The Filename of a predfined Table-Css-Style.
        [Parameter()]
        [System.String]
        [ValidateScript(
            {
                $_ -in (New-Stylesheet).GetValidValues()
            },
            ErrorMessage = ''
        )]
        $CSS_STYLE
    )


    Begin {

        $SendGridHTMLFormat = $SendGridHTMLFormat ?? (New-SendGridHtmlFormat)
        $collection = [System.Collections.ArrayList]::new()

        if ([regex]::Matches($ContentInsert, '\$1').Count -gt 1) {
            throw 'Only one of $1 Content-Insertion is allowed'
        }
    }
    Process {

        ForEach ($Object in $ContentObjects) {
            $convertedResult = $Object | ConvertTo-Json | ConvertFrom-Json -Depth 8
            $PropertiesAsLink.GetEnumerator() | ForEach-Object {
                $linkSource = $_.Value
                $linkSource = $convertedResult."$linkSource"

                if ([System.String]::IsNullOrEmpty($linkSource)) {
                    throw "$($_.Value) not found." 
                }

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
        return  $SendGridHTMLFormat.AddElement($CSS_STYLE, $htmlFragment, $ContentInsert)

    }

}
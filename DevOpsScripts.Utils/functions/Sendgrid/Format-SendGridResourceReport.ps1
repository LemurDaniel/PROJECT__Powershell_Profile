
<#
.Synopsis
    Higly specific Function, closley Coupled with 'Get-AzResourceGraphChangesCreate', 'Get-AzResourceGraphChangesUpdate' and 'Get-AzResourceGraphChangesDelete',
    to create a HTML-formatted Table of the Changes.

.DESCRIPTION
    Higly specific Function, closley Coupled with 'Get-AzResourceGraphChangesCreate', 'Get-AzResourceGraphChangesUpdate' and 'Get-AzResourceGraphChangesDelete',
    to create a HTML-formatted Table of the Changes.
 
.EXAMPLE

    Get recently created Disks and format it into a HTML-Table with some CSS:

    PS> $createdDisks = Get-AzResourceGraphChangesCreate `
            -ResourceType 'microsoft.compute/disks' `
            -ResourceAttributes @{
                newDiskSizeBytes    = 'format_bytes(tolong(properties.diskSizeBytes))'
                skuName             = 'sku.name'
                skuTier             = 'sku.tier'
            }

    PS> $updatedDisks = Get-AzResourceGraphChangesUpdate -ResourceType  'microsoft.compute/disks' `
            -UpdateProperty 'properties.diskSizeBytes' -format 'format_bytes(tolong($1))' `
            -ResourceAttributes @{
                skuName           = 'sku.name'
                skuTier           = 'sku.tier'
            }

    PS> $changedResources = $createdDisks + $updatedDisks
    PS> $resourceReport = Format-SendGridResourceReport `
                -ResourceData $changedResources `
                -ResourceType 'Disks' `
                -PreviousProperty previousDiskSizeBytes `
                -NewProperty newDiskSizeBytes `
                -Order TimeStamp, Name, previousDiskSizeBytes, newDiskSizeBytes, skuName, skuTier, ResourceGroup `
                -PropertiesAsLink @{ Name = 'ResourceUrl' }

    PS> $resourceReport | Out-File resourceReport.html
#>

function Format-SendGridResourceReport {

    param(
        # A list of changes created by, Get-AzResourceGraphChangesCreate, Get-AzResourceGraphChangesDelete and Get-AzResourceGraphChangesUpdate
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]
        $ResourceData,

        # This is only how the Resource Type will be displayed in the HTML. For example entering Virtual Machines will show as Recently Created 'Virtual Machines', etc-
        [Parameter(Mandatory = $true)]
        [System.String]
        $ResourceType,

        # An additonal link for display above table, for current requirement. Might rewrite.
        [Parameter(Mandatory = $false)]
        [System.String]
        $LinkInfo,

        # Coupled with  Get-AzResourceGraphChangesUpdate filter out the previousChangeValue on certain tables.
        [Parameter(Mandatory = $true)]
        [System.String]
        $previousProperty,

        # Coupled with  Get-AzResourceGraphChangesUpdate filter out the newChangeValue on certain tables.
        [Parameter(Mandatory = $true)]
        [System.String]
        $newProperty,

        # Parameter for defining which Property gets interpreted as a Link. If the key is Found, will use elements from the Key as LinkNames.
        [Parameter(Mandatory = $false)]
        [System.Collections.Hashtable]
        $PropertiesAsLink = @{},

        # Defines which properties of the Input will be put in the table in which order.
        [Parameter(Mandatory = $false)]
        [System.String[]]
        $Order = '*',

        # Defines how the Timestamp gets interpreted.
        [Parameter(Mandatory = $false)]
        [ValidateSet(
            'Central Europe Standard Time'
        )]
        [System.String]
        $timeZone = 'Central Europe Standard Time'
    )

    $LookupTable = @{
        'UTC' = 1440
        'Central Europe Standard Time' = 37
    }
    $timeZoneInfo  = [System.TimeZoneInfo]::FindSystemTimeZoneById($timeZone)
    $TimeStampName = "TimeStamp ($($timeZone -creplace '[a-z\s]', ''))"
    $TimeConversionLink = "https://www.timeanddate.com/worldclock/converter.html?iso={0}&p1=$($LookupTable['UTC'])&p2=$($LookupTable[$timeZone])"

    $null  = $PropertiesAsLink.Add($TimeStampName, 'TimeStampConversionLink')
    $Order = $Order | ForEach-Object { $_ -eq 'TimeStamp' ? $TimeStampName : $_ }

    Write-Host -ForegroundColor Yellow "Converting Content to be send via SendGrid `n`n"
      
    $SendGridHTMLFormat = New-SendGridHtmlFormat

    $ResourceData = $ResourceData | Select-Object *, @{
        Name       = $TimeStampName
        Expression = {
            ([System.TimeZoneInfo]::ConvertTimeFromUtc($_.TimeStamp, $timeZoneInfo).toString('dd.MM.yyyy  HH:mm:ss'))
        }
    }, @{
        Name       = 'TimeStampConversionLink'
        Expression = {
            [System.String]::Format($TimeConversionLink, $_.TimeStamp.toString('yyyyMMddTHHmmss'))
        }
    }

    $updatedResources = $resourceData | Where-Object -Property Operation -EQ 'Update' 
    $createdResources = $resourceData | Where-Object -Property Operation -EQ 'Create' 
    $deletedResources = $resourceData | Where-Object -Property Operation -EQ 'Delete' 
    $recreatedResources = $resourceData | Where-Object -Property Operation -EQ 'Recreate' 
    $createdAndDeletedResources = $resourceData | Where-Object -Property Operation -EQ 'CreateAndDelete' 

    if ($updatedResources.Count -gt 0) {

        $SendGridHTMLFormat = $updatedResources | `
            Format-SendGridContent -SendGridHTMLFormat $SendGridHTMLFormat `
            -PropertiesAsLink $PropertiesAsLink `
            -Order $Order -ExcludeProperty TimeLived `
            -CSS_STYLE 'TABLE_STYLE_BLUE' `
            -ContentInsert "
            <h3>Recently Updated '$resourceType':</h3>
            $linkInfo
            `$1
            "
    }

    if ($createdResources.Count -gt 0) {

        $SendGridHTMLFormat = $createdResources | `
            Format-SendGridContent -SendGridHTMLFormat $SendGridHTMLFormat `
            -PropertiesAsLink $PropertiesAsLink `
            -Order $Order -ExcludeProperty $previousProperty, TimeLived `
            -CSS_STYLE 'TABLE_STYLE_GREEN' `
            -ContentInsert "
            <h3>Recently Created '$resourceType':</h3>
            $linkInfo
            `$1
            "
    }

    if ($deletedResources.Count -gt 0) {

        $SendGridHTMLFormat = $deletedResources | `
            Format-SendGridContent -SendGridHTMLFormat $SendGridHTMLFormat `
            -PropertiesAsLink $PropertiesAsLink `
            -Order $Order -ExcludeProperty $newProperty, TimeLived `
            -CSS_STYLE 'TABLE_STYLE_RED' `
            -ContentInsert "
            <h3>Recently Deleted '$resourceType':</h3>
            $linkInfo
            `$1
            "
    }

    if ($recreatedResources.Count -gt 0) {

        $SendGridHTMLFormat = $recreatedResources | `
            Format-SendGridContent -SendGridHTMLFormat $SendGridHTMLFormat `
            -PropertiesAsLink $PropertiesAsLink `
            -Order $Order -ExcludeProperty $previousProperty, TimeLived `
            -CSS_STYLE 'TABLE_STYLE_YELLOW' `
            -ContentInsert "
            <h3>Recently Recreated '$resourceType':</h3>
            $linkInfo
            `$1
            "
    }

    if ($createdAndDeletedResources.Count -gt 0) {

        $SendGridHTMLFormat = $createdAndDeletedResources | `
            Format-SendGridContent -SendGridHTMLFormat $SendGridHTMLFormat `
            -PropertiesAsLink $PropertiesAsLink `
            -Order $Order `
            -CSS_STYLE 'TABLE_STYLE_ORANGE' `
            -ContentInsert "
            <h3>Recently CreatedAndDeleted '$resourceType':</h3>
            $linkInfo
            `$1
            "
    }


    Write-Host -ForegroundColor Green "`n`n Finished Converting Content"

    return $SendGridHTMLFormat.toHTMLString()
}

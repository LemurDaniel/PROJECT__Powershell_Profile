
<#
.Synopsis


.DESCRIPTION
    
 
.EXAMPLE
 
#>

. "$PSScriptRoot/classes/Stylesheet.ps1"
. "$PSScriptRoot/classes/SendGridHTMLFormat.ps1"

function Format-SendGridResourceReport {

    param(

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]
        $ResourceData,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ResourceType,

        [Parameter(Mandatory = $true)]
        [System.String]
        $LinkInfo,

        [Parameter(Mandatory = $true)]
        [System.String]
        $previousProperty,

        [Parameter(Mandatory = $true)]
        [System.String]
        $newProperty,

        [Parameter(Mandatory = $false)]
        [System.String[]]
        $Order = '*'
    )

    Write-Host -ForegroundColor Yellow "Converting Content to be send via SendGrid `n`n"
      
    $SendGridHTMLFormat = $null

    $updatedResources = $resourceData | Where-Object -Property Operation -EQ 'Update' 
    $createdResources = $resourceData | Where-Object -Property Operation -EQ 'Create' 
    $deletedResources = $resourceData | Where-Object -Property Operation -EQ 'Delete' 
    $recreatedResources = $resourceData | Where-Object -Property Operation -EQ 'Recreate' 
    $createdAndDeletedResources = $resourceData | Where-Object -Property Operation -EQ 'CreateAndDelete' 

    if ($updatedResources.Count -gt 0) {

        $SendGridHTMLFormat = $updatedResources | `
            Format-SendGridContent -SendGridHTMLFormat $SendGridHTMLFormat `
            -PropertiesAsLink @{ Name = 'URL' } `
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
            -PropertiesAsLink @{ Name = 'URL' } `
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
            -PropertiesAsLink @{ Name = 'URL' } `
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
            -PropertiesAsLink @{ Name = 'URL' } `
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
            -PropertiesAsLink @{ Name = 'URL' } `
            -Order $Order `
            -CSS_STYLE 'TABLE_STYLE_YELLOW' `
            -ContentInsert "
            <h3>Recently CreatedAndDeleted '$resourceType':</h3>
            $linkInfo
            `$1
            "
    }


    Write-Host -ForegroundColor Green "`n`n Finished Converting Content"

    return $SendGridHTMLFormat.toHTMLString()
}

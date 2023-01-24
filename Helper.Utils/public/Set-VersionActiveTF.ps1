function Set-ActiveVersionTF {

    [CmdletBinding()]
    param (
        [Parameter()]
        [System.String]
        $version
    )

    Set-UtilsCache -Object $version -Type TerraformVersion -Identifier Current -Forever

}

function Get-ActiveVersionTF {

    [CmdletBinding()]
    param ()

    Get-UtilsCache -Type TerraformVersion -Identifier Current

}


<#
    .SYNOPSIS
    Set a chache by a type and a specified identifier.

    .DESCRIPTION
    Set a chache by a type and a specified identifier.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Return the cached object.


    .EXAMPLE

    Cache a value for 3 Minutes:

    PS> Get-UtilsCache -object $value -Type value -Identifier current -Alive 3

        .EXAMPLE

    Cache the all pim-profiles forever:

    PS> Get-UtilsCache -Object $profiles -Type PIM_Profiles -Identifier all -Forever
    
    .LINK
        
#>
function Set-UtilsCache {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [PSCustomObject]
        $Object = @{},

        [Parameter(Mandatory = $true)]
        [System.String]
        $Type,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Identifier,

        [Parameter(Mandatory = $false)]
        [System.Int32]
        $Alive = 120,

        [Parameter(Mandatory = $false)]
        [Switch]
        $Forever,

        [Parameter(Mandatory = $false)]
        [System.String]
        $Path = "$PSScriptRoot/.cache/"
    )

    $cachePath = Join-Path -Path $Path -ChildPath (".$Type.$Identifier.json".toLower() -replace '[\/\\\s]+', '_') 
    
    if (-not (Test-Path -Path $Path)) {
        $null = New-Item -Path $Path -ItemType Directory -Force
    }
    
    $Alive = $Forever ? [System.Int32]::MaxValue : $Alive
    @{
        Date    = ([DateTime]::Now).AddMinutes($Alive)
        Content = $Object
    } | ConvertTo-Json -Depth 16 | Out-File -Path $cachePath
   
    return $Object

}
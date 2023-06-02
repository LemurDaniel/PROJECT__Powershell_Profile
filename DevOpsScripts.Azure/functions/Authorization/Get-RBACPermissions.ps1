
<#
    .SYNOPSIS
    Selects and Gets Information about any available RBAC-Permission.

    .DESCRIPTION
    Selects and Gets Information about any available RBAC-Permission.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    A list of all RBAC-Permission from the Parameters specified.


    .EXAMPLE

    Get all Operation Names for Microsoft.Storage:

    PS> Get-RBACPermissions 'Microsoft.Storage.Operation Name'

    
    .LINK
        
#>
function Get-RBACPermissions {

    param (
        # The Property to return from the items. If null will return full Properties.
        [Alias('return')]
        [Parameter()]
        [System.String]
        $Property
    )

    # Conversion from Json to Powershell object tales a bit.
    if (!$global:rbacPermissions) {
        $global:rbacPermissions = New-Object -TypeName "System.Object"
        $null = Get-ChildItem -Path "$PSScriptRoot/.resources/" -Recurse -Filter 'Permissions.**.json' 
        | Select-Object -First 1 | Get-Content | ConvertFrom-Json | `
            Group-Object -Property "Resource Provider"
        | Where-Object {
            $null -ne $_."Operation Display Name"
        }
        ForEach-Object { 
            $global:rbacPermissions | Add-Member NoteProperty $_.Name @($_.Group | % { $_ }) 
        }
    }

    return Get-Property -object $global:rbacPermissions -Property $Property
}

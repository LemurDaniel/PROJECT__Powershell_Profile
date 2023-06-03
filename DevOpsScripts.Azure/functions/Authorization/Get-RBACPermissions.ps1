
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
        [Parameter()]
        [switch]
        $AsHashtable
    )

    if (!$global:rbacPermissionsHashtable -OR !$global:rbacPermissions) {
        $global:rbacPermissions = New-Object -TypeName "System.Object"
        $global:rbacPermissionsHashtable = [System.Collections.Hashtable]::new()
        Get-ChildItem -Path "$PSScriptRoot/../.resources/" -Recurse -Filter 'Permissions.**.json' 
        | Select-Object -First 1 | Get-Content | ConvertFrom-Json
        | Where-Object -Property "Resource Provider" -Match -Value "^[^\s]+\.{1}[^\s]+$"
        | Group-Object -Property "Resource Provider"
        | ForEach-Object { 
            $global:rbacPermissions | Add-Member NoteProperty $_.Name @($_.Group | % { $_ })  -Force
            $null = $global:rbacPermissionsHashtable.add($_.Name, $_.Group)
        }

    }

    if ($AsHashtable) {
        return $global:rbacPermissionsHashtable
    }
    else {
        return $global:rbacPermissions
    }
}

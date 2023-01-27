

function Get-RBACPermissions {

    param ()
    $global:rbacPermissions = $global:rbacPermissions ?? (Get-ChildItem -Path "$PSScriptRoot/.." -Recurse -Filter 'Permissions**.json' | Get-Content | ConvertFrom-Json)

    return $global:rbacPermissions
}

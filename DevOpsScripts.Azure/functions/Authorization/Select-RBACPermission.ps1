

function Select-RBACPermission {

    param (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Keys,

        [Parameter()]
        [System.String] #TODO
        $Provider ,

        [Parameter()]
        [System.int32]
        $Limit = 7
    )


    $permissionsToSearch = [AzPermission]::GetPermissionsByProvider($Provider)

    return (Search-PreferencedObject -SearchObjects $permissionsToSearch -SearchTags $Keys -SearchProperty 'Operation Name' -Multiple)[0..($Limit - 1)]
}

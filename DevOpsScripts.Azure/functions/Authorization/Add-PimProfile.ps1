function Add-PimProfile {

    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $ProfileName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Scope,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Role,

        [Parameter(Mandatory = $true)]
        [System.int32]
        [ValidateScript(
            { 
                $_ -ge 1 -AND $_ -le 8
            },
            ErrorMessage = 'Duration must be between 1 and 8 Hours inclusive.'
        )]
        $Duration,

        [Parameter(

        )]
        [switch]
        $Force
    )

    $Profiles = Get-PimProfiles

    if (!$Force -AND $Profiles[$ProfileName]) {
        throw 'Context with same name already exists'
    }
    $Profiles[$ProfileName] = @{
        ProfileName = $ProfileName
        Scope       = $Scope 
        Role        = $Role
        Duration    = $Duration
    }


    return Set-UtilsCache -Object $Profiles -Type PIM_Profiles -Identifier (Get-AzContext).Account.Id -Forever
}
function Set-VersionActiveTF {

    [CmdletBinding()]
    param (
        [Parameter()]
        [System.String]
        $version
    )

    Update-SecretStore ORG -ENV -SecretPath CONFIG.TF_VERSION_ACTIVE -SecretValue $version

}
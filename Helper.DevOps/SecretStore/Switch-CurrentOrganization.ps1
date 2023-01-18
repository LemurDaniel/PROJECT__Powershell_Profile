function Switch-CurrentOrganization {
    [CmdletBinding()]
    param (
        [parameter()]
        [ORGANIZATION]
        $Organization
    )
    
    Update-SecretStore -ENV -SecretStoreSource PERSONAL -SecretPath CONFIG/AZURE_DEVOPS/ORGANIZATION.CURRENT -SecretValue $Organization
    $env:AZURE_DEVOPS_ORGANIZATION_CURRENT = $Organization
    Get-SecretsFromStore

}
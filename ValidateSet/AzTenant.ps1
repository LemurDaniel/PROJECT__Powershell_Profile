class AzTenant : System.Management.Automation.IValidateSetValuesGenerator {

    static [PSCustomObject[]] $ALL = (Get-SecretFromStore CACHE.AZURE_TENANTS)
    static [PSCustomObject[]] $DEFAULT = (Get-SecretFromStore CONFIG/AZURE_DEVOPS/DEFAULT.TENNANT)

    static [PSCustomObject] GetByName ($name) {
        return [AzTenant]::Tenants | Where-Object { $_.Name -like $name }
    }

    [String[]] GetValidValues() {
        return   [AzTenant]::ALL.Name
    }

}
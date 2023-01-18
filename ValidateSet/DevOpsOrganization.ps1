class DevOpsOrganization : System.Management.Automation.IValidateSetValuesGenerator {

    static [String[]] $ALL = (Get-SecretStore PERSONAL).CONFIG.AZURE_DEVOPS.ORGANIZATION.ORGANIZATION
    static [String] $DEFAULT = (Get-SecretStore PERSONAL).CONFIG.AZURE_DEVOPS.ORGANIZATION.Default
    static [String] $CURRENT = (Get-SecretStore PERSONAL).CONFIG.AZURE_DEVOPS.ORGANIZATION.CURRENT

    [String[]] GetValidValues() {
        return   [DevOpsOrganization]::ALL
    }
  
}
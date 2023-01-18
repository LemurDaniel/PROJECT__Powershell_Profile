


class AzPermission : System.Management.Automation.IValidateSetValuesGenerator {

  <#
  [string] $resourceProvider
  [string] $resourceType
  [string] $operationName
  [string] $operationDisplayName
  [string] $operationDescription
  [bool] $dataAction

  AzPermission($resourceProvider, $resourceType, $operationName, $operationDisplayName, $operationDescription, $dataAction) {
    $this.resourceProvider = $resourceProvider
    $this.resourceType = $resourceType
    $this.operationName = $operationName
    $this.operationDisplayName = $operationDisplayName
    $this.operationDescription = $operationDescription
    $this.dataAction = $dataAction
  }
  #>

  static [PSCustomObject[]] $ALL = [AzPermission]::GetAllPermissions()

  static [PSCustomObject[]] GetPermissionsByProvider($Provider) {
    if ($Provider -eq [AzPermission]::ALL) {
      return [AzPermission]::GetAllPermissions()
    }
    else {      
      return ((Get-Content -Path $env:SECRET_PERMISSIONS | ConvertFrom-Csv | Group-Object -Property 'Resource Provider') | Where-Object { $_.Name -eq 'Microsoft.Compute' }).Group
    }
  }

  static [PSCustomObject[]] GetAllPermissions() {   
    return (Get-Content -Path $env:SECRET_PERMISSIONS | ConvertFrom-Csv) 
  }

  [String[]] GetValidValues() {

    $Providers = (Get-Content -Path $env:SECRET_PERMISSIONS | ConvertFrom-Csv | Group-Object 'Resource Provider' | Where-Object { [regex]::Match($_.Name, '^[A-Za-z1-9]+.{1}[A-Za-z1-9]+$').Success }) | Sort-Object -Property Count -Descending
    return @([AzPermission]::ALL) + $Providers.Name
  }

}

class PsProfile : System.Management.Automation.IValidateSetValuesGenerator {
  [String[]] GetValidValues() {
    return @(
      'Profile',
      'All'
    ) + (Get-ChildItem -Path $env:PROFILE_HELPERS_PATH -Filter '*.ps1').Name.replace('.ps1', '')
  }
}

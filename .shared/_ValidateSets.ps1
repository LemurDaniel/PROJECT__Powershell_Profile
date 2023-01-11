

class HTTPMethods : System.Management.Automation.IValidateSetValuesGenerator {

  [String[]] GetValidValues() {
    return [System.Net.Http.HttpMethod].GetProperties().Name
  }

}


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

  static [string] $ALL = 'ALL'

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
    # | Select-Object -Property {Name="AzPermission";Expression={ 
    #  return [AzPermission]::new($_."Resource Provider", $_."Resource Type", $_."Operation Name", $_."Operation Display Name", $_."Operation Description", $_."Data Action")
    # }}).AzPermission
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


class AzTenant : System.Management.Automation.IValidateSetValuesGenerator {

  static [PSCustomObject[]] $Tenants = (Get-SecretFromStore CACHE.AZURE_TENANTS)

  static [PSCustomObject[]] $Default = ([AzTenant]::Tenants | Where-Object { $_.Name -like '*baugruppe*' })

  static [PSCustomObject] GetTenantByName ($name) {
    return [AzTenant]::Tenants | Where-Object { $_.Name -like ($name -replace '_', ' ') }
  }

  [String[]] GetValidValues() {
    return   [AzTenant]::Tenants.Name -replace ' ', '_'
  }

}


class DevOpsORG : System.Management.Automation.IValidateSetValuesGenerator {

  static [String[]] GetAllORG() {
    return  Get-SecretFromStore CONFIG/AZURE_DEVOPS/ORGANIZATION.LIST
  }

  static [String] GetDefaultORG() {
    return  Get-SecretFromStore CONFIG/AZURE_DEVOPS/ORGANIZATION.DEFAULT
  }

  [String[]] GetValidValues() {
    return   [DevOpsORG]::GetAllORG()
  }
  
}

class RepoProjects : System.Management.Automation.IValidateSetValuesGenerator {

  static [string] $ALL = 'ALL'

  static [String] GetDefaultProject() {
    return Get-SecretFromStore CONFIG.AZURE_DEVOPS.DEFAULT_PROJECT
  }

  static [PSCustomObject] GetProject($projectName) {
    return Get-SecretFromStore CACHE.DEVOPS_PROJECTS | Where-Object { $_.ShortName -eq $projectName }
  }

  static [System.IO.DirectoryInfo] GetProjectPathById($projectId) {
    $projectRelative = Get-SecretFromStore CACHE.DEVOPS_PROJECTS | Where-Object { $_.id -eq $projectId }
    return [RepoProjects]::GetProjectPath($projectRelative.ShortName)
  }

  static [System.IO.DirectoryInfo] GetProjectPath($projectName) {
    $projectPath = Join-Path -Path $env:ORG_GIT_REPO_PATH -ChildPath ([RepoProjects]::GetProject($projectName).ShortName)

    if (!(Test-Path -Path $projectPath)) {
      return New-Item -ItemType Directory -Path $projectPath
    }
    else {
      return Get-Item -Path $projectPath
    }
  }

  static [PSCustomObject[]] GetRepositoriesAll() {
    return Get-SecretFromStore CACHE.DEVOPS_REPOSITORIES_ALL
  }

  static [PSCustomObject[]] GetRepositories($projectName) {
    if ($projectName -eq [RepoProjects]::ALL) {
      return [RepoProjects]::GetRepositoriesAll()
    }
    else {
      $project = Get-SecretFromStore CACHE.DEVOPS_PROJECTS | Where-Object { $_.ShortName -eq $projectName }
      return $project.Repositories
    }
  }

  static [PSCustomObject] GetRepository($repositoryId) {
    return Get-SecretFromStore CACHE.DEVOPS_REPOSITORIES_ALL | Where-Object { $_.id -eq $repositoryId }
  }

  static [System.IO.DirectoryInfo] GetRepositoryPath($repositoryId) {
    $repository = [RepoProjects]::GetRepository($repositoryId)
    $projectPath = [RepoProjects]::GetProjectPathById($repository.project.id)
    $repositoryPath = Join-Path -Path $projectPath -ChildPath $repository.Name

    if (!(Test-Path -Path $repositoryPath)) {
      return New-Item -ItemType Directory -Path $repositoryPath
    }
    else {
      return Get-Item -Path $repositoryPath
    }
  }

  [String[]] GetValidValues() {
    return   @([RepoProjects]::ALL) + (Get-SecretFromStore CACHE/DEVOPS_PROJECTS).ShortName
  }


}
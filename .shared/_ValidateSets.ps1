

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


class DevOpsOrganization : System.Management.Automation.IValidateSetValuesGenerator {

  static [String[]] $ALL = (Get-SecretFromStore CONFIG/AZURE_DEVOPS/ORGANIZATION.ORGANIZATION)
  static [String] $DEFAULT = (Get-SecretFromStore CONFIG/AZURE_DEVOPS/ORGANIZATION.DEFAULT)
  static [String] $CURRENT = (Get-SecretFromStore CONFIG/AZURE_DEVOPS/ORGANIZATION.CURRENT)

  [String[]] GetValidValues() {
    return   [DevOpsOrganization]::ALL
  }
  
}

class Project : System.Management.Automation.IValidateSetValuesGenerator {

  static [PSCustomObject[]] $ALL = (Get-SecretFromStore CACHE.DEVOPS_PROJECTS)
  static [String] $DEFAULT = (Get-SecretFromStore CONFIG/AZURE_DEVOPS/DEFAULT.PROJECT)

  static [PSCustomObject] GetByName($projectName) {
    return [Project]::ALL | Where-Object { $_.Name -like "*$projectName*" }
  }

  static [PSCustomObject] GetById($projectId) {
    return [Project]::ALL | Where-Object { $_.id -eq $projectId }
  }

  static [PSCustomObject] GetByPath($repositoryPath) {
    $repositoryPath = (git -C $repositoryPath rev-parse --show-toplevel)
    $repositoryName = $repositoryPath.split('/')[-1]
    $projectShortName = $repositoryPath.split('/')[-2]
    $organization = $repositoryPath.split('/')[-3]
    return [Project]::ALL | Where-Object { $_.shortName -eq $projectShortName }
  }

  static [System.IO.DirectoryInfo] GetPathByName($projectName) {
    $project = [Project]::GetByName($projectName).ShortName
    $projectPath = Join-Path -Path $env:ORG_GIT_REPO_PATH -ChildPath $project

    if (!(Test-Path -Path $projectPath)) {
      return New-Item -ItemType Directory -Path $projectPath
    }
    else {
      return Get-Item -Path $projectPath
    }
  }

  [String[]] GetValidValues() {
    return   @([Project]::ALL.Name)
  }

}


class Repository {

  static [PSCustomObject[]] $ALL = (Get-SecretFromStore CACHE.DEVOPS_REPOSITORIES_ALL)

  static [PSCustomObject[]] GetByProjectName($projectName) {
    $project = [Project]::GetByName($projectName)
    return [Repository]::ALL | Where-Object { $_.project.id -eq $project.id }
  }

  static [PSCustomObject] GetById($repositoryId) {
    return [Repository]::ALL | Where-Object { $_.id -eq $repositoryId }
  }

  static [System.IO.DirectoryInfo] GetRepositoryPath($repositoryId) {
    $repository = [Repository]::GetById($repositoryId)
    $projectPath = [Project]::GetPathByName($repository.project.name)
    $repositoryPath = Join-Path -Path $projectPath -ChildPath $repository.Name

    if (!(Test-Path -Path $repositoryPath)) {
      return New-Item -ItemType Directory -Path $repositoryPath
    }
    else {
      return Get-Item -Path $repositoryPath
    }
  }
}
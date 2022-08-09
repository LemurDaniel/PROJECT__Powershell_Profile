class AzPermission : System.Management.Automation.IValidateSetValuesGenerator {

  static [string] $ALL = "ALL"

  static [PSCustomObject[]] GetPermissionsByProvider($Provider) {
    if($Provider -eq [AzPermission]::ALL){
      return [AzPermission]::GetAllPermissions()
    } else {      
      return ((Get-Content -Path $env:SECRET_PERMISSIONS | ConvertFrom-Csv | Group-Object -Property "Resource Provider") | Where-Object { $_.Name -eq "Microsoft.Compute" }).Group
    }
  }

  static [PSCustomObject[]] GetAllPermissions() {   
    return (Get-Content -Path $env:SECRET_PERMISSIONS | ConvertFrom-Csv)
  }

  [String[]] GetValidValues() {

    $Providers = (Get-Content -Path $env:SECRET_PERMISSIONS | ConvertFrom-Csv | Group-Object "Resource Provider" | Where-Object { [regex]::Match($_.Name, "^[A-Za-z1-9]+.{1}[A-Za-z1-9]+$").Success }) | Sort-Object -Property Count -Descending
    return @([AzPermission]::ALL) + $Providers.Name
  }

}

class PsProfile : System.Management.Automation.IValidateSetValuesGenerator {
  [String[]] GetValidValues() {
    return @(
      "Profile",
      "All"
    ) + (Get-ChildItem -Path $env:PROFILE_HELPERS_PATH -Filter "*.ps1").Name.replace('.ps1', '')
  }
}

<#
class DevOpsDefaultCalls : System.Management.Automation.IValidateSetValuesGenerator {

}
#>

class DevOpsORG : System.Management.Automation.IValidateSetValuesGenerator {

  static [String[]] GetAllORG() {
    return Get-PersonalSecret -SecretType DEVOPS_ORGANIZATIONS
  }

  static [String] GetDefaultORG() {
    return Get-PersonalSecret -SecretType DEVOPS_DEFAULT_ORGANIZATION
  }

  [String[]] GetValidValues() {
    return   @(Get-PersonalSecret -SecretType DEVOPS_ORGANIZATIONS)
  }
  
}

class RepoProjects : System.Management.Automation.IValidateSetValuesGenerator {

  static [String] GetDefaultProject() {
    return Get-PersonalSecret -SecretType DEVOPS_DEFAULT_PROJECT
  }

  static [PSCustomObject] GetProject($projectName) {
    return (Get-PersonalSecret -SecretType DEVOPS_PROJECTS) | Where-Object { $_.ShortName -eq $projectName }
  }

  static [System.IO.DirectoryInfo] GetProjectPathById($projectId) {
    $projectRelative = (Get-PersonalSecret -SecretType DEVOPS_PROJECTS) | Where-Object { $_.id -eq $projectId }
    return [RepoProjects]::GetProjectPath($projectRelative.ShortName)
  }

  static [System.IO.DirectoryInfo] GetProjectPath($projectName) {
    $projectPath = Join-Path -Path $env:RepoPath -ChildPath ([RepoProjects]::GetProject($projectName).ShortName)

    if(!(Test-Path -Path $projectPath)) {
      return New-Item -ItemType Directory -Path $projectPath
    } else {
      return Get-Item -Path $projectPath
    }
  }

  static [PSCustomObject[]] GetRepositoriesAll() {
    return (Get-PersonalSecret -SecretType DEVOPS_REPOSITORIES_ALL)
  }

  static [PSCustomObject[]] GetRepositories($projectName) {
    $project = (Get-PersonalSecret -SecretType DEVOPS_PROJECTS) | Where-Object { $_.ShortName -eq $projectName }
    return $project.Repositories
  }

  static [PSCustomObject] GetRepository($repositoryId) {
    return (Get-PersonalSecret -SecretType DEVOPS_REPOSITORIES_ALL) | Where-Object { $_.id -eq $repositoryId }
  }

  static [System.IO.DirectoryInfo] GetRepositoryPath($repositoryId) {
      $repository = [RepoProjects]::GetRepository($repositoryId)
      $projectPath = [RepoProjects]::GetProjectPathById($repository.project.id)
      $repositoryPath = Join-Path -Path $projectPath -ChildPath $repository.Name

      if(!(Test-Path -Path $repositoryPath)) {
        return New-Item -ItemType Directory -Path $repositoryPath
      } else {
        return Get-Item -Path $repositoryPath
      }
  }

  [String[]] GetValidValues() {
    return   @("ALL") + (Get-PersonalSecret -SecretType DEVOPS_PROJECTS).ShortName
  }


}




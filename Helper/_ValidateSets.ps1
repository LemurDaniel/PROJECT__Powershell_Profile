class PsProfile : System.Management.Automation.IValidateSetValuesGenerator {
  [String[]] GetValidValues() {
    return @(
      "Profile",
      "All"
    ) + (Get-ChildItem -Path $env:PROFILE_HELPERS_PATH -Filter "*.ps1").Name.replace('.ps1', '')
  }
}

class RepoProjects : System.Management.Automation.IValidateSetValuesGenerator {

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




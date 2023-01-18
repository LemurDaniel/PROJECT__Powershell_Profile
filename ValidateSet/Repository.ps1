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
        return Join-Path -Path $env:USERPROFILE -ChildPath $repository.Localpath 
    }
}
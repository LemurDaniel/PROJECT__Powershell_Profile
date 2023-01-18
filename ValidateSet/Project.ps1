class Project : System.Management.Automation.IValidateSetValuesGenerator {

    static [PSCustomObject[]] $ALL = (
        Get-SecretFromStore CACHE.DEVOPS_PROJECTS | ForEach-Object {
            $_.Projectpath = Join-Path -Path $env:USERPROFILE -ChildPath $_.Projectpath
            return $_
        }
    )

    static [PSCustomObject] $DEFAULT = ([Project]::GetByName((Get-SecretFromStore CONFIG/AZURE_DEVOPS/DEFAULT.PROJECT)))

    static [PSCustomObject] GetByName($projectName) {
        return [Project]::ALL | Where-Object { $_.Name -like "*$projectName*" }
    }

    static [PSCustomObject] GetById($projectId) {
        return [Project]::ALL | Where-Object { $_.id -eq $projectId }
    }

    [String[]] GetValidValues() {
        return   @([Project]::ALL.Name)
    }

}
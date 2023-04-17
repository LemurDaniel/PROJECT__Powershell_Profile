$commonLintFolder = Get-Item -Path $PSScriptRoot

# Dishing out those Pull-Requests
Invoke-ScriptInAllRepositories `
    -Project 'DC Azure Migration' `
    -workitemTitle 'Integrate TFLint in Azure Pipelines' `
    -FilterBlock `
{
    param($Repositories, $Project)  
    return $Repositories | Where-Object -Property Name -Like 'terraform-*'
} `
    -ScriptBlock `
{ 
    param($Repository, $Project)  
    
    $gitIgnorePath = "$($Repository.Localpath)/.gitignore"
    if (!(Test-Path -Path $gitIgnorePath)) {
        '' | Out-File -FilePath $gitIgnorePath
    } 

    $ContentGitIgnore = Get-Content -Raw -Path $gitIgnorePath
    $ContentGitIgnore += "`n"
    $ContentGitIgnore += "`n# tflint markdownfile"
    $ContentGitIgnore += "`n*.tflint.results.md"

    $ContentGitIgnore | Out-File -FilePath $gitIgnorePath

    Get-ChildItem -Recurse -Path $Repository.Localpath -Filter '.tflint.hcl' | Remove-Item

    Copy-Item -Path "$commonLintFolder/.vscode/.tflint.config.hcl" -Destination "$($Repository.Localpath)/.vscode/.tflint.config.hcl" -Force
    Copy-Item -Path "$commonLintFolder/.vscode/settings.json" -Destination "$($Repository.Localpath)/.vscode/settings.json" -Force
    Copy-Item -Path "$commonLintFolder/.vscode/terraform-lint.ps1" -Destination "$($Repository.Localpath)/.vscode/terraform-lint.ps1" -Force

    
    $tasksJson = "$($Repository.Localpath)/.vscode/tasks.json"
    if (!(Test-Path -Path $tasksJson)) {
        @'
{
  "version": "2.0.0",
  "tasks": []
}
'@ | Out-File -FilePath $tasksJson
    }
    
    $tasksJson = Get-Item -Path $tasksJson
    $taskContent = Get-Content -Path $tasksJson | ConvertFrom-Json -Depth 99

    $taskTemplate = Get-Content -Path "$commonLintFolder/.vscode/tasks.json" | ConvertFrom-Json -Depth 99
    $taskTemplate.tasks += ($taskContent.tasks | Where-Object {
            $_.label -notin $taskTemplate.tasks.Label
        })
    $taskTemplate | ConvertTo-Json -Depth 99 | Out-File -FilePath $tasksJson
    @"
{
  // See https://go.microsoft.com/fwlink/?LinkId=733558
  // for the documentation about the tasks.json format
  $(($taskTemplate | ConvertTo-Json -Depth 99).substring(1))
"@ | Out-File -FilePath $tasksJson




    $launchJson = "$($Repository.Localpath)/.vscode/launch.json"
    if (!(Test-Path -Path $launchJson)) {
        @'
{
  "version": "0.2.0",
  "configurations": []
}
'@ | Out-File -FilePath $launchJson
    }

    $launchJson = Get-Item -Path $launchJson
    $launchContent = Get-Content -Path $launchJson | ConvertFrom-Json -Depth 99

    $launchTemplate = Get-Content -Path "$commonLintFolder/.vscode/launch.json" | ConvertFrom-Json -Depth 99
    $launchTemplate.configurations += ($launchContent.configurations | Where-Object {
            $_.label -notin $launchTemplate.configurations.Label
        }) 
    @"
{
  // Use IntelliSense to learn about possible attributes.
  // Hover to view descriptions of existing attributes.
  // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
  $(($launchTemplate | ConvertTo-Json -Depth 99).substring(1))
"@ | Out-File -FilePath $launchJson
}
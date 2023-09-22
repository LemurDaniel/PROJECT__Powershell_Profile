

<#
    .SYNOPSIS
    Search and open all github repositories that are downloaded manually
    and not via Get-GithubRepository or Get-DevOpsRepository

    .DESCRIPTION
    Search and open all github repositories that are downloaded manually
    and not via Get-GithubRepository or Get-DevOpsRepository

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS
    None

    .LINK
        
#>


function Open-Repository {

    [Alias('git-open')]
    param (
        [Parameter(
            Mandatory = $true
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $basePath = [System.String]::IsNullOrEmpty($env:GIT_RepositoryPath) ? "$env:USERPROFILE\git\repos\" : $env:GIT_RepositoryPath
                $basePath = (Get-Item -Path "$basePath\_ManualDownloads").FullName

                $repositoryPaths = Get-ChildItem -Path $basePath -Filter ".git" -Directory -Hidden -Recurse -Depth 3
                | ForEach-Object {
                    return $_.Parent.FullName.Replace($basePath, '')
                }

                return $repositoryPaths
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ }
            }
        )]
        [System.String]
        $Path,


        [Parameter(
            Mandatory = $false
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                return (Get-CodeEditor -ListAvailable).Keys
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ }
            }
        )]
        [ValidateScript(
            {
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-CodeEditor -ListAvailable).Keys
            }
        )]
        [System.String]
        $CodeEditor

    )
    
    $basePath = [System.String]::IsNullOrEmpty($env:GIT_RepositoryPath) ? "$env:USERPROFILE\git\repos\" : $env:GIT_RepositoryPath
    $targetPath = (Get-Item -Path "$basePath\_ManualDownloads\$Path").FullName

    Open-InCodeEditor -Programm $CodeEditor -Path $targetPath

}


<#
    .SYNOPSIS
    Clone github repositories at a location to find via Open-Repository

    .DESCRIPTION
    Clone github repositories at a location to find via Open-Repository

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS
    None

    .LINK
        
#>


function Invoke-GitClone {

    [Alias('git-clone')]
    param (

        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $url,

        [Parameter(
            Mandatory = $true
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $basePath = [System.String]::IsNullOrEmpty($env:GIT_RepositoryPath) ? "$env:USERPROFILE\git\repos\" : $env:GIT_RepositoryPath
                $basePath = (Get-Item -Path "$basePath\_ManualDownloads").FullName

                $validValues = (Get-ChildItem -Path $basePath -Directory).BaseName

                return $validValues
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ }
            }
        )]
        [System.String]
        $Directory,

        [Parameter(
            Mandatory = $true
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $basePath = [System.String]::IsNullOrEmpty($env:GIT_RepositoryPath) ? "$env:USERPROFILE\git\repos\" : $env:GIT_RepositoryPath
                $basePath = (Get-Item -Path "$basePath\_ManualDownloads\$($fakeBoundParameters['Directory'])").FullName
                
                $validValues = (Get-ChildItem -Path $basePath -Directory
                    | Where-Object {
                        $null -EQ (Get-ChildItem -Path $_.FullName -Filter ".git" -Directory -Hidden)
                    }
                ).BaseName

                return $validValues
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ }
            }
        )]
        [System.String]
        $SubDirectory

    )

    $Directory = [System.String]::IsNullOrEmpty($Directory) ? '.' : $Directory
    $SubDirectory = [System.String]::IsNullOrEmpty($SubDirectory) ? '.' : $SubDirectory

    $targetDirectory = [System.String]::IsNullOrEmpty($env:GIT_RepositoryPath) ? "$env:USERPROFILE\git\repos\" : $env:GIT_RepositoryPath
    $targetDirectory = "$targetDirectory\_ManualDownloads\$Directory\$SubDirectory"
    if (!(Test-Path -Path $targetDirectory)) {
        $null = New-Item -ItemType Directory -Path $targetDirectory
    }

    git -C $targetDirectory clone $url .
    
}
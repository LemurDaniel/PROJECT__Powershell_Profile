
<#
    .SYNOPSIS
    Automatically download an open a repository in VS Code.

    .DESCRIPTION
    Automatically download an open a repository in VS Code.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Fileitem with location of the repository


    .EXAMPLE

    Download an open a repository in the current DevOps-Context:

    PS> Open-Repository '<repository_name>'


    .LINK
        
#>
function Open-Repository {

    [Alias('VC')]
    [cmdletbinding()]
    param (
        # The Name of the Repository.
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'repositoryName'
        )]
        [ValidateScript(
            { 
                $_ -in (Get-ProjectInfo 'repositories.name')
            },
            ErrorMessage = 'Please specify an correct Name.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = Get-ProjectInfo 'repositories.name' 
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Name,

        # Optional download an open by id.
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'repositoryId'
        )]
        [PSCustomObject]
        $RepositoryId,

        # Optional only download the repository.
        [Parameter()]
        [switch]
        $onlyDownload
    )


    $repositories = Get-ProjectInfo 'repositories'
    if ($RepositoryId) {
        $repository = $repositories | Where-Object -Property id -EQ -Value $RepositoryId
    }
    else {
        $repository = $repositories | Where-Object -Property name -EQ -Value $Name
    }

    if (!$repository) {
        Write-Host -Foreground RED 'No Repository Found!'
        return
    }
 

    $userName = Get-CurrentUser 'displayName'
    $userMail = Get-CurrentUser 'emailAddress'

    if (!(Test-Path $repository.Localpath)) {
        New-Item -Path $repository.Localpath -ItemType Directory
        git -C $repository.Localpath clone $repository.remoteUrl .
    }      

    $item = Get-Item -Path $repository.Localpath 
    $null = git config --global --add safe.directory ($item.Fullname -replace '[\\]+', '/' )
    $null = git -C $repository.Localpath config --local commit.gpgsign false
    $null = git -C $repository.Localpath config --local user.name "$userName" 
    $null = git -C $repository.Localpath config --local user.email "$userMail"

    if (-not $onlyDownload) {
        code $repository.Localpath
    } 

    return $item
}
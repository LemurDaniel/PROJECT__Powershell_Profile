
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


    .EXAMPLE

    Open a repository from another Project in the current Organization-Context:

    PS> vc -Project '<autocompleted_projectname>' '<autocompleted_repository_name>'


    .LINK
        
#>
function Open-DevOpsRepository {

    [Alias('vc')]
    [cmdletbinding(
        DefaultParameterSetName = 'currentContext',
        SupportsShouldProcess,
        ConfirmImpact = 'high'
    )]
    param (
        # The name of the Project to swtich to in which you want to open a repository. Will default to curren tproject context.
        [Parameter(
            ParameterSetName = 'Projectspecific',
            Mandatory = $false,
            Position = 1
        )]   
        [ValidateScript(
            { 
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-OrganizationInfo).projects.name
            },
            ErrorMessage = 'Please specify a correct Projectname.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-OrganizationInfo).projects.name
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Project,



        # The Name of the Repository.
        [Parameter(
            ParameterSetName = 'Projectspecific',
            Mandatory = $true,
            Position = 0
        )]
        [Parameter(
            ParameterSetName = 'currentContext',
            Mandatory = $false,
            Position = 0
        )]   
        [ValidateScript(
            { 
                # NOTE cannot access Project when changes dynamically with tab-completion
                $true # $_ -in (Get-ProjectInfo 'repositories.name')
            },
            ErrorMessage = 'Please specify an correct Name.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = Get-ProjectInfo -Name $fakeBoundParameters['Project'] -return 'repositories.name'
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Name,


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
        $CodeEditor,


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
        $onlyDownload,

        # Optional to replace an existing repository at the location and redownload it.
        [Parameter()]
        [switch]
        $replace
    )

    if (![System.String]::IsNullOrEmpty($RepositoryId)) {
        $repository = Get-RepositoryInfo -id $RepositoryId
    }
    else {
        $repository = Get-RepositoryInfo -Project $Project -Name $Name
    }

    $userName = Get-DevOpsUser 'displayName'
    $userMail = Get-DevOpsUser 'emailAddress'


    if ($replace -AND $PSCmdlet.ShouldProcess($repository.Localpath, 'Do you want to replace any existing repository and any data in it.')) {
        if (Test-Path $repository.Localpath) {
            $null = Remove-Item -Path $repository.Localpath -Recurse -Force -Confirm:$false
        }
    }

    if (!(Test-Path $repository.Localpath)) {
        $null = New-Item -Path $repository.Localpath -ItemType Directory
        git -C $repository.Localpath clone $repository.remoteUrl .
    }      

    $item = Get-Item -Path $repository.Localpath 
    $safeDirectoyPath = ($item.Fullname -replace '[\\]+', '/' )
    $included = (git config --global --get-all safe.directory | Where-Object { $_ -eq $safeDirectoyPath } | Measure-Object).Count -gt 0
    if (!$included) {
        $null = git config --global --add safe.directory $safeDirectoyPath
    }
 
    $null = git -C $repository.Localpath config --local commit.gpgsign false
    $null = git -C $repository.Localpath config --local user.name "$userName" 
    $null = git -C $repository.Localpath config --local user.email "$userMail"

    if (-not $onlyDownload) {
        Open-InCodeEditor -Programm $CodeEditor -Path $repository.Localpath
    } 

    return $item
}
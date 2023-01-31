
<#
    .SYNOPSIS
    Automatically opens a DevOps-Repository in the Browser. Different Sites can be opened by switches.

    .DESCRIPTION
    Automatically opens a DevOps-Repository in the Browser. Different Sites can be opened by switches. 
    For easy access from cmd, without click through DevOps-Portal.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .LINK
        
#>
function Open-RepositoryInBrowser {

    [Alias('repoBrowser')]
    [cmdletbinding(
        DefaultParameterSetName = 'files',
        SupportsShouldProcess,
        ConfirmImpact = 'high'
    )]
    param (
        # The Name of the Repository. If null will default to current repository where command is executed.
        [Parameter(
            ParameterSetName = 'files',
            Mandatory = $false,
            Position = 0
        )]
        [Parameter(
            ParameterSetName = 'PullRequest',
            Mandatory = $false,
            Position = 0
        )]
        [Parameter(
            ParameterSetName = 'Branch',
            Mandatory = $false,
            Position = 0
        )]
        [Parameter(
            ParameterSetName = 'Tags',
            Mandatory = $false,
            Position = 0
        )]
        [Parameter(
            ParameterSetName = 'Commits',
            Mandatory = $false,
            Position = 0
        )]
        [Parameter(
            ParameterSetName = 'Pushes',
            Mandatory = $false,
            Position = 0
        )]
        [ValidateScript(
            { 
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-ProjectInfo 'repositories.name')
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

        # Switch to open the Active-PullRequests-Site of the repository. Default is the repository itself.
        [Alias('pr')]
        [Parameter(
            ParameterSetName = 'PullRequest'
        )]
        [switch]
        $PullRequest,

        # Switch to open the Branch-Site of the repository. Default is the Files of the repository.
        [Parameter(
            ParameterSetName = 'Branch'
        )]
        [switch]
        $Branch,

        # Switch to open the Tags-Site of the repository. Default is the Files of the repository.
        [Parameter(
            ParameterSetName = 'Tags'
        )]
        [switch]
        $Tags,

        # Switch to open the Commits-Site of the repository. Default is the Files of the repository.
        [Parameter(
            ParameterSetName = 'Commits'
        )]
        [switch]
        $Commits,

        # Switch to open the Pushes-Site of the repository. Default is the Files of the repository.
        [Parameter(
            ParameterSetName = 'Pushes'
        )]
        [switch]
        $Pushes
    )

    $repositoryUrl = Get-RepositoryInfo -name $name -return 'webUrl'

    if ($Branch) {
        $repositoryUrl = "$repositoryUrl/branches"
    }
    elseif ($Tags) {
        $repositoryUrl = "$repositoryUrl/tags"
    }
    elseif ($PullRequest) {
        $repositoryUrl = "$repositoryUrl/pullrequests?_a=active"
    }
    elseif ($Pushes) {
        $repositoryUrl = "$repositoryUrl/pushes"
    }
    elseif ($Commits) {
        $repositoryUrl = "$repositoryUrl/commits"
    }

    Start-Process $repositoryUrl

}
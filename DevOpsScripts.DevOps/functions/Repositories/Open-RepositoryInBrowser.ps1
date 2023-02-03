
<#
    .SYNOPSIS
    Automatically opens any DevOps-Repository in the Browser. Different Sites can be opened by switches.

    .DESCRIPTION
    Automatically opens a DevOps-Repository in the Browser. Different Sites can be opened by switches. 
    For easy access from cmd, without click through DevOps-Portal.
    Prepending a Projectname can open any other Project without switching context.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Open a repository in the current Project-Context (Tab for autocompletion):

    PS> Open-RepositoryInBrowser '<autocompleted_reponame>'


    .EXAMPLE

    Open a repository from another project in the current Organization-Context:

    PS> Open-RepositoryInBrowser -Project '<autocompleted_projectname>' '<autocompleted_repository_name>'

    
    .EXAMPLE

    Open the pullrequest in a repository from another project in the current Organization-Context:

    PS> Open-RepositoryInBrowser -Project '<autocompleted_projectname>' '<autocompleted_repository_name>' -PullRequest

    repoBrowser -Project 'BRZ365 Galaxy' brz365-cpm-core -PullRequest
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
        # The name of the Project to swtich to in which you want to open a repository. Will default to curren tproject context.
        [Parameter(
            ParameterSetName = 'files',
            Mandatory = $false,
            Position = 1
        )]
        [Parameter(
            ParameterSetName = 'PullRequest',
            Mandatory = $false,
            Position = 1
        )]
        [Parameter(
            ParameterSetName = 'Branch',
            Mandatory = $false,
            Position = 1
        )]
        [Parameter(
            ParameterSetName = 'Tags',
            Mandatory = $false,
            Position = 1
        )]
        [Parameter(
            ParameterSetName = 'Commits',
            Mandatory = $false,
            Position = 1
        )]
        [Parameter(
            ParameterSetName = 'Pushes',
            Mandatory = $false,
            Position = 1
        )]
        [ValidateScript(
            { 
               [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-DevOpsProjects).name
            },
            ErrorMessage = 'Please specify a correct Projectname.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-DevOpsProjects).name 
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Project,



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
                # Todo, somehow by accessing $Project in here
               $true #$_ -in (Get-ProjectInfo -Name $Project 'repositories.name')
            },
            ErrorMessage = 'Please specify a correct Repositoryname.'
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

    $repositoryUrl = Get-RepositoryInfo -Project $Project -name $name -return 'webUrl'

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
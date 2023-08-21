
<#
    .SYNOPSIS
    Gets all references of a repository or of the current repository location.

    .DESCRIPTION
    Gets all refs of a repository or of the current repository location.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    return a list of all repository refs.


    .EXAMPLE

    Gets all refs for the current repository path.

    PS> Get-RepositoryRefs


    .EXAMPLE

    Gets all refs for a Repository.

    PS> Get-RepositoryRefs -name $name


    .EXAMPLE

    Gets only branches of a Repository.

    PS> Get-RepositoryRefs -name $name -Heads

    .LINK
        
#>

function Get-RepositoryRefs {

    [CmdletBinding(
        DefaultParameterSetName = 'currentContext'
    )]
    param ( 
        # The name of the Project to swtich to in which you want to open a repository. Will default to curren tproject context.
        [Parameter(
            ParameterSetName = 'projectSpecific',
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
                $validValues = (Get-OrganizationInfo).projects.name
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Project,



        # The Name of the Repository. If null will default to current repository where command is executed.
        [Parameter(
            ParameterSetName = 'projectSpecific',
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

        # Optional switch to only return tags.
        [Parameter(Mandatory = $false)]
        [Switch]
        $Tags,

        # Optional switch to only return heads.
        [Parameter(Mandatory = $false)]
        [Switch]
        $Heads,


        # Optional switch to include statuses
        [Parameter(Mandatory = $false)]
        [Switch]
        $Statuses
    )  


    $repository = Get-RepositoryInfo -Project $Project -Name $Name
    $Request = @{
        Project = $Project
        METHOD  = 'GET'
        SCOPE   = 'PROJ'
        API     = "/_apis/git/repositories/$($repository.id)/refs?api-version=7.0"
        return  = 'value'
        query   = @{
            includeStatuses = $Statuses
            filter          = $Tags ? 'tags' : $Heads ? 'heads': $null
        } 
    }

    return Invoke-DevOpsRest @Request 
}

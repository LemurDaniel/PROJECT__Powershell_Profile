
<#
    .SYNOPSIS
    Creates a new Branch in the Current Repository, based on a workitem assigned to the current user.

    .DESCRIPTION
    Creates a new Branch in the Current Repository, based on a workitem assigned to the current user.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Create a new Branch in the current repository from a workitem:

    PS> New-BranchFromWorkitem '<item_from_autocomplete>'


    .LINK
        
#>

function New-BranchFromWorkitem {

    [Alias('gitW')]
    [cmdletbinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param (
        # Autocomplete list for workitems assigned to the user.
        [Parameter(
            ParameterSetName = 'Projectspecific',
            Mandatory = $true,
            Position = 0
        )]
        [Parameter(
            ParameterSetName = 'CurrentContext',
            Mandatory = $true,
            Position = 0
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = Search-WorkItemInIteration -SearchTags '*' -Current -Personal -return 'fields.System.Title'  

                $validValues | `
                    ForEach-Object { $_ } | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $workitemTitle,


        # The name of the Project to swtich to in which you want to open a repository. Will default to curren tproject context.
        [Parameter(
            ParameterSetName = 'Projectspecific',
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



        # The Name of the Repository.
        [Parameter(
            ParameterSetName = 'Projectspecific',
            Mandatory = $true,
            Position = 2
        )]
        [Parameter(
            ParameterSetName = 'currentContext',
            Mandatory = $false,
            Position = 2
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
        $Name

    )    

    $repositoryPath = Get-Location

    if ($PSBoundParameters.ContainsKey('Project') -OR $PSBoundParameters.ContainsKey('Name')) {
        $repository = Get-RepositoryInfo -Project $Project -Name $Name
        $repositoryPath = $repository.Localpath
    }

    if (!(Test-IsRepository -Path $repositoryPath)) {
        throw 'Please exexcute command inside a Repository'
    }

    $workItem = Search-WorkItemInIteration -Current -Personal -Single -SearchTags $workitemTitle
    $transformedTitle = $workItem.fields.'System.Title'.toLower() -replace '[?!:\/\\\-\s]+', '_' -replace '[\[\]]+', '__'
    $branchName = "features/$($workItem.id)-$transformedTitle"
        
    git -C $repositoryPath checkout master
    git -C $repositoryPath pull origin master
    git -C $repositoryPath checkout dev
    git -C $repositoryPath pull origin dev


    $branchExists = (git -C . branch | ForEach-Object { $_ -like "*$branchName*" } | Measure-Object).Count -gt 0
    if ($branchExists) {
        $menuPoll = Select-ConsoleMenu -Property display -Description "A Branch with the name '$branchName' already exists! \nPlease choose an action." -options @(
            @{ option = 0; display = 'Switch to existing Branch' },    
            @{ option = 1; display = 'Remove and Replace existing Branch' }
        )

        if ($menuPoll.option -eq 0) {
            git -C $repositoryPath checkout "$branchName"
        }
        elseif ($menuPoll.option -eq 1) {
            git -C $repositoryPath branch -Df "$branchName"
            git -C $repositoryPath checkout -B "$branchName"
        }
    }
    else {
        git -C $repositoryPath checkout -b "$branchName"
    }

} 
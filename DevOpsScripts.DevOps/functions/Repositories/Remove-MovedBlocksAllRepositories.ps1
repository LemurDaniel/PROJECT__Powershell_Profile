
<#
    .SYNOPSIS

    .DESCRIPTION

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None.


    .LINK
        
#>

function Remove-MovedBlocksAllRepositories {

    [cmdletbinding(
        SupportsShouldProcess,
        ConfirmImpact = 'high'
    )]
    param (
        # Autocomplete list for workitems assigned to the user.
        [Parameter(
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


        # The name of the project, if not set default to the Current-Project-Context.
        [Parameter(
            ParameterSetName = 'projectSpecific',
            Mandatory = $false,
            Position = 1
        )]
        [ValidateScript(
            { 
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-DevOpsProjects).name
            },
            ErrorMessage = 'Please specify an correct Name.'
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
        $Project
    )

    $projectTarget = Get-ProjectInfo -Name $Project
    $projectTarget.repositories | ForEach-Object {
    
        Write-Host
        Write-Host -ForegroundColor Yellow "Checking '$($_.Name)'"
        Write-Host
        $path = Open-Repository -Project $projectTarget.name -Name $_.name -onlyDownload

        git -C $path.FullName stash
        git -C $path.FullName checkout master
        git -C $path.FullName pull origin master
        Remove-MovedBlocks -Path $path.FullName

        $count = git -C $path.FullName status --porcelain | Measure-Object | Select-Object -ExpandProperty Count
        if ($count -gt 0) {
    
            Write-Host -ForegroundColor Yellow "Found Moved Blocks in Repository '$($_.name)' in '$($projectTarget.name)'"
            if ($PSCmdlet.ShouldProcess($_.Name , 'Create Feature Pull Request?')) {

                New-BranchFromWorkitem -Project $_.project.name -Name $_.name -workitemTitle $workitemTitle
                git -C $path.FullName add -A
                git -C $path.FullName commit -m 'AUTO--Remove terraform moved blocks'
                git -C $path.FullName push
                New-PullRequest -PRtitle 'AUTO--Remove terraform moved blocks' -Source 'current' -Target 'dev' `
                    -Project ($_.project.name) -RepositoryName $_.name -autocompletion

                    
                if ($PSCmdlet.ShouldProcess($_.Name , 'Create additional Pull Request from dev to Master?')) {
                    New-PullRequest -PRtitle 'AUTO--Remove terraform moved blocks' -Source 'dev' -Target 'default' `
                        -Project ($_.project.name) -RepositoryName $_.name
                }
            }
        }

    }
}


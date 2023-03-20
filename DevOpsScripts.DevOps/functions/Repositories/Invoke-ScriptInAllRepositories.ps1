
<#
    .SYNOPSIS
    Invokes a script block accross all repositories in a project an creates Pull Requests on Changes.

    .DESCRIPTION
    Invokes a script block accross all repositories in a project an creates Pull Requests on Changes.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None.


    .LINK
        
#>

function Invoke-ScriptInAllRepositories {

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
            Mandatory = $false
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
        $Project,

        # The script block to invoke in every repository
        [Parameter(
            Mandatory = $true
        )]
        [System.Management.Automation.ScriptBlock]
        $ScriptBlock
    )

    $projectTarget = Get-ProjectInfo -Name $Project
    $projectTarget.repositories | ForEach-Object {
    
        Write-Host
        Write-Host '---------------------------------------------------------------------------'

        $path = Open-Repository -Project $projectTarget.name -Name $_.name -onlyDownload

        Write-Host
        Write-Host -ForegroundColor Yellow "Processing '$($_.Name)' in '$($_.project.name)'"
        Write-Host

        $randomHex = New-RandomBytes -Type Hex -Bytes 2
        $stashName = "$workItemTitle-$randomHex" -replace '\s', '_' -replace '[^\sA-Za-z0-9\\-]*', ''
        git -C $path.FullName stash push -m $stashName
        git -C $path.FullName checkout master
        git -C $path.FullName pull origin master

        & $ScriptBlock -Repository $_ -Project $_.project

        if ((git -C $path.FullName status --porcelain | Measure-Object).Count -gt 0) {
    
            Write-Host -ForegroundColor Yellow "Detected Changes in Repository '$($_.name)' in '$($projectTarget.name)'"
            if ($PSCmdlet.ShouldProcess($_.Name , 'Create Feature Pull Request?')) {
          
                New-BranchFromWorkitem -Project $_.project.name -Name $_.name -workitemTitle $workitemTitle
                git -C $path.FullName add -A
                git -C $path.FullName commit -m "AUTO--$workitemTitle"
                git -C $path.FullName push
                New-PullRequest -PRtitle "AUTO--$workitemTitle" -Source 'current' -Target 'dev' `
                    -Project ($_.project.name) -RepositoryName $_.name -autocompletion
            }

            if ($PSCmdlet.ShouldProcess($_.Name , 'Create Master Pull Request?')) {
                New-PullRequest -PRtitle "AUTO--$workitemTitle" -Source 'dev' -Target 'default' `
                    -Project ($_.project.name) -RepositoryName $_.name
            }
        }

        git stash apply "stash^{/$stashName}"
    }
}



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

function Invoke-ScriptInRepositories {

    [cmdletbinding(
        DefaultParameterSetName = 'fromProject',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'high'
    )]
    param (
        # Repositories to iterate over
        [Parameter(
            ParameterSetName = 'fromPipeline',
            ValueFromPipeline = $true,
            Mandatory = $true,
            Position = 0
        )]
        [System.Object]
        $Repository,

        # The name of the project, if not set default to the Current-Project-Context.
        [Parameter(
            ParameterSetName = 'fromProject',
            Mandatory = $true,
            Position = 0
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
                $validValues = (Get-OrganizationInfo).projects.name
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Project,

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

        # The script block to invoke in every repository
        [Parameter(
            Mandatory = $true
        )]
        [System.Management.Automation.ScriptBlock]
        $ScriptBlock
    )

    BEGIN {}

    PROCESS {
   
        if ($PSBoundParameters.ContainsKey('Project')) {
            $null = $PSBoundParameters.Remove('Project')
            return (Get-ProjectInfo -Name $Project).repositories 
            | Sort-Object -Property name 
            | Invoke-ScriptInRepositories @PSBoundParameters
        }


        Write-Host
        Write-Host '---------------------------------------------------------------------------'

        $path = Open-Repository -Project $repository.project.name -Name $repository.name -onlyDownload
        
        Write-Host
        Write-Host -ForegroundColor Yellow "Processing '$($repository.Name)' in '$($repository.project.name)'"
        Write-Host

        $randomHex = New-RandomBytes -Type Hex -Bytes 2
        $stashName = "$workItemTitle-$randomHex" -replace '\s', '_' -replace '[^\sA-Za-z0-9\\-]*', ''
  
        git -C $path.FullName add -A
        git -C $path.FullName stash push -m $stashName
        git -C $path.FullName checkout master
        git -C $path.FullName pull origin master

        & $ScriptBlock -Repository $repository -Project $repository.project

        if ((git -C $path.FullName status --porcelain | Measure-Object).Count -gt 0) {
    
            Write-Host -ForegroundColor Yellow "Detected Changes in Repository '$($repository.name)' in '$($repository.project.name)'"
                        
            if ($PSCmdlet.ShouldProcess($repository.Name , 'Open repository for addition changes')) {
                $null = Open-Repository -Project $repository.project.name -Name ($repository.name)
            }
            
            if ($PSCmdlet.ShouldProcess($repository.Name , 'Create Feature Pull Request?')) {
          
                New-BranchFromWorkitem -Project $repository.project.name -Name $repository.name -workitemTitle $workitemTitle
                git -C $path.FullName add -A
                git -C $path.FullName commit -m "AUTO--$workitemTitle"
                git -C $path.FullName push
                New-PullRequest -PRtitle "AUTO--$workitemTitle" -Source 'current' -Target 'dev' `
                    -Project ($repository.project.name) -RepositoryName $repository.name -autocompletion -deleteSourceBranch
            
                if ($PSCmdlet.ShouldProcess($repository.Name , 'Create Master Pull Request?')) {
                    New-PullRequest -PRtitle "AUTO--$workitemTitle" -Source 'dev' -Target 'default' `
                        -Project ($repository.project.name) -RepositoryName $repository.name -autocompletion
                }
            } 
            else {
                git -C $path.FullName reset --hard
            }

        }

        git -C $path.FullName stash apply "stash^{/$stashName}" 2>$null
      
    }

    END {}
}


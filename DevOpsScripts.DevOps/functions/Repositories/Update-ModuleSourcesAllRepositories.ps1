<#
    .SYNOPSIS
    Update all terraform-submodule sources in all locations. (DC Migration specific)

    .DESCRIPTION
    Update all terraform-submodule sources in all locations. (DC Migration specific)

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None.

    .LINK
        
#>
function Update-ModuleSourcesAllRepositories {

    [cmdletbinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'high'
    )]
    param (
        # Refresh cached values.
        [Parameter()]
        [switch]
        $refresh = $false
    )

    if ((Get-DevOpsContext -Project) -ne 'DC Azure Migration') {
        throw 'Set Context to DC Azure Migration'
    }
    

    #Referenced By other Modules
    $moduleUpdatesRequired = @(
        'terraform-azurerm-acf-naming',
        'terraform-azurerm-acf-monitoring'
    )

    # Require feature branch and fetch Versions again.
    $EnteredNonModules = $false
    $nonModules = @(
        'terraform-acf-main',
        'terraform-acf-adds',
        'terraform-acf-launchpad'
    )


    $null = Get-RecentSubmoduleTags -refresh:($refresh)
    $allTerraformRepositories = Get-ProjectInfo -return 'repositories' | Where-Object -Property name -Like '*terraform*' 

    $sortedLast = $allTerraformRepositories | Where-Object -Property name -In $nonModules | Sort-Object -Property { $nonModules.IndexOf($_.name) }
    $sortedFirst = $allTerraformRepositories | Where-Object -Property name -In $moduleUpdatesRequired | Sort-Object -Property { $moduleUpdatesRequired.IndexOf($_.name) }
    $terraformOther = $allTerraformRepositories | Where-Object -Property name -NotIn $moduleUpdatesRequired | Where-Object -Property name -NotIn $nonModules

    $repositoriesInOrder = $sortedFirst + $terraformOther + $sortedLast

    foreach ($repository in $repositoriesInOrder) {

        if (!$EnteredNonModules -AND $repository.Name -in $nonModules) {
            Write-Host "`n---------------------------------------------------------------`n"
            Write-Host -ForegroundColor Red '   Fnished Processing all Modules'
            Write-Host -ForegroundColor Red '   The script will fetch all tags again!'
            Write-Host "`n---------------------------------------------------------------`n"
            $null = Get-RecentSubmoduleTags -refresh
        }
    
        Write-Host "`n------------------------------`n"
        Write-Host -ForegroundColor Yellow "Searching Respository '$($repository.name)' locally"
        $null = Open-Repository -Name ($repository.name) -onlyDownload

        Write-Host -ForegroundColor Yellow "Update Master and Dev Branch '$($repository.name)'"
        $repoRefs = Get-RepositoryRefs -Project $repository.project.name -Name $repository.Name | `
            Where-Object -Property name -In @('refs/heads/dev' , 'refs/heads/main' , 'refs/heads/master' ) | `
            Sort-Object { @('dev', 'main', 'master').IndexOf($_.name.split('/')[-1]) }
          
        git -C $repository.Localpath checkout ($repoRefs[0].name -split '/')[-1]
        git -C $repository.Localpath pull



        Write-Host -ForegroundColor Yellow 'Search and Replace Submodule Source Paths'
        $replacements = Update-ModuleSourcesInPath -replacementPath ($repository.Localpath) -Confirm:$false

        # Case when feature branch is needed
        if ($replacements.Count -ne 0 -AND $nonModules.Contains($repository.name)) {
        
            if ($PSCmdlet.ShouldProcess($repository.Name , 'Create Pull Request')) {
                Write-Host -ForegroundColor Yellow 'Create Feature Branch and create Pull Request'
                git -C $repository.Localpath checkout -B features/AUTO__Update-Submodule-source-path
                git -C $repository.Localpath add -A
                git -C $repository.Localpath commit -m 'AUTO--Update Submodule Source Paths'
                git -C $repository.Localpath push origin features/AUTO__Update-Submodule-source-path
        
                if ($repoRefs[0].name.contains('dev')) {
                    New-PullRequest -PRtitle 'DEV - AUTO--Update Submodule Source Paths' -Target 'dev' `
                        -Id ($repository.id) -Path ($repository.Localpath) #-projectName ($repository.remoteUrl.split('/')[4])
                }
                else {
                    New-PullRequest -PRtitle 'DEV - AUTO--Update Submodule Source Paths' -Target 'default' `
                        -Id ($repository.id) -Path ($repository.Localpath) #-projectName ($repository.remoteUrl.split('/')[4])
                }
            }
            else {
                Write-Host -ForegroundColor Red "`n The Script will exit now! `n"
                return 
            }

        }

        # Case when no feature branch is needed
        if ($replacements.Count -ne 0 -AND !$nonModules.Contains($repository.name)) {
        
            Write-Host -ForegroundColor Yellow 'Update Dev Branch and create Pull Request'
            git -C $repository.Localpath checkout -B dev
            git -C $repository.Localpath add -A
            git -C $repository.Localpath commit -m 'AUTO--Update Submodule Source Paths'
            git -C $repository.Localpath push origin dev
        
            New-PullRequest -PRtitle 'DEV - AUTO--Update Submodule Source Paths' -Target 'default' `
                -Id ($repository.id) -Path ($repository.Localpath) #-projectName ($repository.remoteUrl.split('/')[4])

        }
    

     
        if ($repository.Name -in $moduleUpdatesRequired) {
            Write-Host "`n---------------------------------------------------------------`n"
            Write-Host -ForegroundColor Red "   '$($repository.Name)' is referenced by Successor-Modules."
            Write-Host -ForegroundColor Red '   Please update the Module before proceeding.'
            Write-Host -ForegroundColor Red '   The script will fetch all tags again!'
            Write-Host "`n---------------------------------------------------------------`n"

            if ($PSCmdlet.ShouldProcess('Update Module Tags Cache')) {
                $null = Get-RecentSubmoduleTags -refresh
            }
            else {
                Write-Host -ForegroundColor Red "`n The Script will exit now! `n"
                return 
            }
        }
       
    }
}
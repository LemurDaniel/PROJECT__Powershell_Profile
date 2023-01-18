function Update-ModuleSourcesAllRepositories {
    param (
        [Parameter()]
        [switch]
        $forceApiCall = $false
    )
    
    # Peform regex on following last
    $sortOrder = @(
        'terraform-acf-main',
        'terraform-acf-adds',
        'terraform-acf-launchpad'
    )

    $forceFeatureBranch = @(
        'terraform-acf-main',
        'terraform-acf-adds',
        'terraform-acf-launchpad'
    )



    $null = Get-RecentSubmoduleTags -forceApiCall:($forceApiCall)
    $allTerraformRepositories = Get-ProjectInfo 'repositories' | `
        Where-Object { $_.name.contains('terraform') } | `
        Sort-Object -Property { $sortOrder.IndexOf($_.name) }


    foreach ($repository in $allTerraformRepositories) {
    
        Write-Host -ForegroundColor Yellow "Searching Respository '$($repository.name)' locally"
        $null = Open-Repository -repositoryName ($repository.name) -onlyDownload

        Write-Host -ForegroundColor Yellow "Update Master and Dev Branch '$($repository.name)'"
        $repoRefs = Get-RepositoryRefs -repositoryId $repository.id | `
            Where-Object { $_.name.contains('dev') -OR $_.name.contains('main') -OR $_.name.contains('master') } | `
            Sort-Object { @('dev', 'main', 'master').IndexOf($_.name.split('/')[-1]) }
          
        git -C $repository.Localpath checkout ($repoRefs[0].name -split '/')[-1]
        git -C $repository.Localpath pull



        Write-Host -ForegroundColor Yellow 'Search and Replace Submodule Source Paths'
        $replacements = Update-ModuleSourcesInPath -replacementPath ($repository.Localpath) -Confirm:$false

        if ($replacements.Count -eq 0) {
            continue;
        }



        
        # Case when feature branch is needed
        if ($forceFeatureBranch.Contains($repository.name)) {
        
            Write-Host -ForegroundColor Yellow 'Create Feature Branch and create Pull Request'
            git -C $repository.Localpath checkout -B features/AUTO__Update-Submodule-source-path
            git -C $repository.Localpath add -A
            git -C $repository.Localpath commit -m 'AUTO--Update Submodule Source Paths'
            git -C $repository.Localpath push origin features/AUTO__Update-Submodule-source-path
        
            if ($repoRefs[0].name.contains('dev')) {
                New-PullRequest -PRtitle 'DEV - AUTO--Update Submodule Source Paths' -Target 'dev' `
                    -repositoryId ($repository.id) -repositoryPath ($repository.Localpath) -projectName ($repository.remoteUrl.split('/')[4])
            }
            else {
                New-PullRequest -PRtitle 'DEV - AUTO--Update Submodule Source Paths' -Target 'default' `
                    -repositoryId ($repository.id) -repositoryPath ($repository.Localpath) -projectName ($repository.remoteUrl.split('/')[4])
            }

        }
        else {
        
            Write-Host -ForegroundColor Yellow 'Update Dev Branch and create Pull Request'
            git -C $repository.Localpath checkout -B dev
            git -C $repository.Localpath add -A
            git -C $repository.Localpath commit -m 'AUTO--Update Submodule Source Paths'
            git -C $repository.Localpath push origin dev
        
            New-PullRequest -PRtitle 'DEV - AUTO--Update Submodule Source Paths' -Target 'default' `
                -repositoryId ($repository.id) -repositoryPath ($repository.Localpath) -projectName ($repository.remoteUrl.split('/')[4])

        }
    }
}
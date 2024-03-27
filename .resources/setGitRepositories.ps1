


$path = (Get-Location).Path
Get-GitRepositories -Account 'Loro Play' -Context adesso
| Where-Object {
    $_.Name -match 'LoroPlay[.].*Function' `
    #    -OR $_.Name.Contains('SignalRHub') `
    #    -OR $_.Name.Contains('Voucher.Api') `
    #    -OR $_.Name.Contains('CrossDomain') `
    #    -OR $_.Name.Contains('ScratchGames') `
    #    -OR $_.Name.Contains('Health') `
    #    -OR $_.Name.Contains('Sport') `
    #    -OR $_.Name.Contains('CMS')
}
| Invoke-GitScriptInRepositories `
    -ScriptBlock {
    param($Repository, $Identifier) 

    Write-Host $Repository.full_name

    $releaseBranch = Get-GitBranch @Identifier
    | Where-Object -Property name -Match 'release/*'
    | Sort-Object {
        [version]::new(($_.name.replace('release/', '').replace('x', '0')))
    } -Descending
    | Select-Object -First 1

    git -C $Repository.LocalPath checkout $releaseBranch.name
    git -C $Repository.LocalPath pull

    $item = Get-Item "$($Repository.LocalPath)\.github\workflows\release.deploy.yaml" 
    (($item | Get-Content) -replace '\s+-\s+prod', '') | Out-File $item.FullName

    $item = Get-Item "$($Repository.LocalPath)\.github\aks.templates\prod.template.deployment.yaml" 
    (($item | Get-Content) -replace '\s+replicas:\s+\d+', '') | Out-File $item.FullName

    Get-Content "$Path\pipelines\release.prod.deploy.yaml"
    | Out-File "$($Repository.LocalPath)\.github\workflows\release.deploy.prod.yaml" 

    Get-Content "$Path\pipelines\release.prod.verify.yaml"
    | Out-File "$($Repository.LocalPath)\.github\workflows\release.verify.prod.yaml"

    git -C $Repository.LocalPath add -A
    git -C $Repository.LocalPath commit -m "production release pipeline"
    git -C $Repository.LocalPath push
    git -C $Repository.LocalPath branch -D 'main'
    git -C $Repository.LocalPath checkout -B 'main'
    git -C $Repository.LocalPath push origin 'main' --force

    git -C $Repository.LocalPath checkout $releaseBranch.name

    Get-Content "$Path\pipelines\release.create.yaml"
    | Out-File "$($Repository.LocalPath)\.github\workflows\release.create.yaml"

    git -C $Repository.LocalPath add -A
    git -C $Repository.LocalPath commit -m "production release pipeline"

    git -C $Repository.LocalPath checkout 'dev'
    git -C $Repository.LocalPath merge $releaseBranch.name
    git -C $Repository.LocalPath push origin 'dev'

    Deploy-GitSecretsTemplate @Identifier -Name LoRo.Repo.Default

    $BranchProtection = @{
        Branch                    = 'main'
        ConverstionResolution     = $true
        RequireStatusChecks       = @{
            strict = $true
            checks = @()
        }
        RequirePullRequestReviews = @{
            dismiss_stale_reviews           = $true
            required_approving_review_count = 1
            require_last_push_approval      = $true
        }
    }
    Set-GitBranchProtection @Identifier @BranchProtection
}
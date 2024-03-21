

Get-GitRepositories -Account 'Loro Play' -Context adesso
| Where-Object {
    $_.Name -match 'LoroPlay[.].*Function' `
        -OR $_.Name.Contains('SignalRHub') `
        -OR $_.Name.Contains('Voucher.Api') `
        -OR $_.Name.Contains('CrossDomain') `
        -OR $_.Name.Contains('ScratchGames') `
        -OR $_.Name.Contains('Health') `
        -OR $_.Name.Contains('Sport') `
        -OR $_.Name.Contains('CMS')
}
| Invoke-GitScriptInRepositories `
    -Message "Test" `
    -PullRequestTitle "Test" `
    -ScriptBlock {
    param($Repository, $Identifier) 


    Write-Host $Repository.full_name

    Deploy-GitSecretsTemplate @Identifier -Name LoRo.Repo.Default

    $BranchProtection = @{
        Branch                      = 'main'
        ConverstionResolution       = $true
        RequireStatusChecks         = @{
            strict = $true
            checks = @()
        }
        RequirePullRequestReviews = @{
            dismiss_stale_reviews           = $true
            required_approving_review_count = $true
            require_last_push_approval      = $true
        }
    }
    Set-GitBranchProtection @Identifier @BranchProtection
}
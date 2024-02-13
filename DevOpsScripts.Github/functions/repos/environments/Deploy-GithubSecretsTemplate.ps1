<#
    .SYNOPSIS
    Adds secrets to an repository according to the template.

    .DESCRIPTION
    Adds secrets to an repository according to the template.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None

    .LINK
#>

function Deploy-GithubSecretsTemplate {

    [CmdletBinding()]
    param (
        # The name of the github account to use. Defaults to current Account.
        [Parameter(
            Position = 3,
            Mandatory = $false
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Account' })]
        [System.String]
        [Alias('a')]
        $Account,

        # The Name of the Github Context to use. Defaults to current Context.
        [Parameter(
            Mandatory = $false,
            Position = 2
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Context' })]
        [System.String]
        [Alias('c')]
        $Context,

        # The Name of the Github Repository. Defaults to current Repository.
        [Parameter(
            Mandatory = $false,
            Position = 1
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Repository' })]
        [System.String]
        [Alias('r')]
        $Repository,


        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args -alias 'SecretsTemplate' })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'SecretsTemplate' })]
        [System.String]
        $Name
    )

    $templateFile = Get-GithubSecretsTemplate -Name $Name -AsPlainText | ConvertFrom-Json -AsHashtable
    $repositoryData = Get-GithubRepositoryInfo -Account $Account -Context $Context -Repository $Repository
    $repositoryInfo = @{
        Account    = $repositoryData.Account
        Context    = $repositoryData.Context
        Repository = $repositoryData.Repository
    }
    
    Set-GithubSecret -Secrets $templateFile['repository_secrets'] @repositoryInfo
    Set-GithubVariable -Variables $templateFile['repository_variables'] @repositoryInfo
   
    $environments = Get-GithubEnvironments @repositoryInfo
    $environmentNames = @()
    $environmentNames += $templateFile['environment_secrets'].environment_name
    $environmentNames += $templateFile['environment_variables'].environment_name

    $environmentNames 
    | Sort-Object | Get-Unique
    | ForEach-Object {
        if ($_ -notin $environments.name) {
            Write-Host -ForeGroundColor GREEN "Create Environment '$($_)'"
            $null = Set-GithubEnvironment -Name $_ @repositoryInfo
        }
    }

    $templateFile['environment_secrets'] 
    | ForEach-Object {
        Write-Host -ForeGroundColor GREEN "-- Setting Environment Secrets '$($_.environment_name)'"
        Set-GithubSecret -Environment $_.environment_name -Secrets $_.secrets @repositoryInfo
    }
    $environments = Get-GithubEnvironments @repositoryInfo
    $templateFile['environment_variables'] 
    | ForEach-Object {
        Write-Host -ForeGroundColor GREEN "-- Setting Environment Variables '$($_.environment_name)'"
        Set-GithubVariable -Environment $_.environment_name -Variables $_.variables @repositoryInfo
    }
}

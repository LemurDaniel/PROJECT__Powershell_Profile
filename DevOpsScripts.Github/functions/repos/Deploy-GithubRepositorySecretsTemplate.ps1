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

function Deploy-GithubRepositorySecretsTemplate {

    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = Get-GithubRepositorySecretsTemplate -ListAvailable
                
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [validateScript(
            {
                $_ -in (Get-GithubRepositorySecretsTemplate -ListAvailable)
            }
        )]
        [System.String]
        $Name,

        [Parameter(
            Position = 4,
            Mandatory = $false
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-GithubAccountContext -ListAvailable).name
                
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [validateScript(
            {
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-GithubAccountContext -ListAvailable).name
            }
        )]
        [Alias('a')]
        $Account,

        # The Name of the Github Context to use. Defaults to current Context.
        [Parameter(
            Mandatory = $false,
            Position = 3
        )]
        [ValidateScript(
            { 
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-GithubContexts -Account $PSBoundParameters['Account']).login
            },
            ErrorMessage = 'Please specify an correct Context.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)
                $validValues = (Get-GithubContexts -Account $fakeBoundParameters['Account']).login
        
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        [Alias('c')]
        $Context,

        
        # The Name of the Github Repository.
        [Parameter(
            Mandatory = $false,
            Position = 1
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)
                $Context = Get-GithubContextInfo -Account $fakeBoundParameters['Account'] -Context $fakeBoundParameters['Context']
                $validValues = $Context.repositories.Name

                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        [Alias('r')]
        $Repository
    )

    $templateFile = Get-GithubRepositorySecretsTemplate -Name $Name -AsPlainText | ConvertFrom-Json -AsHashtable
    $repositoryInfo = @{
        Account    = $Account
        Context    = $Context
        Repository = $Repository
    }
    
    Set-GithubRepositorySecret -Secrets $templateFile['repository_secrets'] @repositoryInfo
   
    $environments = Get-GithubEnvironments @repositoryInfo
    $templateFile['environment_secrets'] 
    | ForEach-Object {
        if ($_.environment_name -notin $environments.name) {
            Write-Host -ForeGroundColor GREEN "Create Environment '$($_.environment_name)'"
            $null = Set-GithubEnvironment -Name $_.environment_name @repositoryInfo
        }

        Set-GithubRepositorySecret -Environment $_.environment_name -Secrets $templateFile['repository_secrets'] @repositoryInfo
    }

}

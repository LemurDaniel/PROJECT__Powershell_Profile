<#
    .SYNOPSIS
    Adds or Updates a Variable in a Github-Repository via API.

    .DESCRIPTION
    Adds or Updates a Variable in a Github-Repository via API.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Adding/Updating a secret to the repository on the current path:

    PS> Set-GithubRepositorySecret -Name "VariableName" -Value "Value"

    .EXAMPLE

    Adding/Updating multiple secrets to the repository on the current path:

    PS> Set-GithubRepositorySecret -Variables @{
        Secret1 = "Value1"
        Secret2 = "Value2"
    }

    .EXAMPLE

    Adding/Updating a secret in a specific environment in the repository on the current path:

    PS> Set-GithubRepositorySecret -Environment dev -Name "VariableName" -Value "Value"

    .EXAMPLE

    Adding/Updating multiple secrets in a specific environment in the repository on the current path:

    PS> Set-GithubRepositorySecret -Environment dev -Secrets @{
        Secret1 = "SecretValue"
        Secret2 = "SecretValue"
    }

    .LINK
        
#>

function Set-GithubRepositoryVariable {

    [CmdletBinding(
        DefaultParameterSetName = "Single"
    )]
    param (
        [Parameter(
            Position = 3,
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
            Position = 2
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
            Position = 0
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
        $Repository,



        # The Environment to set the secret in. Leaving this empty creates a Repository Secret.
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Environment,

        # The name of the secret.
        [Parameter(
            Mandatory = $true,
            ParameterSetName = "Single"
        )]
        [System.String]
        $Name,

        # The value of the secret.
        [Parameter(
            Mandatory = $true,
            ParameterSetName = "Single"
        )]
        [System.String]
        $Value,

        # The hashtable of secret names and values to add to the repository.
        [Parameter(
            Mandatory = $true,
            ParameterSetName = "Hashtable"
        )]
        [System.Collections.Hashtable]
        $Variables
    )

    $repositoryData = Get-GithubRepositoryInfo -Account $Account -Context $Context -Name $Repository

    if (!$PSBoundParameters.ContainsKey("Variables")) {
        $Variables = [System.Collections.Hashtable]::new()
        $null = $Variables.add($Name, $Value)
    }


    $remoteUrl = "/repos/$($repositoryData.full_name)/actions/variables"
    if (![System.String]::IsNullOrEmpty($Environment)) {
        $remoteUrl = "/repositories/$($repositoryData.id)/environments/$Environment/variables"
    }

    $existingVariables = Invoke-GithubRest -API $remoteUrl -Account $Account

    $Variables.GetEnumerator() 
    | ForEach-Object {

        $Request = @{
            METHOD  = $null
            API     = $remoteUrl
            Account = $repositoryData.Account
            Body    = @{
                name  = $_.Key
                value = $_.Value
            }
        }

        if ($_.Key -in $existingVariables.variables.name) {
            $Request.METHOD = "PATCH"
            $Request.API = "$remoteUrl/$($_.Key)"
            Write-Host -ForegroundColor GREEN "Updating Variable '$($_.Key)'"
        }
        else {
            $Request.METHOD = "POST"
            Write-Host -ForegroundColor GREEN "Adding Variable '$($_.Key)'"
        }

        $null = Invoke-GithubRest @Request
    }
    
}
<#
    .SYNOPSIS
    Adds or Updates a Secret to a Github-Repository via API.

    .DESCRIPTION
    Adds or Updates a Secret to a Github-Repository via API.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Adding/Updating a secret to the repository on the current path:

    PS> Set-GithubRepositorySecret -Name "Secret" -Value "SecretValue"

    .EXAMPLE

    Adding/Updating multiple secrets to the repository on the current path:

    PS> Set-GithubRepositorySecret -Secrets @{
        Secret1 = "SecretValue"
        Secret2 = "SecretValue"
    }

    .EXAMPLE

    Adding/Updating a secret in a specific environment in the repository on the current path:

    PS> Set-GithubRepositorySecret -Environment dev -Name "Secret" -Value "SecretValue"

    .EXAMPLE

    Adding/Updating multiple secrets in a specific environment in the repository on the current path:

    PS> Set-GithubRepositorySecret -Environment dev -Secrets @{
        Secret1 = "SecretValue"
        Secret2 = "SecretValue"
    }

    .LINK
        
#>

function Set-GithubRepositorySecret {

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
        $Secrets

    )

    $repositoryData = Get-GithubRepositoryInfo -Account $Account -Context $Context -Name $Repository


    # Not working. Bad IL-Format
    # # Install sodium
    # if ($null -EQ (Get-Package -Name Sodium.Core -ErrorAction SilentlyContinue)) {
    #     Write-Host "...Installing Sodium.Core"
    #     Install-Package -Name Sodium.Core -ProviderName NuGet -Scope CurrentUser
    # }

    # $libsodiumDirectory = Get-Item -Path (Get-Package -Name libsodium).Source 
    # $libsodiumDll = "$($libsodiumDirectory.Directory.FullName)/runtimes/win-x64/native/libsodium.dll"

    # if (!(
    #         [System.AppDomain]::CurrentDomain.GetAssemblies() 
    #         | Where-Object -Property Location -EQ $libsodiumDll
    #     )
    # ) {
    #     [System.Reflection.Assembly]::LoadFrom($libsodiumDll)
    # }
 
    # $sodiumCoreDirectory = Get-Item -Path (Get-Package -Name Sodium.Core).Source 
    # $sodiumCoreDll = "$($sodiumCoreDirectory.Directory.FullName)/lib/netstandard2.1/Sodium.Core.dll"

    # if (!(
    #         [System.AppDomain]::CurrentDomain.GetAssemblies() 
    #         | Where-Object -Property Location -EQ $sodiumCoreDll
    #     )
    # ) {
    #     [System.Reflection.Assembly]::LoadFrom($sodiumCoreDll)
    # }

    # $SecretBytes = [System.Text.Encoding]::UTF8.GetBytes($SecretValue)
    # $publicKey = [System.Convert]::FromBase64String($publicKey.key)

    # $sealdPublicKeyBox = [Sodium.SealedPublicKeyBox]::Create($SecretBytes, $publicKey)
    # $encryptedSecret = [System.Convert]::FromBase64String($sealdPublicKeyBox)

    if (!(npm list sodium-native -g -json | Select-String 'sodium-native')) {
        npm install sodium-native -g
    }

    if (!$PSBoundParameters.ContainsKey("Secrets")) {
        $Secrets = [System.Collections.Hashtable]::new()
        $null = $Secrets.add($Name, $Value)
    }

    $remoteUrl = "/repos/$($repositoryData.full_name)/actions/secrets/{0}"
    if (![System.String]::IsNullOrEmpty($Environment)) {
        $remoteUrl = "/repositories/$($repositoryData.id)/environments/$Environment/secrets/{0}"
    }

    $publicKey = Get-GithubPublicKey -Environment $Environment -Account $Account -Context $Context -Repository $Repository

    $Secrets.GetEnumerator() 
    | ForEach-Object {

        Write-Host -ForegroundColor GREEN "Setting Secret '$($_.Key)'"
        $encryptedSecret = node "$PSScriptRoot/../.resources/encrypt.js" $_.Value $publicKey.key

        $Request = @{
            METHOD  = "PUT"
            API     = [System.String]::Format($remoteUrl, $_.Key)
            Account = $repositoryData.Account
            Body    = @{
                encrypted_value = $encryptedSecret
                key_id          = $publicKey.key_id
            }
        }

        $null = Invoke-GithubRest @Request
    }
    
}
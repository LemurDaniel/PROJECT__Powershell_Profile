
<#
    .SYNOPSIS
    Resturns information about a terraform provider. For all verified terraform providers.

    .DESCRIPTION
    Resturns information about a terraform provider. For all verified terraform providers.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None

    .EXAMPLE

    Get Information about a Provider:

    PS> Get-TerraformProviderInfo <autocompleted>

    .EXAMPLE

    Get Information for the 'hashicorp/azurerm' Provider:

    PS> Get-TerraformProviderInfo 'hashicorp/azurerm

    .EXAMPLE

    Get Information for the 'F5Networks/bigip' Provider:

    PS> Get-TerraformProviderInfo F5Networks/bigip

    .LINK
        
#>

function Get-TerraformProviderInfo {

    [cmdletbinding()]
    param (
        # The provider to return information from
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundsParameters)
                $validValues = (Get-TerraformProviders).identifier
                
                return $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [ValidateScript(
            {
                $_ -in (Get-TerraformProviders).identifier
            }
        )]        
        [System.String]
        $provider
    )

    $endpoint = "https://registry.terraform.io/v1/providers/{{namespace}}/{{provider}}"

    $providerData = Get-TerraformProviders | Where-Object -Property identifier -EQ -Value $provider
    $providerInfo = Get-UtilsCache -Type 'terraform.provider' -Identifier $provider

    if ($null -eq $providerInfo) {

        $endpoint = $endpoint -replace '{{namespace}}', $providerData.namespace -replace '{{provider}}', $providerData.name
        $providerInfo = Invoke-RestMethod -Method Get -Uri $endpoint
        $providerInfo = Set-UtilsCache -Object $providerInfo -Type 'terraform.provider' -Identifier $provider -Alive 1440
     
    }

    return $providerInfo
}

 
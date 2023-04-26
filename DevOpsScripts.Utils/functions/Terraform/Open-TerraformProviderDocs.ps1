
<#
    .SYNOPSIS
    Opens the Documentation for a specific resource in a terraform provider in the Browser. Currenlty 'azurerm', 'azuread'

    .DESCRIPTION
    Opens the Documentation for a specific resource in a terraform provider in the Browser. Currenlty 'azurerm', 'azuread'

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None

    .EXAMPLE

    Open the documentaion for the 'azurerm_key_vault':

    PS> Open-TerraformProviderDocs azurerm -name key_vault

    .EXAMPLE

    Open the documentaion for the 'azurerm_key_vault' Data-Source:

    PS> tfDocs -type data azurerm -name key_vault

    .LINK
        
#>

function Open-TerraformProviderDocs {

    [Alias('tfDocs')]
    param (
        # The terraform provider to search resources in.
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundsParameters)
                $validValues = (Get-TerraformProviders).name
                
                return $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [ValidateScript(
            {
                $_ -in (Get-TerraformProviders).name
            }
        )]        
        [System.String]
        $provider,

        # The resource to open the doc for.
        [Parameter(
            Mandatory = $true,
            Position = 1
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundsParameters)

                $category = 'data' -eq $fakeBoundsParameters['type'] ? 'data-sources' : 'resources' 
                $validValues = (Get-TerraformProviderInfo -provider $fakeBoundsParameters['provider']).docs 
                | Where-Object -Property category -EQ -Value $category
                | Select-Object -ExpandProperty title
                
                return $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $name,

        # type to show data reads or resources
        [Parameter(
            Mandatory = $false,
            Position = 2
        )]
        [ValidateSet('resource', 'data')]
        [System.String]
        $type = "resource"
    )


    $providerInfo = Get-TerraformProviderInfo -provider $provider
    if ($name -notin $providerInfo.docs.title) {
        throw "'$name': Not such resource in '$provider'"
    }

    $category = $type -eq 'data' ? 'data-sources' : 'resources' 
    $docsUrl = "https://registry.terraform.io/providers/{{namespace}}/{{provider}}/{{version}}/docs/{{category}}/{{resource}}" `
        -replace '{{namespace}}', $providerInfo.namespace `
        -replace '{{provider}}', $providerInfo.name `
        -replace '{{version}}', $providerInfo.version `
        -replace '{{category}}', $category `
        -replace '{{resource}}', $name 

    Start-Process $docsUrl

}


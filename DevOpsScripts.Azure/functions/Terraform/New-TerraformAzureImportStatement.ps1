

<#

.SYNOPSIS
    TODO

.DESCRIPTION
    TODO


.EXAMPLE
    TODO

    Mostly still testing

    Select-AzContext ...
    tf-azimport ... ... ...

.LINK
  

#>




function New-TerraformAzureImportStatement {

    [CmdletBinding()]
    [Alias('tf-azimport')]
    param (
        
        # The path to the module
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = (Get-TerraformModuleCalls).modulePath
                
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [ValidateScript(
            {
                $_ -in (Get-TerraformModuleCalls).modulePath
            },
            ErrorMessage = "Not a valid module path in the current path."
        )]
        $ModulePath,

        # The resource in the module
        [Parameter(
            Position = 1,
            Mandatory = $true
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $module = Get-TerraformModuleCalls 
                | Where-Object -Property modulePath -EQ $fakeBoundParameters['ModulePath']
    
                $validValues = Get-TerraformModuleResources -Path $module.fsPath
                | Where-Object { $_ -like "azurerm*" }
                
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [ValidateScript(
            {
                $module = Get-TerraformModuleCalls 
                | Where-Object -Property modulePath -EQ $PSBoundParameters['ModulePath']

                $_ -in (Get-TerraformModuleResources -Path $module.fsPath)
            },
            ErrorMessage = "Not a valid module path in the current path."
        )]
        $Resource,
        
        [Parameter(
            Position = 2,
            Mandatory = $true
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)
                    
                $validValues = (Get-AzureResources -AzurermResource $fakeBoundParameters['Resource']).slug

                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        $Name
    )
    

    $providerResource = $PSBoundParameters['Resource'] -split '\.' | Select-Object -First 1
    $azureType = Get-TerraformAzuremMapping -ProviderResource $providerResource
    | Select-Object -ExpandProperty azureType

    if ($null -EQ $azureType) {
        throw "The corresponding type in azure ist not set for '$ProviderResource'. Please update '$PSScriptRoot/azurerm.resources.json' accordingly."
    }

    $azureResource = Get-AzureResources -AzurermResource $fakeBoundParameters['Resource']
    | Where-Object -Property slug -EQ $Name


    $importStatement = @"
import {
    id = "$($azureResource.importId)"
    to = $ModulePath.$Resource
}
"@

    $importStatement | Set-Clipboard
    return $importStatement
}


<#

(Get-terraformProviderInfo -provider hashicorp/azurerm).docs
| Where-Object -Property category -EQ resources
| Where-Object -Property language -EQ hcl
| ForEach-Object {
    return [PSCustomObject]@{
        id          = $_.id
        title       = $_.title
        slug        = $_.slug
        subcategory = $_.subcategory
        azureType   = $null
    }
}
| ConvertTo-Json
| Out-File azurerm.resources.json



$file = Get-Item -Path ".\azurerm.resources.json"
$data = Get-Content -Path $file 
| ConvertFrom-Json 
| ForEach-Object {

    if ($null -EQ $_.azureType) {
        $title = $_.slug -replace '_', ''
        $type = Get-AzureResourceTypes 
        | Where-Object {
            $_ -like "*$title*"
        }
        | Select-Object -First 1

        if ($null -NE $type) {
            $_.azureType = $type
            Write-Host $title, $type
        }
    }

    return $_
}
| ConvertTo-Json
$data | Out-File $file


#>
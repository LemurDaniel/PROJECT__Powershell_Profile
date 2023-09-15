
<#

.SYNOPSIS
    Get all provider resources as 'provider_resource.name' on a given path.
    Used by New-TerraformAzureImportStatement.ps1

.DESCRIPTION
    Get all provider resources as 'provider_resource.name' on a given path.
    Used by New-TerraformAzureImportStatement.ps1

.LINK
  
#>


function Get-TerraformModuleResources {

    param (
        # The path to the module
        [Parameter(
            Mandatory = $true
        )]
        $Path
    )

    $Path = (Get-Item -Path $Path).FullName

    $terraformFiles = Get-ChildItem -Path $Path -Filter "*.tf"
    $totalResources = @()

    foreach ($file in $terraformFiles) {

        $fileData = Get-Content -Raw -Path $file.FullName

        if ($fileData.Length -EQ 0) {
            continue
        }

        $resourceDefinitions = [regex]::Matches($fileData, 'resource\s*"[^"]+"\s*"[^"]+"')

        foreach ($resource in $resourceDefinitions) {
            $totalResources += [regex]::Matches($resource.Value, '"[^"]+"').Value -join '.' -replace '"', ''
        }
    
    }

    return $totalResources
}
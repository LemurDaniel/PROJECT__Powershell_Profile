<#

.SYNOPSIS
    Get all module calls recursivly down on a given path.
    The given path should have at least one module-call.
    Used by New-TerraformAzureImportStatement.ps1

.DESCRIPTION
    Get all module calls recursivly down on a given path.
    The given path should have at least one module-call.
    Used by New-TerraformAzureImportStatement.ps1

.LINK
  
#>


function Get-TerraformModuleCalls {

    param (
        # The path to the module
        [Parameter(
            Mandatory = $false
        )]
        $Path = '.',

        # The parent module
        [Parameter(
            Mandatory = $false
        )]
        $ParentModule = ''
    )

    $Path = (Get-Item -Path $Path).FullName

    $terraformFiles = Get-ChildItem -Path $Path -Filter "*.tf"
    $totalModuleCallPaths = @()

    foreach ($file in $terraformFiles) {

        $fileData = Get-Content -Raw -Path $file.FullName

        if ($fileData.Length -EQ 0) {
            continue
        }

        $moduleCalls = [regex]::Matches($fileData, 'module\s*"[^"]+"')

        foreach ($module in $moduleCalls) {
            $source = [regex]::Match($fileData.Substring($module.Index), 'source\s*=\s*"[^"]+"')
            $source = [regex]::Match($source.Value, '"[^"]+"').Value -replace '"', ''

            if($source -notlike ".*") { # not a path on filesystem
                continue
            }

            $fsPath = Join-Path -Path $Path -ChildPath $source
            $fsPath = (Get-Item -Path $fsPath).FullName

            $resources = Get-TerraformModuleResources -Path $fsPath
            
            $baseModulePath = $module.Value -replace '"+', '' -replace "\s+", '.'
            $baseModulePath = [System.String]::IsNullOrEmpty($ParentModule) ? $baseModulePath : "$ParentModule.$baseModulePath"
            $totalModuleCallPaths += [PSCustomObject]@{
                modulePath = $baseModulePath
                fsPath     = $fsPath
                resources  = $resources
                fullPaths  = $resources 
                | ForEach-Object {
                    "$baseModulePath.$_"
                }
            }
            
            # NOTE FOR FUTURE: Read terraform init modulecache for remote-modules?
            $totalModuleCallPaths += Get-TerraformModuleCalls -Path $fsPath -ParentModule $baseModulePath 
        }
    
    }

    return $totalModuleCallPaths
}
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

    param ()

    # Read module from TF_DATA_DIR after init, so remote modules are covered too.
    $modulesJson = Get-ChildItem -Path $env:TF_DATA_DIR -Filter "modules.json" -Recurse 
    if ($null -EQ $modulesJson) {
        throw "No modules JSON found in TF_DATA_DIR. Make sure terraform is initalized!"
    }

    $terraformModules = Get-Content -Path $modulesJson.FullName 
    | ConvertFrom-Json 
    | Select-Object -ExpandProperty Modules
    
    
    $totalModuleCallPaths = @()
    foreach ($module in $terraformModules) {

        try {
            # Get all defined resources at that file location
            if ([System.IO.Path]::IsPathRooted($module.Dir)) {
                $resources = Get-TerraformModuleResources -Path $module.Dir
            }
            else {
                $resources = Get-TerraformModuleResources -Path "./$($module.Dir)"
            }

            $modulePath = $module.Key
            if (![System.String]::IsNullOrEmpty($module.Key)) {
                $modulePath = ($module.key.split('.') | ForEach-Object { "module.$_" }) -Join '.'
            }

            $totalModuleCallPaths += [PSCustomObject]@{
                modulePath = $modulePath # path in terraform state
                fsPath     = $module.Dir # path in filesystem
                resources  = $resources # terraform resources at path
                fullPaths  = $resources # full module path for each resource
                | ForEach-Object {
                    [System.String]::IsNullOrEmpty($modulePath) ? $_ : "$($modulePath).$_"
                }
            }
            
        
        }
        catch {
            Write-Warning $_
        }
    }

    
    return $totalModuleCallPaths
}


<#

.SYNOPSIS
    TODO

.DESCRIPTION
    TODO


.EXAMPLE
    TODO

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
            $source = [regex]::Match($fileData.Substring($module.Index), 'source\s*=\s*"\.*[^"]+"')
            $source = [regex]::Match($source.Value, '"[^"]+"').Value -replace '"', ''
            $fsPath = Join-Path -Path $Path -ChildPath $source
            $fsPath = (Get-Item -Path $fsPath).FullName
            
            $baseModulePath = $module.Value -replace '"+', '' -replace "\s+", '.'
            $baseModulePath = [System.String]::IsNullOrEmpty($ParentModule) ? $baseModulePath : "$ParentModule.$baseModulePath"
            $totalModuleCallPaths += [PSCustomObject]@{
                modulePath = $baseModulePath
                fsPath     = $fsPath
            }
            
            # NOTE FOR FUTURE: Read terraform init modulecache for remote-modules?
            $totalModuleCallPaths += Get-TerraformModuleCalls -Path $fsPath -ParentModule $baseModulePath 
        }
    
    }

    return $totalModuleCallPaths
}
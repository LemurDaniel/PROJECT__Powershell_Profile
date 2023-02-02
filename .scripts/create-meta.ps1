
param ($moduleBaseName, $buildPath, $buildNuget)

# Stupid code completion
$moduleBaseName = [System.String]::IsNullOrEmpty($moduleBaseName) ? 'DevOpsScripts' : $moduleBaseName
$buildPath = [System.String]::IsNullOrEmpty($buildPath) ? './build/psmodules' : $buildPath
$buildNuget = [System.String]::IsNullOrEmpty($buildNuget) ? $true : $buildNuget
$buildNuget = [System.Boolean]::Parse($buildNuget)

# Move File to correct Build-Path
$sourcePath = Resolve-Path -Path '.' 
$buildDirectoy = $buildPath

Write-Host "Module Base Name: $moduleBaseName"
Write-Host "Current Path: $sourcePath"
Write-Host "Build Path: $buildDirectoy"
Write-Host "Build Nuget: $buildNuget"


if (!(Test-Path -Path $buildDirectoy)) {
    $buildDirectoy = New-Item -Path $buildDirectoy -ItemType Directory
    $sourcePath | Get-ChildItem -Filter "$moduleBaseName*" | Copy-Item -Recurse -Destination $buildDirectoy
    $sourcePath | Get-ChildItem -Filter 'nuget.config' | Copy-Item -Destination $buildDirectoy
}
elseif ((Get-Item -Path $buildDirectoy).FullName -ne (Get-Item -Path $sourcePath).FullName) {
    Remove-Item -Path $buildDirectoy -Recurse -Force -Verbose
    $buildDirectoy = New-Item -Path $buildDirectoy -ItemType Directory
    $sourcePath | Get-ChildItem -Filter "$moduleBaseName*" | Copy-Item -Recurse -Destination $buildDirectoy
    $sourcePath | Get-ChildItem -Filter 'nuget.config' | Copy-Item -Destination $buildDirectoy
}



$buildFolderModules = Get-ChildItem -Path $buildDirectoy -Filter "$moduleBaseName*" 

$buildFolderModules | ForEach-Object {

    $_modulePath = $_.FullName
    $_moduleRootPath = Join-Path -Path $_modulePath -ChildPath "$($_.BaseName).psd1"
    $_moduleMetaPath = Join-Path -Path $_modulePath -ChildPath 'meta.json'
    $_meta = Get-Content -Path $_moduleMetaPath | ConvertFrom-Json -Depth 3

    # Create the Module-Description Files.
    $Parameters = @{
        Path               = $_moduleRootPath
        GUID               = $_meta.GUID
        ModuleVersion      = $_meta.Version
        Author             = $_meta.Author
        Description        = $_meta.description

        RootModule         = "$($_.BaseName).psm1"

        RequiredModules    = @(
            $_meta.dependencies.modules
        )
        RequiredAssemblies = @(
            $_meta.dependencies.assemblies
        )
        PowerShellVersion  = $_meta.powershellversion

        VariablesToExport  = @()
        CmdletsToExport    = @()
        AliasesToExport    = @(
            Get-ChildItem -Path (Join-Path -Path $_.FullName -ChildPath 'functions') -Recurse -Filter '*.ps1' -ErrorAction SilentlyContinue | `
                Get-Content -Raw | ForEach-Object {
                $match = [regex]::Match($_, 'function[^\{]*\{(?s)(?<={).+?(?=param\s*\()')?.Value
                $match = [regex]::Match($match, "\[Alias\([A-Za-z,\s\-\']*\)\]")?.Value
                return [regex]::Matches($match, "'[A-Za-z\-]+'").Value
            } | Where-Object { $_ -ne $null } | ForEach-Object { $_ -replace "'", '' }
        )
        FunctionsToExport  = (
            Get-ChildItem -Path (Join-Path -Path $_.FullName -ChildPath 'functions') -Recurse -Filter '*.ps1' -ErrorAction SilentlyContinue | `
                Select-Object -ExpandProperty Name | ForEach-Object { $_.split('.')[0] }
        )
    }

    #$Parameters
    $null = New-ModuleManifest @Parameters


    #########################################################################################################################################
    #########################################################################################################################################


    if ($_.BaseName -ne $moduleBaseName) {

        # Content written in Module-File to Load module.
        $rootModuleContent = {
            if ($true -and ($PSEdition -eq 'Desktop')) {
                if ($PSVersionTable.PSVersion -lt [Version]'{{PSVERSION}}') {
                    throw 'PowerShell versions lower than {{PSVERSION}} are not supported. Please upgrade to PowerShell {{PSVERSION}} or higher.'
                }
            }

            @(
                'functions'
            ) | `
                ForEach-Object { Join-Path -Path $PSScriptRoot -ChildPath $_ } | `
                Get-ChildItem -Recurse -File -Filter '*.ps1' -ErrorAction Stop | `
                ForEach-Object {
                . $_.FullName
            }

        } 
            

    }
    else {

        $rootModuleContent = {
            if ($true -and ($PSEdition -eq 'Desktop')) {
                if ($PSVersionTable.PSVersion -lt [Version]'{{PSVERSION}}') {
                    throw 'PowerShell versions lower than {{PSVERSION}} are not supported. Please upgrade to PowerShell {{PSVERSION}} or higher.'
                }
            }

            # For Testing
            {{MODULE_IMPORTS}}
        }
    }

    $moduleImportsUnsorted = [System.Collections.ArrayList]::new()
    $moduleImportsSorted = [System.Collections.ArrayList]::new()
    $null = $buildFolderModules | ` 
    Where-Object { $_.BaseName.toLower() -ne $moduleBaseName.toLower()} | `
    Select-Object -Property *, @{
        Name = "dependencies";
        Expression = {
            (Get-Content -Path "$_/meta.json" | ConvertFrom-Json).dependencies
        }
    } | ForEach-Object { $moduleImportsUnsorted.Add($_) }
  
    while($moduleImportsUnsorted.Count -ne 0) {
        
        $item = $null
        :Ordering
        foreach ($item in $moduleImportsUnsorted) {
            
            $referenced = $moduleImportsUnsorted | Where-Object { $item.BaseName -in $_.dependencies.modules }
            if($referenced -eq 0){
                break Ordering
            }
        }

        $null = $moduleImportsUnsorted.remove($item)
        $null = $moduleImportsSorted.Add($item)
    }
$moduleImportsSorted
    $moduleImportsSorted | ForEach-Object {
        $buildNuget ? "Import-Module $($_.BaseName) -Global" : ('Import-Module (Resolve-Path "$PSScriptRoot\..\'+($_.BaseName)+'") -Global')
    }
 
    $rootModuleContent `
        -replace '{{MODULE_IMPORTS}}', ($moduleImports -Join "`n")`
        -replace '{{PSVERSION}}', $_meta.powershellversion | `
        Out-File -FilePath (Join-Path -Path $_modulePath -ChildPath "$($_.Name).psm1")

    #########################################################################################################################################
    if (!$buildNuget) {
        return
    }

    # When building the nuget place all the files in a folder with the version as a name.
    Remove-Item -Path $_moduleMetaPath -Force
    $folderItems = $_modulePath | Get-ChildItem
    # Sub version Folder
    $versionFolder = Join-Path -Path $_modulePath -ChildPath $_meta.Version
    $versionFolder = New-Item -ItemType Directory -Path $versionFolder -Force
    $folderItems | Move-Item -Destination $versionFolder
    
    #########################################################################################################################################  

    # Create the nuspec-File for each Module.
    $moduleNuspecFileName = ($_.BaseName + '.nuspec')
    Write-Host "Building $moduleNuspecFileName"
    $nuspecContent = Get-Content -Path (Join-Path -Path $sourcePath -ChildPath 'Module.nuspec.templ') -Raw
    Write-Host 'Adding Type'
    $nuspecContent = $nuspecContent -replace '{{TYPE}}', 'psmodules' 
    Write-Host 'Adding Release Notes'
    $nuspecContent = $nuspecContent -replace '{{RELEASEMESSAGE}}', 'Test' #$metaData.releasemessage
    Write-Host 'Adding Version'
    $nuspecContent = $nuspecContent -replace '{{VERSION}}', $_meta.version
    Write-Host 'Adding Description'
    $nuspecContent = $nuspecContent -replace '{{DESCRIPTION}}', $_meta.description
    Write-Host 'Adding Tags'
    $nuspecContent = $nuspecContent -replace '{{TAGS}}', (($_meta.tags, 'PSModule' | Get-Unique | ForEach-Object { $_ }) -join ' ')
    Write-Host 'Adding Author'
    $nuspecContent = $nuspecContent -replace '{{AUTHOR}}', $_meta.author
    Write-Host 'Adding Owner'
    $nuspecContent = $nuspecContent -replace '{{OWNER}}', $_meta.owner
    Write-Host 'Adding Module Name'
    $nuspecContent = $nuspecContent -replace '{{MODULENAME}}', $_.BaseName
    Write-Host 'Adding Build Path'
    $nuspecContent = $nuspecContent -replace '{{MODULEPATHNAME}}', $_.BaseName
    Write-Host 'Creating nuspec file'
    $nuspecFile = New-Item -Path $buildDirectoy -Name $moduleNuspecFileName -Value $nuspecContent -ItemType File
    Write-Host "`"$($nuspecFile.Name)`" created"
    
    # Create the csproj-File for each Module.
    $moduleCsprojFileName = ($_.BaseName + '.csproj')
    Write-Host "Building $moduleCsprojFileName"
    $csprojContent = Get-Content -Path (Join-Path -Path $sourcePath -ChildPath 'Module.csproj.templ') -Raw
    Write-Host 'Adding Package Id'
    $csprojContent = $csprojContent -replace '{{PACKAGE_ID}}', $_.BaseName 
    Write-Host 'Adding Version'
    $csprojContent = $csprojContent -replace '{{VERSION}}', $_meta.Version
    Write-Host 'Adding Authors'
    $csprojContent = $csprojContent -replace '{{AUTHORS}}', $_meta.author
    Write-Host 'Adding Description'
    $csprojContent = $csprojContent -replace '{{DESCRIPTION}}', $_meta.description 
    Write-Host 'Adding NUSPEC_FILE_PATH'
    $csprojContent = $csprojContent -replace '{{NUSPEC_FILE_PATH}}', $nuspecFile.Name
    $csprojFile = New-Item -Path $buildDirectoy -Name $moduleCsprojFileName -Value $csprojContent -ItemType File
    Write-Host "`"$($csprojFile.Name)`" created"
}
return

Write-Host
Write-Host '#########################################################################'
Write-Host

$buildDirectoy.FullName
(Get-ChildItem -Path $buildDirectoy -Recurse -Directory).FullName
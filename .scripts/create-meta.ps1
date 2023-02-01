
param ($moduleBaseName, $buildPath, $buildNuget)

$moduleBaseName = [System.String]::IsNullOrEmpty($moduleBaseName) ? 'DevOpsScripts' : $moduleBaseName
$buildPath = [System.String]::IsNullOrEmpty($buildPath) ? '.' : $buildPath
$buildNuget = [System.String]::IsNullOrEmpty($buildNuget) ? $false : $buildNuget
$buildNuget = [System.Boolean]::Parse($buildNuget)

# Move File to correct Build-Path
$currentPath = Resolve-Path -Path '.' 
$buildDirectoy = Join-Path $currentPath -ChildPath $buildPath

Write-Host "Module Base Name: $moduleBaseName"
Write-Host "Current Path: $currentPath"
Write-Host "Build Path: $buildDirectoy"
Write-Host "Build Nuget: $buildNuget"


if (!(Test-Path -Path $buildDirectoy)) {
    $buildDirectoy = New-Item -Path $buildDirectoy -ItemType Directory
    $currentPath | Get-ChildItem -Filter "$moduleBaseName*" | Copy-Item -Recurse -Destination $buildDirectoy
    $currentPath | Get-ChildItem -Filter '*.config' | Copy-Item -Recurse -Destination $buildDirectoy
}
elseif ((Get-Item -Path $buildDirectoy).FullName -ne (Get-Item -Path $currentPath).FullName) {
    Remove-Item -Path $buildDirectoy -Recurse -Force -Verbose
    $buildDirectoy = New-Item -Path $buildDirectoy -ItemType Directory
    $currentPath | Get-ChildItem -Filter "$moduleBaseName*" | Copy-Item -Recurse -Destination $buildDirectoy
    $currentPath | Get-ChildItem -Filter '*.config' | Copy-Item -Recurse -Destination $buildDirectoy
}


# Manipulate Files in Build-Path.
Get-ChildItem -Path $buildDirectoy -Filter "$moduleBaseName*" | ForEach-Object {

    $_modulePath = $_.FullName
    $_moduleRootPath = Join-Path -Path $_.FullName -ChildPath "$($_.BaseName).psd1"
    $_moduleMetaPath = Join-Path -Path $_.FullName -ChildPath 'meta.json'
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

    $Parameters
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

            if({{LOAD_FROM_LOCAL_RELATIVE_PATH}}){
                Import-Module (Resolve-Path "$PSScriptRoot\..\DevOpsScripts.Stuff") -Global
                Import-Module (Resolve-Path "$PSScriptRoot\..\DevOpsScripts.OneDrive") -Global
                Import-Module (Resolve-Path "$PSScriptRoot\..\DevOpsScripts.Utils") -Global
                Import-Module (Resolve-Path "$PSScriptRoot\..\DevOpsScripts.Azure") -Global
                Import-Module (Resolve-Path "$PSScriptRoot\..\DevOpsScripts.DevOps") -Global
            } else {
                Import-Module DevOpsScripts.Utils -Global
                Import-Module DevOpsScripts.Azure -Global
                Import-Module DevOpsScripts.DevOps -Global
            }
        }
    }

    $rootModuleContent `
        -replace '{{LOAD_FROM_LOCAL_RELATIVE_PATH}}', ($buildNuget ? '$False' : '$True') `
        -replace '{{PSVERSION}}', $_meta.powershellversion | `
        Out-File -FilePath (Join-Path -Path $_modulePath -ChildPath "$($_.Name).psm1")

    #########################################################################################################################################
    if (!$buildNuget) {
        return
    }

    # When building the nuget place all the files in a folder with the version as a name.
    $_modulePath | Get-ChildItem | Where-Object -Property name -Like meta.json | Remove-Item -Force
    $folderItems = $_modulePath | Get-ChildItem
    $versionFolder = New-Item -ItemType Directory -Path (Join-Path -Path $_modulePath -ChildPath $_meta.Version) -Force
    $folderItems | Move-Item -Destination $versionFolder
    
    #########################################################################################################################################  

    # Create the nuspec-File for each Module.
    Write-Host '##[section]Creating NuGet Specifications File'
    $nuspecContent = Get-Content 'Package.nuspec.templ' -Raw
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
    $nuspecFile = New-Item -Path $buildDirectoy -Name ('Package.DevOpsScripts.psmodules.' + $_.BaseName + '.nuspec') -Value $nuspecContent -ItemType File
    Write-Host "`"$($nuspecFile.Name)`" created"
    
}

Write-Host
Write-Host '#########################################################################'
Write-Host

$buildDirectoy.FullName
(Get-ChildItem -Path $buildDirectoy -Recurse -Directory).FullName
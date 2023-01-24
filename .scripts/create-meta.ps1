

$moduleBaseName = 'DevOpsScripts'
$currentPath = Resolve-Path -Path '.'


Get-ChildItem -Path $currentPath -Filter "$moduleBaseName*" | ForEach-Object {

    $metaPath = Join-Path -Path $_.FullName -ChildPath 'meta.json'
    $meta = Get-Content -Path $metaPath | ConvertFrom-Json -Depth 3


    $Parameters = @{
        Path               = (Join-Path -Path $_.FullName -ChildPath "$($_.Name).psd1")
        GUID               = $meta.GUID
        ModuleVersion      = $meta.Version
        Author             = $meta.Author
        Description        = $meta.description

        RootModule         = "$($_.Name).psm1"

        RequiredModules    = @(
            $meta.dependencies.modules
        )
        RequiredAssemblies = @(
            $meta.dependencies.assemblies
        )
        PowerShellVersion  = $meta.powershellversion

        VariablesToExport  = @()
        CmdletsToExport    = @()
        AliasesToExport    = @(
            Get-ChildItem -Path (Join-Path -Path $_.FullName -ChildPath 'functions') -Recurse -Filter '*.ps1' -ErrorAction SilentlyContinue | `
                Get-Content -Raw | ForEach-Object {
                $match = [regex]::Match($_, "Alias\([A-Za-z\-',\s]+\)[\s\S]+param\s+\(")?.Value
                return [regex]::Matches($match, "[A-Za-z\-]+").Value
            } | Where-Object { $_ -ne $null }
        )
        FunctionsToExport  = (
            Get-ChildItem -Path (Join-Path -Path $_.FullName -ChildPath 'functions') -Recurse -Filter '*.ps1' -ErrorAction SilentlyContinue | `
                Select-Object -ExpandProperty Name | ForEach-Object { $_.split('.')[0] }
        )
    }

    $Parameters
    $null = New-ModuleManifest @Parameters


    ###############################################################################################

    if ($_.BaseName -eq $moduleBaseName) {
        return
    }

    {
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

    } -replace '{{PSVERSION}}', $meta.powershellversion `
    | Out-File -FilePath (Join-Path -Path $_.FullName -ChildPath "$($_.Name).psm1")

}
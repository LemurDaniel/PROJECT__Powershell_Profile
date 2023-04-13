param([switch]$useCachedEnvironment, [switch]$runFromPipelineAgent, [switch]$generateMarkdownFile, [string]$location, [string]$config)
$ErrorActionPreference = 'Stop'

if ($useCachedEnvironment) {
    $cachedEnvirontment = Get-Content -Path '.vscode/last_used_env.json' | ConvertFrom-Json
  
    Clear-Host
    Write-Host ''
    Write-Host "Invoking `"tflint`""
    Write-Host "Name     : $($cachedEnvirontment.Name)"
    Write-Host "State    : $($cachedEnvirontment.StateEnvironment)"
    if ($cachedEnvirontment.Name -eq 'landingzone_acf_appzone') {
        Write-Host "Workpace : $($cachedEnvirontment.Workspace)"
    }
  
    $currentWorkingDirectory = (Resolve-Path -Path "landingzones/$($cachedEnvirontment.Name)" ).Path
}
elseif ($location) {
    $currentWorkingDirectory = $location
}
else {
    $currentWorkingDirectory = (Get-Location).Path
}

Write-Host "Current Location $currentWorkingDirectory"
$modules = Get-ChildItem -Path $currentWorkingDirectory -Recurse -Directory | Where-Object { 
  (Get-ChildItem -Path $_.FullName -File '*.tf*' | Measure-Object).Count -gt 0
}
$modules = @(Get-Item -Path $currentWorkingDirectory) + $modules



$isLintInstalled = Get-Command -Name tflint -ErrorAction SilentlyContinue

if ($null -eq $isLintInstalled) {
    $lintSourceUrl = 'https://github.com/terraform-linters/tflint/releases/latest'
    try {
        $latestVersion = Invoke-WebRequest $lintSourceUrl -ErrorAction Stop
        [version]$version = ($latestVersion.BaseResponse.RequestMessage.RequestUri.AbsoluteUri |
            Select-String -Pattern '(?:(\d+)\.)?(?:(\d+)\.)?(?:(\d+)\.\d+)').Matches.Value
        $lintLatestUrl = "https://github.com/terraform-linters/tflint/releases/download/v$version/tflint_windows_386.zip"
    }
    catch {
        $lintLatestUrl = $lintSourceUrl
    }

    if (!$runFromPipelineAgent) {
        Write-Error "TFLint seems not to be installed properly, download it from $lintLatestUrl and add it to your path!"
    }
    else {
        Write-Host 'Installing Lint'
        curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash  
    }
  
}


tflint --chdir=$currentWorkingDirectory --config=$config --init 

$TFLintIssues = @()
for ($index = 0; $index -lt $modules.Count; $index++) {
    $relativeModulePath = ('.') + $modules[$index].FullName -replace ([regex]::Escape($currentWorkingDirectory)), $null

    $Progress = @{
        Activity        = 'tflinting'
        Completed       = $index -eq ($modules.Count - 1)
        PercentComplete = [System.Math]::Round($index / $modules.Count * 100)
        Status          = "$($Progress.PercentComplete)% | linting `"$relativeModulePath`""
    }
    Write-Progress @Progress 
  
    $lintCommand = @(
        "--chdir=`"$($modules[$index].FullName)`"",
        "--config=$config"
        '--format=json'
    )

    if ($cachedEnvirontment.StateEnvironment -eq 'prod' -AND (Test-Path "$currentWorkingDirectory/landingzone.prod.tfvars")) {
        $lintCommand += @("--var-file=$currentWorkingDirectory/landingzone.prod.tfvars")
    }
  
    #if ($module.FullName -eq $currentWorkingDirectory) {
    #  $lintCommand += @('--module')
    #}
    #$lintCommand += @("$relativeModulePath")

    $TFLintIssues += (tflint $lintCommand | ConvertFrom-Json | Select-Object -ExpandProperty Issues)
}

$tfLintSelect = $TFLintIssues |
Select-Object -Property *, @{
    Name       = 'range_identifier';
    Expression = {
        "$($_.range.filename)|$($_.range.start.line)-$($_.range.start.column)|$($_.range.end.line)-$($_.range.end.column)"
    }
} | 
Group-Object -Property range_identifier |
Select-Object -Property @(
    @{Name = 'Line'; Expression = { 
            $_.Group[0].range.start.line
        }
    },
    @{Name = 'Column'; Expression = { 
            $_.Group[0].range.start.column
        }
    },
    @{Name = 'File'; Expression = { 
            $_.Group[0].range.filename } 
    },
    @{Name = 'Directory'; Expression = { 
            Get-Item -Path $_.Group[0].range.filename | Select-Object -ExpandProperty Directory } 
    },
    @{Name = 'SeverityLevels'; Expression = {
            @{
                Highest  = $_.Group.rule.Severity | Sort-Object { $('info', 'warning', 'error').indexOf($_) } | Select-Object -Last 1
                Errors   = $_.Group.rule | Where-Object -Property Severity -EQ error | Measure-Object | Select-Object -ExpandProperty Count
                Warnings = $_.Group.rule | Where-Object -Property Severity -EQ warning | Measure-Object | Select-Object -ExpandProperty Count
                Infos    = $_.Group.rule | Where-Object -Property Severity -EQ info | Measure-Object | Select-Object -ExpandProperty Count
            }
        }
    },
    @{
        Name       = 'Data';
        Expression = {
            $_.Group | Sort-Object { $('info', 'warning', 'error').indexOf($_.rule.Severity) }
        }
    },
    @{
        Name       = 'Rules';
        Expression = {
            $_.Group.rule.Name
        }
    },
    @{
        Name       = 'Messages';
        Expression = {
            $_.Group.message
        }
    }
)



Write-Host "`n -------------------------------------- Linting Results -------------------------------------- `n"
$tfLintSelect | Sort-Object -Property Severity | ForEach-Object {

    $colorPalette = @{
        error   = 'red'
        warning = 'yellow'
        info    = 'cyan'
    }

    Write-Host "`n------------------------`n"
    $headline = "Linting:  $($_.SeverityLevels.errors) Errors | $($_.SeverityLevels.warnings) Warnings | $($_.SeverityLevels.infos) Infos"
    $position = "Position: Line $($_.Line) | Column $($_.Column)"
    Write-Host $position
    Write-Host $headline
    Write-Host "File:     $($_.File)"
    Write-Host

    $_.data | ForEach-Object {
        Write-Host -ForegroundColor $colorPalette[$_.rule.Severity] "- $($_.rule.name)"
        Write-Host -ForegroundColor $colorPalette[$_.rule.Severity] "   $($_.message)"
    }
}
Write-Host "`n -------------------------------------- Linting Results -------------------------------------- `n"

Write-Host
Write-Host
Write-Host "$([System.Environment]::NewLine)found $($tfLintSelect.Count) issue(s)"
$global:tfLintOutput = $tfLintSelect
Write-Host "Hint: for a pwsh object representation of the tfplan, you can checkout the variable `"`$tfLintOutput`"" -ForegroundColor Cyan

$lintingDetails = $(
  ($tfLintSelect | 
    ForEach-Object {
          
        $colorMapping = @{
            error   = 'red'
            warning = 'orange'
            info    = 'cyan'
        }
        $Errors = "<span style=`"color:$($colorMapping['error'])`">$($_.SeverityLevels.errors) Errors </span>"
        $Warnings = "<span style=`"color:$($colorMapping['warning'])`">$($_.SeverityLevels.warnings) Warnings </span>"
        $Infos = "<span style=`"color:$($colorMapping['info'])`">$($_.SeverityLevels.infos) Infos </span>"

        $section = "`n> |               |                                           |"
        $section += "`n>|  ------------ | ----------------------------------------- |" 
        $section += "`n>| __Linting:__  | __$Errors / $Warnings / $Infos`__         |" 
        $section += "`n>| __Position:__ | __Line $($_.Line) / Column $($_.Column)__ |"
        $section += "`n>| __File:__     | __$($_.File)__                            |"

        $section += "`n>"
        $section += "`n>"
        $section += $_.data | ForEach-Object {

            "`n>- <span style=`"color:$($colorMapping[$_.rule.severity])`">__$($_.rule.name)__</span>"
            "`n>   - $($_.message)"
        }

        return $section
    }
    ) -join "`n`n"
)


if ($generateMarkdownFile -AND $tfLintSelect.Count -gt 0) {

    $markdownComment = @"

## Linting $((Get-Item -Path $currentWorkingDirectory).BaseName)

$lintingDetails

"@

    $fileName = ".$((Get-Item -Path $currentWorkingDirectory).BaseName).tflint.results.md"
    $markdownComment | Out-File -FilePath $filename
    code $fileName

}

if ($runFromPipelineAgent -AND $tfLintSelect.Count -gt 0) {

    $markdownComment = @"

## Linting $env:BUILD_DEFINITIONNAME

$lintingDetails

"@

    . "$PSScriptRoot/new-pullrequestcomment.ps1" -markdownComment $markdownComment

}

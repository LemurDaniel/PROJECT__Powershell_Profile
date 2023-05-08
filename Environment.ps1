

$global:DefaultEnvPaths = [ordered]@{
    
    # Code Editors
    VSCode_primary      = "$env:AppPath\_EnvPath_Apps\Microsoft VS Code\bin"
    VSCode_scondary     = 'C:\Program Files\Microsoft VS Code\bin'

    # CLI Tools
    AzureCLI_primary    = "$env:AppPath\_EnvPath_Apps\CLI\Azure\CLI2\wbin"
    AzureCLI_secondary  = 'C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin'
    sqlcmd              = "$env:AppPath\_EnvPath_Apps\CLI\Microsoft SQL Server\sqlcmd"
 
    terraformDocs       = "Invoke-ScriptInRepositories\_EnvPath_Apps\terraform-docs\v.0.16.0"
    tflint              = "$env:AppPath\_EnvPath_Apps\tflint\v0.44.0"

    node_modules_global = "$env:APPDATA\npm"
    nodejs_primary      = "$env:AppPath\_EnvPath_Apps\nodejs\18.12.1"
    nodejs_secondary    = 'C:\Program Files\nodejs'

    git_primary         = "$env:AppPath\_EnvPath_Apps\Git\2.38"
    git_secondary       = 'C:\Program Files\Git'
    gitcmd              = (Resolve-Path -Path "$env:AppPath\_EnvPath_Apps\Git\2.38\cmd" -ErrorAction SilentlyContinue).Path `
        ?? 'C:\Program Files\Git\cmd'

    dotnet              = "C:\Program Files\dotnet"

    java                = "$env:AppPath\_EnvPath_Apps\javaSDK\jdk-10.0.2\bin"
    docker              = 'C:\Program Files\Docker\Docker\resources\bin'

    gpg                 = (Resolve-Path -Path "C:\Program Files (x86)\GnuPG\bin" -ErrorAction SilentlyContinue).Path `
        ?? '$env:APPDATA\..\Local\Programs\GnuPG\bin'

}


$EnvironmentPaths = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::User) -split ';' 
| Where-Object { $global:DefaultEnvPaths.Values -notcontains $_ }

$EnvironmentPaths = (@() + $global:DefaultEnvPaths.Values + $EnvironmentPaths) -join ';'
#[System.Environment]::SetEnvironmentVariable('Path', $EnvironmentPaths, [System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable('Path', $EnvironmentPaths, [System.EnvironmentVariableTarget]::Process)
$env:Path = $EnvironmentPaths

$SettingsJsonDefaults = [PSCustomObject]@{

    # Profiles
    'workbench.experimental.settingsProfiles.enabled'          = $true

    # Git
    'git.enableCommitSigning'                                  = $env:USERNAME -ne 'M01947'
    'git-graph.repository.commits.showSignatureStatus'         = $env:USERNAME -ne 'M01947'
    'git-graph.repository.sign.tags'                           = $env:USERNAME -ne 'M01947'
    'git-graph.repository.sign.commits'                        = $env:USERNAME -ne 'M01947'

    # Blockman
    'blockman.n04ColorComboPreset'                             = 'Classic Dark 1 (Super gradients)'
    'blockman.n04Sub04RightSideBaseOfBlocks'                   = 'Rightmost Edge Of Viewport'
    'blockman.n23AnalyzeSquareBrackets'                        = $true
    'blockman.n28TimeToWaitBeforeRerenderAfterLastChangeEvent' = 1.1
    'blockman.n30TimeToWaitBeforeRerenderAfterLastScrollEvent' = 0.2
    'blockman.n33A01B2FromDepth0ToInwardForAllBackgrounds'     = '45,0,0,2; none'
    'blockman.n21BorderRadius'                                 = 4
    'blockman.n31RenderIncrementBeforeAndAfterVisibleRange'    = 50
    'blockman.n20CustomColorOfDepth0Border'                    = 'none'

    'powershell.developer.editorServicesLogLevel'              = 'Normal'
    'powershell.powerShellAdditionalExePaths'                  = @{
        'PS Core 7' = "$($global:DefaultEnvPaths['PowerShell_primary'])/pwsh.exe"
    }
    'powershell.powerShellDefaultVersion'                      = 'PS Core 7'

    ############################################
    'workbench.iconTheme'                                      = 'vscode-icons'
    'terminal.integrated.fontFamily'                           = "Jetbrains Mono, Consolas, 'Courier New', monospace"
    'editor.fontFamily'                                        = "Jetbrains Mono, Consolas, 'Courier New', monospace"
    'editor.fontLigatures'                                     = $true

    'workbench.colorTheme'                                     = 'Default Dark+'
    'scm.alwaysShowRepositories'                               = $true
    'git.enabled'                                              = $true
    'git.path'                                                 = "$($global:DefaultEnvPaths['GITCMD'])/git.exe"
    'gitlens.advanced.repositorySearchDepth'                   = 5

    'terminal.integrated.defaultProfile.windows'               = 'PS 7'
    'terminal.integrated.profiles.windows'                     = @{
        'Git Bash'                       = $null
        'Azure Cloud Shell (Bash)'       = $null
        'Azure Cloud Shell (PowerShell)' = $null
        'JavaScript Debug Terminal'      = $null
        'Command Prompt'                 = $null
        'PowerShell'                     = $null
        'PS 7'                           = @{
            'icon' = 'terminal-powershell'
            'path' = @(
                "$($global:DefaultEnvPaths['PowerShell'])/pwsh.exe"
            )
            'args' = @()
        }
        'Dev CMD'                        = @{
            'path' = @(
                "${env:windir}/Sysnative/cmd.exe",
                "${env:windir}/System32/cmd.exe"
            )
            'args' = @(
                '/k',
                'C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat'
            )
            'icon' = 'terminal-cmd'
        }
        'Node'                           = @{
            'path' = @(
                "$($global:DefaultEnvPaths['NodeJs'])/node.exe"
            )
            'args' = @()
            'icon' = 'terminal-cmd'
        }
    }
}




$null = Start-Job -ArgumentList $SettingsJsonDefaults -ScriptBlock {
    
    $settingsJsonItems = @(
        Get-Item -Path "$env:APPDATA\Code\User\settings.json"
        Get-ChildItem -Path "$env:APPDATA\Code\User\Profiles" -Filter 'settings.json' -Recurse | ForEach-Object { $_ }
    )

    foreach ($settingsItem in $settingsJsonItems) {

        $settingsJsonContent = Get-Content -Path $settingsItem.FullName | ConvertFrom-Json

        foreach ($setting in $args[0].PSObject.Properties) {

            $settingsJsonContent | Add-Member -MemberType $setting.MemberType `
                -Name $setting.Name -Value $setting.Value -Force
        }

        $settingsJsonContent | ConvertTo-Json -Depth 8 | Out-File -FilePath $settingsItem.FullName

    }
        
}
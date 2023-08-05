

$global:DefaultEnvPaths = [ordered]@{}


$EnvironmentPaths = @(
	[System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::User),
	[System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Machine) 
) -join ';' -split ';' 
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
        'PS Core 7' = "C:\Program Files\PowerShell\7\pwsh.exe"
    }
    'powershell.powerShellDefaultVersion'                      = 'PS Core 7'

    ############################################
    'workbench.iconTheme'                                      = 'vscode-icons'
    'terminal.integrated.fontFamily'                           = "Jetbrains Mono, Consolas, 'Courier New', monospace"
    'editor.fontFamily'                                        = "Jetbrains Mono, Consolas, 'Courier New', monospace"
    'editor.fontLigatures'                                     = $true

    'workbench.colorTheme'                                     = 'Dark Modern' #'Default Dark+'
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
                "C:\Program Files\PowerShell\7\pwsh.exe"
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
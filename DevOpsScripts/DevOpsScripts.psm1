
            if ($true -and ($PSEdition -eq 'Desktop')) {
                if ($PSVersionTable.PSVersion -lt [Version]'7.2') {
                    throw 'PowerShell versions lower than 7.2 are not supported. Please upgrade to PowerShell 7.2 or higher.'
                }
            }

            $ErrorActionPreference = 'Stop'

            

            # For Testing
            Import-Module (Resolve-Path "$PSScriptRoot\..\DevOpsScripts.Utils") -Global
Import-Module (Resolve-Path "$PSScriptRoot\..\DevOpsScripts.Stuff") -Global
Import-Module (Resolve-Path "$PSScriptRoot\..\DevOpsScripts.OneDrive") -Global
Import-Module (Resolve-Path "$PSScriptRoot\..\DevOpsScripts.Github") -Global
Import-Module (Resolve-Path "$PSScriptRoot\..\DevOpsScripts.Fresh") -Global
Import-Module (Resolve-Path "$PSScriptRoot\..\DevOpsScripts.DevOps") -Global
Import-Module (Resolve-Path "$PSScriptRoot\..\DevOpsScripts.Azure") -Global
        

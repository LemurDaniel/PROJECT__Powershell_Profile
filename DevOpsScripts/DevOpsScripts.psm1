
            if ($true -and ($PSEdition -eq 'Desktop')) {
                if ($PSVersionTable.PSVersion -lt [Version]'7.2') {
                    throw 'PowerShell versions lower than 7.2 are not supported. Please upgrade to PowerShell 7.2 or higher.'
                }
            }

            # For Testing
            if ([System.Boolean]::Parse('True')) {
                Import-Module (Resolve-Path "$PSScriptRoot\..\DevOpsScripts.Utils") -Global
                Import-Module (Resolve-Path "$PSScriptRoot\..\DevOpsScripts.Azure") -Global
                Import-Module (Resolve-Path "$PSScriptRoot\..\DevOpsScripts.DevOps") -Global
            }
            else {
                Import-Module DevOpsScripts.Utils -Global
                Import-Module DevOpsScripts.Azure -Global
                Import-Module DevOpsScripts.DevOps -Global
            }
        

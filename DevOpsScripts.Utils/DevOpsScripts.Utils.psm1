
            if ($true -and ($PSEdition -eq 'Desktop')) {
                if ($PSVersionTable.PSVersion -lt [Version]'7.2') {
                    throw 'PowerShell versions lower than 7.2 are not supported. Please upgrade to PowerShell 7.2 or higher.'
                }
            }

            $ErrorActionPreference = 'Stop'

            Add-Type -AssemblyName PresentationFramework

            @(
                'functions'
            ) | `
                ForEach-Object { Join-Path -Path $PSScriptRoot -ChildPath $_ } | `
                Get-ChildItem -Recurse -File -Filter '*.ps1' -ErrorAction Stop | `
                ForEach-Object {
                . $_.FullName
            }

        

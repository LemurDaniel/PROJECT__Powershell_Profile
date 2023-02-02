
            if ($true -and ($PSEdition -eq 'Desktop')) {
                if ($PSVersionTable.PSVersion -lt [Version]'7.2') {
                    throw 'PowerShell versions lower than 7.2 are not supported. Please upgrade to PowerShell 7.2 or higher.'
                }
            }

            # For Testing
            
        

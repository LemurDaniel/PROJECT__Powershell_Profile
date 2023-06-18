

<#
    .SYNOPSIS
    Install Software is use.

    .DESCRIPTION
    Install Software is use.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS
    None

    .LINK
        
#>

function Install-Stuff {

    param (
        [Parameter()]
        [System.String[]]
        $packageIds = @(
            "Git.Git",
            "JGraph.Draw",
            "OpenJS.NodeJS",
            "GnuPG.Gpg4win",
            "Postman.Postman",
            "Microsoft.WindowsTerminal",
            "Microsoft.VisualStudioCode"
            "Microsoft.AzureDataStudio",
            "Microsoft.Azure.StorageExplorer",
            "Microsoft.PowerShell"
        )
    )
    
    $selected = $null
    do {
        $installed = (winget list) -join ([System.Environment]::NewLine)
        $options = @()
        $options += @{
            display   = " -- End -- "
            operation = $null
            id        = "end"
        }
        $options += $packageIds 
        | ForEach-Object {
            $isInstalled = $installed.contains($_)
            return @{ 
                display   = "$_ ($($isInstalled ? "Upgrade" : "Install"))"
                operation = $isInstalled ? "upgrade" : "install"
                id        = $_
            }
        }

        $selected = Select-ConsoleMenu -Description "Install via winget:" -Property display -Options $options
        Write-Host ([System.Environment]::NewLine)
        if ($null -NE $selected) {
            
            if ($selected.operation -eq "install") {
                winget install -e --id $selected.id
                $null = Read-Host "...Press any key"
            } 
            elseif ($selected.operation -eq "upgrade") {
                winget upgrade --id $selected.id
                $null = Read-Host "...Press any key"
            }
        }
        
    } while ($null -NE $selected -AND $selected.id -NE "end")

}
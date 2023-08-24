

<#
    .SYNOPSIS
    Installs Software is use so I don't forget them in the future and quick install.

    .DESCRIPTION
    Installs Software is use so I don't forget them in the future and quick install.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS
    None

    .LINK
        
#>

function Install-Software {

    param (
        [Parameter()]
        [switch]
        $deinstall,

        [Parameter()]
        [System.String[]]
        $packageIds = @(
            "Git.Git",
            "7zip.7zip",
            "GIMP.GIMP",
            "Opera.Opera",
            "Opera.OperaGX",
            "Valve.Steam",
            "JGraph.Draw",
            "GnuPG.Gpg4win",
            "Postman.Postman",
            "Docker.DockerDesktop",
            "Kubernetes.kubectl",
            "Microsoft.Teams",
            "Microsoft.AzureCLI",
            "Microsoft.PowerBI",
            "Microsoft.WindowsTerminal",
            "Microsoft.VisualStudioCode",
            "Microsoft.VisualStudio.2022.Community",
            "Microsoft.SQLServerManagementStudio",
            "Microsoft.Azure.StorageExplorer",
            "Microsoft.AzureDataStudio",
            "Microsoft.PowerShell",
            "OpenJS.NodeJS",
            "Microsoft.DotNet.SDK.7",
            "VMware.WorkstationPlayer"
        )
    )
    
    $selected = $null
    enum Operation {
        install; upgrade; deinstall; none
    }

    do {
        $installed = (winget list) -join ([System.Environment]::NewLine)
        $options = @()
        $options += @{
            display   = " -- End -- "
            operation = [Operation]::none
            id        = "end"
        }
        $options += $packageIds 
        | ForEach-Object {
            $isInstalled = $installed.contains($_)
            if ($deinstall) {
                return @{ 
                    display   = "$_ ($($isInstalled ? "Deinstall" : "Not installed"))"
                    operation = $isInstalled ? [Operation]::deinstall : [Operation]::none
                    id        = $_
                }
            }
            else {
                return @{ 
                    display   = "$_ ($($isInstalled ? "Upgrade" : "Install"))"
                    operation = $isInstalled ? [Operation]::upgrade : [Operation]::install
                    id        = $_
                }
            }
        }

        $selected = Select-ConsoleMenu -Description "Install via winget:" -Property display -Options $options
        Write-Host ([System.Environment]::NewLine)
        if ($null -NE $selected) {
            
            if ($selected.operation -eq [Operation]::install) {
                winget install -e --id $selected.id
                $null = Read-Host "...Press any key"
            } 
            elseif ($selected.operation -eq [Operation]::upgrade) {
                winget upgrade --id $selected.id
                $null = Read-Host "...Press any key"
            }
            elseif ($selected.operation -eq [Operation]::deinstall) {
                winget uninstall --id $selected.id
                $null = Read-Host "...Press any key"
            }
        }
        
    } while ($null -NE $selected -AND $selected.id -NE "end")

}
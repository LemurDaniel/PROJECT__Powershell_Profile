

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
        $npmPackages = @(
            "yo",
            "mssql",
            "generate-code"
            "vscode/vsce",
            "ionic/cli",
            "create-react-app",
            "create-react-library"
            "react-native"
        ),

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
    enum Programm {
        winget; npm
    }

    $ProgramSelection = Select-ConsoleMenu -Options @(
        [Programm]::winget.ToString() 
        [Programm]::npm.ToString() 
    )

    do {

        $PackageRefrences = $null
        $InstalledPackages = [System.Collections.Hashtable]::new()

        if ([Programm]::npm -EQ [Programm]$ProgramSelection) {

            $PackageRefrences = $npmPackages
            $null = npm list --global --depth 0 
            | Select-Object -Skip 1 
            | ForEach-Object { 
                $_.substring([System.Math]::max($_.indexOf(' ') + 1, 0)) 
            } 
            | Where-Object { 
                $_.length -gt 0 
            } 
            | ForEach-Object { 
                $InstalledPackages[$_.substring(0, $_.lastIndexOf('@'))] = @{ 
                    id      = $_.substring(0, $_.lastIndexOf('@'))
                    version = $_.substring($_.lastIndexOf('@') + 1)
                    display = $_
                }
            }

        }
        elseif ([Programm]::winget -EQ [Programm]$ProgramSelection) {
            
            $PackageRefrences = $packageIds
            $null = Get-WinGetPackage 
            | Where-Object { $_.id -match "^.*\.+.*" } 
            | ForEach-Object { 
                $InstalledPackages[$_.id] = @{
                    id      = $_.Id
                    version = $_.InstalledVersion
                    display = "$($_.id) @$($_.InstalledVersion)"
                } 
            }
        }




        $options = @()
        $options += @{
            display   = " -- End -- "
            operation = [Operation]::none
            id        = "end"
        }
        $options += $PackageRefrences 
        | ForEach-Object {
            $isInstalled = $InstalledPackages.ContainsKey($_)

            if ($deinstall) {
                return @{ 
                    isInstalled = $isInstalled
                    display     = $isInstalled  ? "(Deinstall)     $($InstalledPackages[$_].display)" : "(Not installed) $_"
                    operation   = $isInstalled ? [Operation]::deinstall : [Operation]::none
                    id          = $_
                }
            }
            else {
                return @{ 
                    isInstalled = $isInstalled
                    display     = $isInstalled ? "(Upgrade) $($InstalledPackages[$_].display)" : "(Install) $_"
                    operation   = $isInstalled ? [Operation]::upgrade : [Operation]::install
                    id          = $_
                }
            }

        }



        $selected = Select-ConsoleMenu -Description "Install via '$($ProgramSelection)':" -Property display -Options $options
        Write-Host ([System.Environment]::NewLine)

        if ($null -NE $selected) {
        
            if ($selected.operation -eq [Operation]::install) {

                if ($ProgramSelection -EQ [Programm]::winget) {
                    winget install -e --id $selected.id
                }
                elseif ($ProgramSelection -EQ [Programm]::npm) {
                    npm install $selected.id --global
                }
                $null = Read-Host "...Press any key"
            } 
            elseif ($selected.operation -eq [Operation]::upgrade) {
                
                if ($ProgramSelection -EQ [Programm]::winget) {
                    winget upgrade -e --id $selected.id
                }
                elseif ($ProgramSelection -EQ [Programm]::npm) {
                    npm update $selected.id --global
                }
                $null = Read-Host "...Press any key"
            }
            elseif ($selected.operation -eq [Operation]::deinstall) {
                
                if ($ProgramSelection -EQ [Programm]::winget) {
                    winget uninstall -e --id $selected.id
                }
                elseif ($ProgramSelection -EQ [Programm]::npm) {
                    npm uninstall $selected.id --global
                }
                $null = Read-Host "...Press any key"
            }
        }

    } while ($null -NE $selected -AND $selected.id -NE "end")

}
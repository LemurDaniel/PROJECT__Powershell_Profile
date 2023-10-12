

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

        # install npm packages locally instead of globally
        [Parameter()]
        [switch]
        $local,

        [Parameter()]
        [System.String[]]
        $npmPackages = @(
            "yo",
            "sharp",
            "mssql",
            "generate-code"
            "vscode/vsce",
            "cdktf-cli",
            "@ionic/cli",
            "react-native",
            "create-react-app",
            "create-react-library"
            "azure-functions-core-tools"
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
            "Notepad++.Notepad++",
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
            "VMware.WorkstationPlayer",
            "Microsoft.Azure.FunctionsCoreTools"
        )
    )

    if (
        $null -EQ (Get-InstalledModule -Name Microsoft.WinGet.Client -MinimumVersion 0.2.1 -ErrorAction SilentlyContinue)
    ) {
        Write-Host -ForeGroundColor Magenta "Installing required Module 'Microsoft.WinGet.Client'"
        Install-Module -Name Microsoft.WinGet.Client -Repository PSGallery
        Import-Module -Name Microsoft.WinGet.Client

        $null = Read-Host "...Continue"
    }

    
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

    $commandOptions = ""
    if ($ProgramSelection -EQ [Programm]::npm -AND !$local) {
        $commandOptions = "--global"
    }

    $commandReference = @{
        [Programm]::winget = @{
            [Operation]::install   = {
                param($id, $commandOptions)    Install-WinGetPackage -Id $id
            }
            [Operation]::deinstall = {
                param($id, $commandOptions)    Uninstall-WinGetPackage -Id $id
            }
            [Operation]::upgrade   = {
                param($id, $commandOptions)    Update-WinGetPackage -Id $id
            }
        }
        [Programm]::npm    = @{
            [Operation]::install   = {
                param($id, $commandOptions)    npm install $id $commandOptions
            }
            [Operation]::deinstall = {
                param($id, $commandOptions)    npm uninstall $id $commandOptions
            }
            [Operation]::upgrade   = {
                param($id, $commandOptions)    npm update $id $commandOptions
            }
        }
    }

    do {

        $PackageRefrences = $null
        $InstalledPackages = [System.Collections.Hashtable]::new()

        if ([Programm]::npm -EQ [Programm]$ProgramSelection) {

            $PackageRefrences = $npmPackages
            $null = (npm list $commandOptions --json --depth 0) 
            | ConvertFrom-Json 
            | Select-Object @{
                Name       = "Properties";
                Expression = { $_.dependencies.psobject.properties }
            } 
            | Select-Object -ExpandProperty Properties
            | ForEach-Object {
                $InstalledPackages[$_.Name] = @{ 
                    id      = $_.Name
                    version = $_.Value.version
                    display = "$($_.Name)@$($_.Value.version)"
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
            id        = 'end'
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

        if ($null -NE $selected -AND $selected.id -NE "end") {

            $scriptBlock = $commandReference[[Programm]$ProgramSelection][$selected.operation]
            Invoke-Command -ScriptBlock $scriptBlock -ArgumentList ($selected.id), $commandOptions

            $null = Read-Host "...Press any key"

        }

    } while ($null -NE $selected -AND $selected.id -NE "end")

}
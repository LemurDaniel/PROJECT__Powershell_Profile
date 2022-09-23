function Add-EnvPaths {

    param (
        [Parameter()]
        [System.Collections.Hashtable]
        $AdditionalPaths = [System.Collections.Hashtable]::new(),

        [Parameter()]
        [System.Collections.ArrayList]
        $RemovePaths = [System.Collections.ArrayList]::new()
    )


    $global:DefaultEnvPaths = @{

        # Some default
        winget            = "$env:HOMEDRIVE\AppData\Local\Microsoft\WindowsApps"
        System32          = 'C:\Windows\system32'
        wbem              = 'C:\Windows;C:\Windows\System32\Wbem'
        OpenSSH           = 'C:\Windows\System32\OpenSSH\'
        ThinPrint         = 'C:\Program Files\ThinPrint Client\'
        ThinPrintx86      = 'C:\Program Files (x86)\ThinPrint Client\'

        # Code Editors
        # VSCode_Primary    = 'C:\Program Files\Microsoft VS Code\bin'
        VSCode_Secondary  = "$env:AppPath\_EnvPath_Apps\Microsoft VS Code\bin" 
        #"C:\Users\Daniel\AppData\Local\Programs\Microsoft VS Code\bin"

        # Powershell
        WindowsPowerShell = 'C:\Windows\System32\WindowsPowerShell\v1.0\'
        PowerShell        = "$env:AppPath\_Apps\_EnvPath_Apps\PowerShell\7.2"
     
        #PowerShell_Onedrive        = "$env:AppPath\PowerShell\7\"
        #initialProfile_Onedrive    = "$env:AppPath\PowerShell\7\profile.ps1"

        WindowsAppsFolder = 'C:\Users\M01947\AppData\Local\Microsoft\WindowsApps' #TODO
        
        # CLI Tools
        AzureCLI          = 'C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin'
        AzureCLI_Onedrive = "$env:AppPath\_EnvPath_Apps\CLI\Azure\CLI2\wbin"

        sqlcmd_Onedrive   = "$env:AppPath\_EnvPath_Apps\CLI\Microsoft SQL Server\sqlcmd"
 
        terraform         = $env:TerraformNewestVersion 
        terraformDocs     = $env:TerraformDocsNewestVersion

        nodejs            = 'C:\Program Files\nodejs\'
        gitcmd            = 'C:\Program Files\Git\cmd'
        git               = 'C:\Program Files\Git'

        nodejs_Secondary  = "$env:AppPath\_EnvPath_Apps\nodejs"
        gitcmd_Secondary  = "$env:AppPath\_EnvPath_Apps\Git\cmd"
        git_Secondary     = "$env:AppPath\_EnvPath_Apps\Git"

        vlang             = (Get-ChildItem -Path "$env:AppPath\_EnvPath_Apps" -Directory -Filter 'v')
        dotnet            = (Get-ChildItem -Path 'C:\Program Files' -Directory -Filter 'dotnet').FullName
        dotnet_Secondary  = (Get-ChildItem -Path "$env:AppPath\_EnvPath_Apps" -Directory -Filter 'dotnet').FullName

        java              = "$env:AppPath\_EnvPath_Apps\javaSDK\jdk-10.0.2\bin"
    }

    foreach ($key in $AdditionalPaths.Keys) {
        $global:DefaultEnvPaths.Remove($key)
        $global:DefaultEnvPaths.Add($key, $AdditionalPaths[$key])
    }

    $processedPaths = [System.Collections.ArrayList]::new()
    foreach ($path in $env:InitialEnvsPaths -split ';' ) {

        if ( ($RemovePaths | Where-Object { $path.contains($_) }).length -eq 0) {
            $processedPaths += $path
        }
    }

    $UniquePathsMap = [System.Collections.Hashtable]::new()
    $processedPaths + $global:DefaultEnvPaths.Values | Where-Object { $_.length -gt 0 } | Where-Object { $UniquePathsMap[$_] = $_ } 

    $env:Path = ($UniquePathsMap.Values -join ';')

}




function Get-PreferencedObject {
    param (
        [Parameter(Mandatory = $true)]
        [System.Object[]]
        $SearchObjects,

        [Parameter(Mandatory = $true)]
        [System.Object[]]
        $SearchTags,

        [Parameter(Mandatory = $false)]
        [System.Object[]]
        $ExcludeSearchTags,

        [Parameter()]
        [System.String]
        $SearchProperty = 'name',

        [Parameter()]
        [System.Boolean]
        $Quiet = [bool]::Parse($env:Quiet),

        [Parameter()]
        [Switch]
        $Multiple
    )



    $ChosenObjects = [System.Collections.ArrayList]::new()
    foreach ($SearchObject in $SearchObjects) {

        if (!($SearchObject."$SearchProperty")) {
            continue
        }

        $ObjectWrapper = [PSCustomObject]@{
            Hits           = 0
            SearchProperty = $SearchObject."$SearchProperty"
            Object         = $SearchObject
        }
        foreach ($Tag in $SearchTags) {

            if (!$Quiet) {
                Write-Host "Search Property: $SearchProperty"
                Write-Host "Search Property Value: $($SearchObject."$SearchProperty".ToLower())"
                Write-Host $Tag $SearchObject."$SearchProperty".ToLower().Contains($Tag.ToLower())
                Write-Host -Foreground yellow '###############################################################################################'
            }

            if ($SearchObject."$SearchProperty" -and $SearchObject."$SearchProperty".ToLower().Contains($Tag.ToLower()) ) {
                $ObjectWrapper.Hits -= 1;
            }
        }
        foreach ($Tag in $ExcludeSearchTags) {

            if (!$Quiet) {
                Write-Host "Search Property: $SearchProperty"
                Write-Host "Exclude Search Property Value: $($SearchObject."$SearchProperty".ToLower())"
                Write-Host $Tag $SearchObject."$SearchProperty".ToLower().Contains($Tag.ToLower())
                Write-Host -Foreground yellow '###############################################################################################'
            }

            if ($SearchObject."$SearchProperty" -and $SearchObject."$SearchProperty".ToLower().Contains($Tag.ToLower()) ) {
                $ObjectWrapper.Hits += 1;
            }
        }

        if (!$Quiet) {
            Write-Host $ObjectWrapper
        }
        


        if ($ObjectWrapper.Hits -lt 0) {
            $null = $ChosenObjects.Add($ObjectWrapper)
        }
    }
    
    if ($ChosenObjects[0]) {

        if ($Multiple) {
            return ($ChosenObjects | Sort-Object -Property Hits, $SearchProperty).Object
        }
        else {
            $preferedObject = ($ChosenObjects | Sort-Object -Property Hits, $SearchProperty)[0]
            if (!$Quiet) {
                Write-Host 
                Write-Host $preferedObject.SearchProperty
                Write-Host 
            }
            return $preferedObject.Object
        }
    }
}


######################################################

function Edit-PSProfile {

    param(
        [Parameter()]
        [System.String]
        [ValidateSet([PsProfile])] 
        $PsProfile = 'Profile'
    )

    if ($PsProfile -eq 'Profile') {
        code $env:PS_PROFILE
    }
    elseif ($PsProfile -eq 'All') {
        code (Get-ChildItem -Path $env:PROFILE_HELPERS_PATH -Filter '*.ps1')      
    }
    else {
        code (Get-ChildItem -Path $env:PROFILE_HELPERS_PATH -Filter "$PsProfile.ps1") 
    }
}

######################################################

function Update-VSCodeSettings {

    param()

    git -C "$env:APPDATA\Code\User\" pull origin master
    git -C "$env:APPDATA\Code\User\" push origin master

}
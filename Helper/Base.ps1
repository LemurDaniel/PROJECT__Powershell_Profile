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
        System32          = "C:\Windows\system32"
        wbem              = "C:\Windows;C:\Windows\System32\Wbem"
        OpenSSH           = "C:\Windows\System32\OpenSSH\"
        ThinPrint         = "C:\Program Files\ThinPrint Client\"
        ThinPrintx86      = "C:\Program Files (x86)\ThinPrint Client\"

        WindowsPowerShell = "C:\Windows\System32\WindowsPowerShell\v1.0\"
        PowerShell        = "C:\Program Files\PowerShell\7\"

        AzureCLI          = "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin"

        VSCodePrimary     = "C:\Program Files\Microsoft VS Code\bin"
        VSCodeSecondary   = "C:\Users\Daniel\AppData\Local\Programs\Microsoft VS Code\bin"

        WindowsAppsFolder = "C:\Users\M01947\AppData\Local\Microsoft\WindowsApps"
 
        terraform         = $env:TerraformNewestVersion 
        terraformDocs     = $env:TerraformDocsNewestVersion

        vlang             = Resolve-Path -Path "$env:AppPath\v" -ErrorAction Ignore
        nodejsSecondary   = Resolve-Path -Path "$env:AppPath\nodejs" -ErrorAction Ignore
        nodejs            = "C:\Program Files\nodejs\"
        gitcmd            = "C:\Program Files\Git\cmd"
        git               = "C:\Program Files\Git"

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
    $processedPaths + $global:DefaultEnvPaths.Values | Where-Object { $_.length -gt 0 } | where-Object { $UniquePathsMap[$_] = $_ } 

    $env:Path = ($UniquePathsMap.Values -join ';')

}




function Get-PreferencedObject {
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]
        $SearchObjects,

        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]
        $SearchTags,

        [Parameter()]
        [System.String]
        $SearchProperty = "name"
    )


    $ChosenObjects = [System.Collections.ArrayList]::new()
    foreach ($SearchObject in $SearchObjects) {

        $ObjectWrapper = [PSCustomObject]@{
            Hits           = 0
            SearchProperty = $SearchObject."$SearchProperty"
            Object         = $SearchObject
        }
        foreach ($Tag in $SearchTags) {
            # Write-Host $SearchObject."$SearchProperty".ToLower()
            # Write-Host $SearchObject."$SearchProperty".ToLower(),  $Tag  $SearchObject."$SearchProperty".ToLower().Contains($Tag)
            if ($SearchObject."$SearchProperty" -and $SearchObject."$SearchProperty".ToLower().Contains($Tag) ) {
                $ObjectWrapper.Hits -= 1;
            }
        }

        # Write-Host $ObjectWrapper
        if ($ObjectWrapper.Hits -lt 0) {
            $null = $ChosenObjects.Add($ObjectWrapper)
        }
    }
    
    if ($ChosenObjects[0]) {
        $preferedObject = ($ChosenObjects | Sort-Object -Property Hits, $SearchProperty)[0]
        Write-Host 
        Write-Host $preferedObject.SearchProperty
        Write-Host 
        return $preferedObject.Object
    }
}


######################################################

function Edit-PSProfile {

    param(
        [Parameter()]
        [System.String]
        [ValidateSet([PsProfile])] 
        $PsProfile = "Profile"
    )

    if ($PsProfile -eq "Profile") {
        code  $env:PS_PROFILE
    }
    elseif ($PsProfile -eq "All") {
        code (Get-ChildItem -Path $env:PROFILE_HELPERS_PATH -Filter "*.ps1")      
    }
    else {
        code  (Get-ChildItem -Path $env:PROFILE_HELPERS_PATH -Filter "$PsProfile.ps1") 
    }
}


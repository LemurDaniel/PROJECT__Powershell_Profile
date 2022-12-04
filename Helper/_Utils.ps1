
function Join-PsObject {

    param ( 
        [parameter()]
        [PSObject]
        $Object1,

        [parameter()]
        [PSObject]
        $Object2
    )

    $PropertyNamesList = (@($Object1.PSObject.Properties.Name) + @($Object2.PSObject.Properties.Name)) | Sort-Object | Get-Unique

    foreach ($PropertyName in $PropertyNamesList) {

        $isPropertyInObj1 = $PropertyName -in $Object1.PSObject.Properties.Name
        $isPropertyInObj2 = $PropertyName -in $Object2.PSObject.Properties.Name

        if ($isPropertyInObj1 -AND !$isPropertyInObj2) {
            continue
        }
        elseif (!$isPropertyInObj1 -AND $isPropertyInObj2) {
            $Property = $Object2.PSObject.Properties[$PropertyName]
            $Object1 | Add-Member -MemberType $Property.MemberType -Name $Property.Name -Value $Property.Value
            continue
        }

        $Type = $Object1."$PropertyName".GetType();

        if ( $Type -ne $Object2."$PropertyName".GetType() ) {
            Throw 'Mismatching Types'
        }
        if ( $Type.BaseType -eq [System.ValueType] || $Type -eq [System.String] ) {
            Throw "Operation not Supported for $($Property.PSObject.Properties.Value.GetType())"
        }
        elseif ( $Type.BaseType -eq [System.Array]) {
            $Object1."$($PropertyName)" = (@($Object1."$($PropertyName)") + @($Object2."$($PropertyName)")) | Sort-Object | Get-Unique
        }
        else {
            $Object1."$($PropertyName)" = Join-PsObject -Object1 ($Object1."$($PropertyName)") -Object2 ($Object2."$($PropertyName)") 
        }

    }
    return $Object1
}

################################################################################################

function Search-PreferencedObject {

    [cmdletbinding()]
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
        [System.String]
        $returnProperty,

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

            Write-Verbose "Search Property: $SearchProperty"
            Write-Verbose "Search Property Value: $($SearchObject."$SearchProperty".ToLower())"
            Write-Verbose $Tag $SearchObject."$SearchProperty".ToLower().Contains($Tag.ToLower())
            Write-Verbose '###############################################################################################'

            if ($SearchObject."$SearchProperty" -and $SearchObject."$SearchProperty".ToLower().Contains($Tag.ToLower()) ) {
                $ObjectWrapper.Hits -= 1;
            }
        }
        foreach ($Tag in $ExcludeSearchTags) {

            Write-Verbose "Search Property: $SearchProperty"
            Write-Verbose "Exclude Search Property Value: $($SearchObject."$SearchProperty".ToLower())"
            Write-Verbose $Tag $SearchObject."$SearchProperty".ToLower().Contains($Tag.ToLower())
            Write-Verbose -Foreground yellow '###############################################################################################'

            if ($SearchObject."$SearchProperty" -and $SearchObject."$SearchProperty".ToLower().Contains($Tag.ToLower()) ) {
                $ObjectWrapper.Hits += 1;
            }
        }

        Write-Verbose $ObjectWrapper

        if ($ObjectWrapper.Hits -lt 0) {
            $null = $ChosenObjects.Add($ObjectWrapper)
        }
    }

    if ($ChosenObjects.Count -eq 0) {
        return
    }

    $ChosenObjects = ($ChosenObjects | Sort-Object -Property Hits, $SearchProperty).Object
    if ($returnProperty) {
        $ChosenObjects = $ChosenObjects."$returnProperty"
    }

    if ($Multiple) {
        return  $ChosenObjects
    }
    else {
        return $ChosenObjects.GetType().BaseType -eq [System.Array] ? $ChosenObjects[0] : $ChosenObjects
    }
   
}


################################################################################################

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

################################################################################################

function Update-VSCodeSettings {

    param()

    git -C "$env:APPDATA\Code\User\" pull origin master
    git -C "$env:APPDATA\Code\User\" push origin master

}

################################################################################################

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
        winget               = "$env:HOMEDRIVE\$env:HOMEPATH\AppData\Local\Microsoft\WindowsApps"
        System32             = 'C:\Windows\system32'
        wbem                 = 'C:\Windows;C:\Windows\System32\Wbem'
        OpenSSH              = 'C:\Windows\System32\OpenSSH\'
        ThinPrint            = 'C:\Program Files\ThinPrint Client\'
        ThinPrintx86         = 'C:\Program Files (x86)\ThinPrint Client\'

        # Code Editors
        VSCode_Secondary     = "$env:AppPath\_EnvPath_Apps\Microsoft VS Code\bin" 
        VSCode_Primary       = 'C:\Program Files\Microsoft VS Code\bin'
        #"C:\Users\Daniel\AppData\Local\Programs\Microsoft VS Code\bin"

        # Powershell
        WindowsPowerShell    = 'C:\Windows\System32\WindowsPowerShell\v1.0\'
        PowerShell           = "$env:AppPath\_EnvPath_Apps\PowerShell\7.5"
        PowerShell_Secondary = 'C:\Program Files\PowerShell\7'

        #PowerShell_Onedrive        = "$env:AppPath\PowerShell\7\"
        #initialProfile_Onedrive    = "$env:AppPath\PowerShell\7\profile.ps1"

        WindowsAppsFolder    = 'C:\Users\M01947\AppData\Local\Microsoft\WindowsApps' #TODO
        
        # CLI Tools
        AzureCLI             = 'C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin'
        AzureCLI_Onedrive    = "$env:AppPath\_EnvPath_Apps\CLI\Azure\CLI2\wbin"

        sqlcmd_Onedrive      = "$env:AppPath\_EnvPath_Apps\CLI\Microsoft SQL Server\sqlcmd"
 
        terraform            = $env:TerraformNewestVersion 
        terraformDocs        = $env:TerraformDocsNewestVersion

        nodejs               = 'C:\Program Files\nodejs'
        gitcmd               = 'C:\Program Files\Git\cmd'
        git                  = 'C:\Program Files\Git'

        nodejs_Secondary     = "$env:AppPath\_EnvPath_Apps\nodejs\18.12.1"
        gitbin_Secondary     = "$env:AppPath\_EnvPath_Apps\Git\2.38\bin"
        git_Secondary        = "$env:AppPath\_EnvPath_Apps\Git\2.38"

        vlang                = (Get-ChildItem -Path "$env:AppPath\_EnvPath_Apps" -Directory -Filter 'v')
        dotnet               = (Get-ChildItem -Path 'C:\Program Files' -Directory -Filter 'dotnet').FullName
        dotnet_Secondary     = (Get-ChildItem -Path "$env:AppPath\_EnvPath_Apps" -Directory -Filter 'dotnet').FullName

        cmake                = "$env:AppPath\_EnvPath_Apps\cmake\3.24\bin"
        gnumake              = "$env:AppPath\_EnvPath_Apps\GnuWin32\3.8\bin"

        java                 = "$env:AppPath\_EnvPath_Apps\javaSDK\jdk-10.0.2\bin"
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
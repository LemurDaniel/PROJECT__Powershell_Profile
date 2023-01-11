
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

function Get-Property {
    param (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Object,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PropertyPath
    )

    $splitPath = $PropertyPath -split '[\/\.]+'
    foreach ($segment in $splitPath) {

        $segment = $segment -replace '[()]+', ''
        Write-Verbose $segment
        if ($null -eq $Object) {
            Throw "Path: $PropertyPath - Error at Segment $segment - Object is NULL"
        }

        if ($Object.GetType().Name -notin @('PSObject', 'PSCustomObject') ) {
            Throw "Path: $PropertyPath - Error at Segment $segment - Object is $($SecretObject.GetType().Name)"
        }

        if ($null -eq $Object."$segment") {
            Throw "Path: $PropertyPath - Error at Segment $segment - Segment does not exist "
        }

        $Object = $Object."$segment"
    }

    return $Object
}

function Search-PreferencedObject {

    [cmdletbinding()]
    [Alias('Search-In')]
    param (
        [Parameter(Mandatory = $true)]
        [System.Object[]]
        $SearchObjects,

        [Alias('is')]
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $SearchTags,

        [Alias('not')]
        [Parameter(Mandatory = $false)]
        [System.String[]]
        $ExcludeSearchTags,

        [Alias('where')]
        [Parameter()]
        [System.String]
        $SearchProperty = 'name',

        [Alias('return')]
        [Parameter()]
        [System.String]
        $returnProperty,

        [Parameter()]
        [Switch]
        $Multiple
    )


    $ChosenObjects = $SearchObjects | ForEach-Object {
    
        Write-Verbose "Search Property: $SearchProperty"
        $Property = Get-Property -Object $_ -PropertyPath $SearchProperty
        $positiveHits = ($SearchTags | Where-Object { $Property.contains($_) } | Measure-Object).Count
        $negativeHits = ($ExcludeSearchTags | Where-Object { !($Property.contains($_)) } | Measure-Object).Count

        $returnValue = [String]::IsNullOrEmpty($returnProperty) ? $_ : (Get-Property -Object $_ -PropertyPath $returnProperty)

        return [PSCustomObject]@{
            Hits     = $positiveHits + $negativeHits
            Property = $returnValue
            Object   = $_
        }
    } | `
        Where-Object { $_.Hits -gt 0 } | `
        Sort-Object -Property Hits -Descending

    if ($ChosenObjects.Count -eq 0) {
        return
    }
    if ($Multiple) {
        return  $ChosenObjects.Property
    }
    else {
        return $ChosenObjects.GetType().BaseType -eq [System.Array] ? $ChosenObjects[0].Property : $ChosenObjects.Property
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
        [System.String]
        $AdditionalPath,

        [Parameter()]
        [System.String]
        $AdditionalValue
    )

    $global:DefaultEnvPaths[$AdditionalPath] = $AdditionalValue
    $UniquePathsMap = [System.Collections.Hashtable]::new()
    $processedPaths + $global:DefaultEnvPaths.Values | Where-Object { $_.length -gt 0 } | Where-Object { $UniquePathsMap[$_] = $_ } 
    $env:Path = ($UniquePathsMap.Values -join ';')
}

################################################################################################

function prompt {

    if ( (Get-Location | Split-Path -NoQualifier).Equals('\') ) { return $loc } # Edgecase if current folder is a drive
  
    $maxlenFolder = 25
    $maxlenParent = 40

    $loc = Get-Location
    $Drive = ($loc | Split-Path -Qualifier) 	# Like C: or F:
    $Parent = ($loc | Split-Path -Parent)		# Parent Path like C:/users/Daniel Notebool (includes drive!!!)
    $Leaf = ($loc | Split-Path -Leaf)			# Current Folder
  
    $Leaf = shorten_path -InputString $Leaf -SplitChar ' ' -maxlen $maxlenFolder -Cut_On_Letter_Level $true
    $Parent = shorten_path -InputString $Parent -SplitChar '\' -maxlen $maxlenParent -Cut_On_Letter_Level $false
  
    # debug return $Parent.substring(3, $Parent.length-3)
  
    # Assemble final Path
    $path = $Drive + '\' # Start with drive
    $path += $Parent.substring(3, $Parent.length - 3) + '\'
    $path += $Leaf # append foldername
  
    $Edition = $PSVersionTable.PSEdition
    $PSVersion = $PSVersionTable.PSVersion.Major

    return "$path> "
    #return "PS $PSVersion || $path> "
}

function shorten_path {
    param (
        [string]$InputString,
        [char]$SplitChar,
        [int]$MaxLen,
        [bool]$Cut_On_Letter_Level
    )
    if ($InputString.length + 1 -lt $MaxLen) { return $InputString }
	
    # Section 1 Code shortens the Current Foldername if too long 
    $WordArray = $InputString.split($SplitChar)  # Turn Foldername in Array of Words (if multiple Words in Name)
    $CutPath = ''	# New Current Foldername
  
    for ($i = 0; $i -lt $WordArray.Length; $i++) {
        if ($maxlen - ($CutPath.Length + $WordArray[$i].Length) -gt 0) {
            # if word fits in new name
            $CutPath += $WordArray[$i] + $SplitChar	# add it back to new name
        }
        elseif ($Cut_On_Letter_Level) {
            if ($CutPath.Length -eq 0) { $CutPath = $WordArray[0].substring(0, $maxlen - 3) + '... ' } # if foldername is one large word shorten it to maxlen and end it  with ... ( = foldernameblablablaba... )
            else { $CutPath += '... ' } # if foldername consist of words and they exced maxlen, append ...
            break; # if maxlen reached then break loop
        }
        else {
            $CutPath += '...'
            break; # if maxlen reached then break loop
        }
    }
	
    return $CutPath
}

################################################################################################

$global:DefaultEnvPaths = @{

    WindowsAppsFolder = 'C:\Users\M01947\AppData\Local\Microsoft\WindowsApps' #TODO

    # Some default
    winget            = "$env:HOMEDRIVE\$env:HOMEPATH\AppData\Local\Microsoft\WindowsApps"
    System32          = 'C:\Windows\system32'
    wbem              = 'C:\Windows;C:\Windows\System32\Wbem'
    OpenSSH           = 'C:\Windows\System32\OpenSSH\'
    ThinPrint         = 'C:\Program Files\ThinPrint Client\'
    ThinPrintx86      = 'C:\Program Files (x86)\ThinPrint Client\'

    # Code Editors
    VSCode            = (Resolve-Path -Path "$env:AppPath\_EnvPath_Apps\Microsoft VS Code\bin" -ErrorAction SilentlyContinue).Path `
        ?? 'C:\Program Files\Microsoft VS Code\bin'
    #"C:\Users\Daniel\AppData\Local\Programs\Microsoft VS Code\bin"

    # Powershell
    WindowsPowerShell = 'C:\Windows\System32\WindowsPowerShell\v1.0\'
    PowerShell        = (Resolve-Path -Path "$env:AppPath\_EnvPath_Apps\PowerShell\7.5" -ErrorAction SilentlyContinue).Path `
        ?? 'C:\Program Files\PowerShell\7'


    # CLI Tools
    AzureCLI          = (Resolve-Path -Path "$env:AppPath\_EnvPath_Apps\CLI\Azure\CLI2\wbin" -ErrorAction SilentlyContinue).Path `
        ?? 'C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin'
    sqlcmd            = "$env:AppPath\_EnvPath_Apps\CLI\Microsoft SQL Server\sqlcmd"
 
    terraform         = $env:TerraformNewestVersion 
    terraformDocs     = $env:TerraformDocsNewestVersion


    # TODO - Sort for newest Version
    nodejs            = (Resolve-Path -Path "$env:AppPath\_EnvPath_Apps\nodejs\18.12.1" -ErrorAction SilentlyContinue).Path `
        ?? 'C:\Program Files\nodejs'

    gitbin            = (Resolve-Path -Path "$env:AppPath\_EnvPath_Apps\Git\2.38\bin" -ErrorAction SilentlyContinue).Path 
    gitcmd            = (Resolve-Path -Path "$env:AppPath\_EnvPath_Apps\Git\2.38\cmd" -ErrorAction SilentlyContinue).Path `
        ?? 'C:\Program Files\Git\cmd'
    git               = (Resolve-Path -Path "$env:AppPath\_EnvPath_Apps\Git\2.38" -ErrorAction SilentlyContinue).Path `
        ?? 'C:\Program Files\Git'

    dotnet            = (Get-ChildItem -Path 'C:\Program Files' -Directory -Filter 'dotnet').FullName
    dotnet_1Drv       = (Get-ChildItem -Path "$env:AppPath\_EnvPath_Apps" -Directory -Filter 'dotnet').FullName

    vlang             = (Get-ChildItem -Path "$env:AppPath\_EnvPath_Apps" -Directory -Filter 'v')
    clang             = 'C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.34.31933\bin\Hostx86\x86'
    cinlude           = 'C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.34.31933\include'
    cmake             = "$env:AppPath\_EnvPath_Apps\cmake\3.24\bin"
    gnumake           = "$env:AppPath\_EnvPath_Apps\GnuWin32\3.8\bin"

    java              = "$env:AppPath\_EnvPath_Apps\javaSDK\jdk-10.0.2\bin"

    docker            = 'C:\Program Files\Docker\Docker\resources\bin'


    gpg               = (Resolve-Path -Path 'C:\Program Files (x86)\GnuPG\bin' -ErrorAction SilentlyContinue).Path `
        ?? 'C:\Users\M01947\AppData\Local\Programs\GnuPG\bin'
    tflint            = "$env:AppPath\_EnvPath_Apps\tflint\v0.44.0"
}

$SettingsJsonDefaults = [PSCustomObject]@{

    # Profiles
    'workbench.experimental.settingsProfiles.enabled'          = $true

    # Git
    'git.enableCommitSigning'                                  = $env:USERNAME -ne 'M01947'
    'git-graph.repository.commits.showSignatureStatus'         = $env:USERNAME -ne 'M01947'
    'git-graph.repository.sign.tags'                           = $env:USERNAME -ne 'M01947'
    'git-graph.repository.sign.commits'                        = $env:USERNAME -ne 'M01947'

    # Blockman
    'blockman.n04ColorComboPreset'                             = 'Classic Dark 1 (Super gradients)'
    'blockman.n04Sub04RightSideBaseOfBlocks'                   = 'Rightmost Edge Of Viewport'
    'blockman.n23AnalyzeSquareBrackets'                        = $true
    'blockman.n28TimeToWaitBeforeRerenderAfterLastChangeEvent' = 1.1
    'blockman.n30TimeToWaitBeforeRerenderAfterLastScrollEvent' = 0.2
    'blockman.n33A01B2FromDepth0ToInwardForAllBackgrounds'     = '45,0,0,2; none'
    'blockman.n21BorderRadius'                                 = 4
    'blockman.n31RenderIncrementBeforeAndAfterVisibleRange'    = 50
    'blockman.n20CustomColorOfDepth0Border'                    = 'none'


    ############################################
    'workbench.iconTheme'                                      = 'vscode-icons'
    'terminal.integrated.fontFamily'                           = "Jetbrains Mono, Consolas, 'Courier New', monospace"
    'editor.fontFamily'                                        = "Jetbrains Mono, Consolas, 'Courier New', monospace"
    'editor.fontLigatures'                                     = $true

    'workbench.colorTheme'                                     = 'Default Dark+'
    'scm.alwaysShowRepositories'                               = $true
    'git.enabled'                                              = $true
    'git.path'                                                 = "$($global:DefaultEnvPaths['GITCMD'])/git.exe"
    'gitlens.advanced.repositorySearchDepth'                   = 5

    'terminal.integrated.defaultProfile.windows'               = 'PS 7'
    'terminal.integrated.profiles.windows'                     = @{
        'Git Bash'                       = $null
        'Azure Cloud Shell (Bash)'       = $null
        'Azure Cloud Shell (PowerShell)' = $null
        'JavaScript Debug Terminal'      = $null
        'Command Prompt'                 = $null
        'PowerShell'                     = $null
        'PS 7'                           = @{
            'icon' = 'terminal-powershell'
            'path' = @(
                "$($global:DefaultEnvPaths['PowerShell'])/pwsh.exe"
            )
            'args' = @()
        }
        'Dev CMD'                        = @{
            'path' = @(
                "${env:windir}/Sysnative/cmd.exe",
                "${env:windir}/System32/cmd.exe"
            )
            'args' = @(
                '/k',
                'C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat'
            )
            'icon' = 'terminal-cmd'
        }
        #'CMD'                            = @{
        #    'path' = @(
        #        "${env:windir}/Sysnative/cmd.exe",
        #        "${env:windir}/System32/cmd.exe"
        #    )
        #    'args' = @()
        #    'icon' = 'terminal-cmd'
        #}
        'Node'                           = @{
            'path' = @(
                "$($global:DefaultEnvPaths['NodeJs'])/node.exe"
            )
            'args' = @()
            'icon' = 'terminal-cmd'
        }
    }
}




Start-Job -ArgumentList $SettingsJsonDefaults -ScriptBlock {
    
        
    $settingsJsonItems = @(
        Get-Item -Path "$env:APPDATA\Code\User\settings.json"
        Get-ChildItem -Path "$env:APPDATA\Code\User\Profiles" -Filter 'settings.json' -Recurse | ForEach-Object { $_ }
    )


    foreach ($settingsItem in $settingsJsonItems) {

        $settingsJsonContent = Get-Content -Path $settingsItem.FullName | ConvertFrom-Json

        foreach ($setting in $args[0].PSObject.Properties) {

            $settingsJsonContent | Add-Member -MemberType $setting.MemberType `
                -Name $setting.Name -Value $setting.Value -Force
        }
        $settingsJsonContent | ConvertTo-Json -Depth 8 | Out-File -FilePath $settingsItem.FullName

    }
        
}
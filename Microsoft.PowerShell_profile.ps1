
$env:SECRET_TOKEN_STORE = Join-Path -Path $env:APPDATA -ChildPath "SECRET_TOKEN_STORE/TOKEN_STORE.json"
(Get-Content -Path $env:SECRET_TOKEN_STORE | ConvertFrom-Json).PSObject.Properties | `
    ForEach-Object { 
    Write-Host "Loading '$($_.Name)' from Secret Store"
    if ($_.value[0] -eq '´') {
        $value = Invoke-Expression -Command $_.value.substring(1)
        $null = New-Item -Path "env:$($_.Name)" -Value $value -Force
    }
    else {
        $null = New-Item -Path "env:$($_.Name)" -Value $_.Value -Force  
    }
}

function Invoke-AzDevOpsRest {

    param(
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("GET", "POST", "PUT", "UPDATE", "DELETE")]
        $Method,

        [Parameter()]
        [System.String]
        $API_Project,

        [Parameter()]
        [System.String]
        $API_Team,

        [Parameter()]
        [System.String]
        $URI,

        [Parameter()]
        [System.Collections.Hashtable]
        $body = @{},

        [Parameter()]
        [System.String]
        $Property = "value",

        [Parameter()]
        [ValidateSet("DC", "RD")] # DC-Migration, RD-Redeployment
        $Project = "DC"
    )

    $ProjectName = "DC%20Azure%20Migration"
    $Team = "DC%20Azure%20Migration%20Team"
    if ($Project -eq "RD") {
        $ProjectName = "DC%20ACF%20Redeployment"
        $Team = ""
    }

    $TargetUri = "https://$(Join-Path -Path "dev.azure.com/baugruppe/$ProjectName/" -ChildPath $API_Project)".Replace("\", "/")
    if ($API_Team) {
        $TargetUri = "https://$(Join-Path -Path "dev.azure.com/baugruppe/$ProjectName/$Team/" -ChildPath $API_Team)".Replace("\", "/")
    }
    elseif ($URI) {
        $TargetUri = $URI
    }

    Write-Host "    "$TargetUri

    try {
        $headers = @{ 
            Authorization  = "Basic $env:AzureDevops_HEADER"
            "Content-Type" = $Method.ToLower() -eq "get" ? "application/x-www-form-urlencoded" : "application/json"
        }

        $response = Invoke-RestMethod -Method $Method -Uri $TargetUri -Headers $headers -Body ($body | ConvertTo-Json -Compress)

        if ($Property) {
            return ($response.PSObject.Properties | Where-Object { $_.Name -like $Property }).Value 
        }
        else {
            return $response
        }

    }
    catch {
        Write-Host "ERROR"
        throw $_
    }
   
}


function New-BranchFromWorkitem {

    [Alias("gitW")]
    param (
        [Parameter()]
        [System.Collections.ArrayList]
        $SearchTags = [System.Collections.ArrayList]::new()
    )
    
    $currentIteration = Invoke-AzDevOpsRest -Method GET -API_Team "/_apis/work/teamsettings/iterations?`$timeframe=current&api-version=7.1-preview.1"
    $workItems = Invoke-AzDevOpsRest -Method GET -Property "WorkItemRelations" -API_Team "/_apis/work/teamsettings/iterations/$($currentIteration.Id)/workitems?api-version=7.1-preview.1"

    $body = @{
        ids    = $workItems.target.id
        fields = @(
            "System.Id",
            "System.Title",
            "System.AssignedTo",
            "System.WorkItemType",
            "Microsoft.VSTS.Scheduling.RemainingWork"
        )
    }

    $workItems = (Invoke-AzDevOpsRest -Method POST -API_Project "/_apis/wit/workitemsbatch?api-version=7.1-preview.1" -body $body).fields | Where-Object { $_.'System.AssignedTo'.uniqueName -like "daniel.landau@brz.eu" }

    $workItem = Get-PreferencedObject -SearchObjects $workItems -SearchTags $SearchTags -SearchProperty "System.Title"
    
    $isRepo = (Get-ChildItem -Path . -Directory -Hidden -Filter '.git').Count -gt 0
    
    if (!$isRepo) {
        Write-Host "Please exexcute command inside a Repository"
    }
    elseif ($workItem) {


        $transformedTitle = $workItem.'System.Title'.toLower().split(' ') -join '-'
        $branchName = "features/$($workItem.'System.id')-$transformedTitle"

        $byteArray = [System.BitConverter]::GetBytes((Get-Random))
        $hex = [System.Convert]::ToHexString($byteArray)
        git stash save "st-$hex"
        git checkout master
        git pull origin master
        git checkout dev
        git pull origin dev
        git checkout -b "$branchName"
        git stash pop
    }

}

########################################################################################################################
########################################################################################################################
########################################################################################################################
$env:VSCodeSettings = (Resolve-Path -Path "$env:appdata/code/user/settings.json").Path
#$VSCodeSettings = (Get-Content -Path $env:VSCodeSettings) | ConvertFrom-Json 
#$VSCodeSettings | Add-Member -MemberType NoteProperty -Name "editor.tabSize" -Value 2
#$VSCodeSettings | Add-Member -MemberType NoteProperty -Name "editor.fontFamily" -Value "Jetbrains Mono, Consolas, \'Courier New\', monospace"
#$VSCodeSettings | Add-Member -MemberType NoteProperty -Name "editor.fontLigatures" -Value true
#$VSCodeSettings | ConvertTo-Json -Depth 4 | Out-File -Path $env:VSCodeSettings 

# $env:TerraformPath = (Resolve-Path  "$env:APPDATA/../Local/Microsoft/WindowsApps/terraform").Path
$env:TerraformPath = (Resolve-Path "$env:OneDrive/Dokumente/Apps/terraform/").Path
$env:TerraformDownloadSource = "https://releases.hashicorp.com/terraform/"

$env:InitialEnvsPaths = $env:Path
$env:RepoPath = (Resolve-Path  "$env:Userprofile/Documents/Repos").Path

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

        gitcmd            = "C:\Program Files\Git\cmd"
        git               = "C:\Program Files\Git"

        WindowsPowerShell = "C:\Windows\System32\WindowsPowerShell\v1.0\"
        PowerShell        = "C:\Program Files\PowerShell\7\"

        AzureCLI          = "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin"
        nodejs            = "C:\Program Files\nodejs\"
        VSCode            = "C:\Program Files\Microsoft VS Code\bin"

        WindowsAppsFolder = "C:\Users\M01947\AppData\Local\Microsoft\WindowsApps"

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

function Get-TerraformNewestVersion {

    param ()

    $versions = (Invoke-WebRequest -Method GET -Uri $env:TerraformDownloadSource).Links.href `
    | Where-Object { $_ -match "^\/terraform\/\d.\d.\d$" }

    $newVersion = $versions[0].split("/")[2]
    $downloadZipFile = "$env:USERPROFILE\downloads/terraform_$newVersion`_temp-$(Get-Random).zip"
    Invoke-WebRequest -Method GET -Uri "$env:TerraformDownloadSource$newVersion/terraform_$newVersion`_windows_amd64.zip" -OutFile  $downloadZipFile

    $newTerraformFolder = Join-Path -Path $env:TerraformPath -childPath "/v$newVersion"
    if (!(Test-Path -Path $newTerraformFolder)) {
        New-Item -ItemType directory $newTerraformFolder -Force
    }

    $terraformZip = [System.IO.Compression.ZipFile]::OpenRead($downloadZipFile)
    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($terraformZip.Entries[0], "$newTerraformFolder\terraform.exe", $true)

}

function Switch-Terraform {

    [Alias("tf")]
    param (
        [Parameter()]
        [System.String]
        $Version = "latest"
    )
    
    if ($Version.Length -eq 2 -and $Version.ToLower()[0] -eq 'v' -and "0123456789".Contains($Version[1])) {
        $Version = "v1.1.$($Version[1])"
    }

    # Latest
    $TerraformFolder = $null

    if ($Version -and $Version.ToLower() -ne "latest") {
        # Write-Host (Get-ChildItem -Path $env:TerraformPath -Directory -Filter $Version)
        $TerraformFolder = (Get-ChildItem -Path $env:TerraformPath -Directory -Filter $Version)
    }
    else {
        $TerraformFolder = (Get-ChildItem -Path $env:TerraformPath -Directory | Sort-Object -Property Name -Descending)[0]
    }

    # Write-Host $TerraformFolder
    Add-EnvPaths -RemovePaths @($env:TerraformPath) -AdditionalPaths @{
        Terraform = $($TerraformFolder.FullName)
    } 

    Write-Host
    terraform --version
    Write-Host
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

########################################################################################################
########################################################################################################
########################################################################################################

function Search-AzResource {
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]
        $ResourceName,
    
        [Parameter(Mandatory = $true)]
        [System.String]
        $ResourceType
    )
    
    $query = "
        resources 
            | where type =~ '$ResourceType'
            | where name contains '' 
    "

    foreach ($name in $ResourceName) {
        $query += "or name contains '$name'"
    }
    
    $results = [System.Collections.ArrayList]::new()
    foreach ($result in (Search-AzGraph -ManagementGroup (Get-AzContext).Tenant.Id -Query $query)) {
        $null = $results.Add($result)
    }

    return Get-PreferencedObject -SearchObjects $results -SearchTags $ResourceName   
}

function Search-AzStorageAccount {
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]
        $StorageAccountName
    )
    
    return Search-AzResource -ResourceName $StorageAccountName -ResourceType "microsoft.storage/storageaccounts"

}

function Search-AzFunctionApp {
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]
        $FunctionAppName
    )
    
    return Search-AzResource -ResourceName $FunctionAppName -ResourceType "microsoft.web/sites"

}

function Search-AzFunctionAppConfiguration {

    [Alias("FAConf")]
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]
        $FunctionAppName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()] 
        $ConfigName
    )

    if ($ConfigName.GetType().Name -eq "String") {
        $ConfigName = @( $ConfigName )
    }
    $FunctionApp = Search-AzFunctionApp -FunctionAppName $FunctionAppName
    if ($FunctionApp) {

        Write-Host "https://management.azure.com$($FunctionApp.ResourceId)/config/appsettings/list?api-version=2021-02-01"
        $response = Invoke-AzRestMethod -Method POST -Uri "https://management.azure.com$($FunctionApp.ResourceId)/config/appsettings/list?api-version=2021-02-01"
        $AppSettings = [System.Collections.ArrayList]::new()
        ($response.Content | ConvertFrom-Json).properties.PSObject.Properties | ForEach-Object { $null = $AppSettings.Add($_) }
        return Get-PreferencedObject -SearchObjects $Appsettings -SearchTags $ConfigName
    }

}

function Search-AzStorageAccountContext {

    [Alias("STCtx")]
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]
        $StorageAccountName
    )

    $currentContext = Get-AzContext
    $StorageAccount = Search-AzStorageAccount -StorageAccountName $StorageAccountName
    if ($StorageAccount) {
        $null = Set-AzContext -Tenant $currentContext.Tenant -SubscriptionId $StorageAccount.subscriptionId
        $key = Get-AzStorageAccountKey -ResourceGroupName $StorageAccount.resourceGroup -Name $StorageAccount.name
        $ctx = New-AzStorageContext -StorageAccountName $StorageAccount.name -StorageAccountKey $key[0].Value
        $null = Set-AzContext -Context $currentContext
        return $ctx;
    }

}

function Search-AzStorageAccountKey {

    [Alias("STkey")]
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]
        $StorageAccountName,

        [Parameter()]
        [ValidateSet("Key1", "Key2", "Both")]
        $KeySet = "Key1"
    )

    $currentContext = Get-AzContext
    $StorageAccount = Search-AzStorageAccount -StorageAccountName $StorageAccountName
    if ($StorageAccount) {
        $null = Set-AzContext -Tenant $currentContext.Tenant -SubscriptionId $StorageAccount.subscriptionId
        $key = Get-AzStorageAccountKey -ResourceGroupName $StorageAccount.resourceGroup -Name $StorageAccount.name
        $null = Set-AzContext -Context $currentContext

        if ($KeySet -eq "Key1") {
            return $key[0].Value
        }
        elseif ($KeySet -eq "Key2") {
            return $key[1].Value
        }
        elseif ($KeySet -eq "Both") {
            return $key
        }
    }
}

########################################################################################################
########################################################################################################
########################################################################################################

function Open-RepositoryVSCodeDevOps {
    [Alias("VCD")]
    param (
        [Parameter()]
        [System.Collections.ArrayList]
        $RepositoryName,

        [Parameter()]
        [ValidateSet("DC", "RD")] # DC-Migration, RD-Redeployment
        $Project = "DC"
    )

    Open-RepositoryVSCode -RepositoryName $RepositoryName -Method devops -Project $Project
}
function Open-RepositoryVSCode {

    [Alias("VC")]
    param (
        [Parameter()]
        [System.Collections.ArrayList]
        $RepositoryName,

        [Parameter()]
        [ValidateSet("DC", "RD")] # DC-Migration, RD-Redeployment
        $Project = "DC",

        [Parameter()]
        [ValidateSet("local", "devops")]
        $Method = "local"
    )

    $ReposLocation = Get-ChildItem -Path $env:RepoPath -Directory | `
        Where-Object { $_.Name -like "_$Project*" } 

        
    $Repos = Get-ChildItem -Path $ReposLocation.FullName -Directory | `
        Where-Object { (Get-ChildItem -Path $_.FullName -Hidden -Filter '.git') } 

    $Repos = $Repos ?? ([System.Collections.ArrayList]::new())
    if ($Repos -isnot [System.Collections.ArrayList]) {
        $Repos = @($Repos)
    }
    if($Repos) {
        $ChosenRepo = Get-PreferencedObject -SearchObjects $Repos -SearchTags $RepositoryName
    }
    if ($ChosenRepo -AND $Method -eq "local") {
        code $ChosenRepo.FullName
    }
    else {

        $response = Invoke-AzDevOpsRest -Method GET -Property "value" -API_Project "_apis/git/repositories?api-version=7.1-preview.1" -Project $Project
        $preferedObject = Get-PreferencedObject -SearchObjects $response -SearchTags $RepositoryName
        if ($preferedObject) {
            $preferedObject
            git clone $preferedObject.remoteUrl (Join-Path -Path $ReposLocation -ChildPath $preferedObject.name)
            Open-RepositoryVSCode -RepositoryName $RepositoryName
        }

    }
}

function Switch-GitConfig {

    [Alias("sc")]
    param(
        [Parameter()]
        [ValidateSet("brz", "git")]
        $config = "git"
    )

    if ($config -eq "brz") {
        git config --global user.name "Daniel Landau"
        git config --global user.email "daniel.landau@brz.eu"      
    }
    elseif ($config -eq "git") {
        git config --global user.name "LemurDaniel"
        git config --global user.email "landau.daniel.1998@gmail.com"  
    }

    Write-Host "Current Git Profile:"
    Write-Host "    $(git config  --global user.name )"
    Write-Host "    $(git config  --global user.email )"
    Write-Host ""
}

# Invoke-WebRequest -Method GET -Au -Uri "https://dev.azure.com/baugruppe/_apis/projects?api-version=2.0"
########################################################################################################
########################################################################################################
########################################################################################################




Add-EnvPaths
Switch-Terraform

if ( (terraform --version --json | ConvertFrom-Json).terraform_outdated) {
    Get-TerraformNewestVersion
    Switch-Terraform
}
#if ((Get-AzContext -ListAvailable).Count -eq 0) {
#    Connect-AzAccount
#}
#if ((az account list --all).Count -lt 2) {
#    az login
#}

Switch-GitConfig






########################################################################################################
########################################################################################################
########################################################################################################


function prompt {

	if( (Get-Location | Split-Path -NoQualifier).Equals("\") ) { return $loc } # Edgecase if current folder is a drive
  
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
  $path = $Drive + "\" # Start with drive
  $path += $Parent.substring(3, $Parent.length-3) + "\"
  $path += $Leaf # append foldername
  
  return "$path> "
}

function shorten_path  {
	param (
        [string]$InputString,
		[char]$SplitChar,
		[int]$MaxLen,
		[bool]$Cut_On_Letter_Level
    )
	if ($InputString.length+1 -lt $MaxLen) { return $InputString }
	
	# Section 1 Code shortens the Current Foldername if too long 
	$WordArray = $InputString.split($SplitChar)  # Turn Foldername in Array of Words (if multiple Words in Name)
	$CutPath = ""	# New Current Foldername
  
	for($i = 0; $i -lt $WordArray.Length; $i++){
		if($maxlen - ($CutPath.Length + $WordArray[$i].Length) -gt 0) {	# if word fits in new name
			$CutPath += $WordArray[$i]+$SplitChar	# add it back to new name
		} elseif($Cut_On_Letter_Level) {
			if($CutPath.Length -eq 0) { $CutPath = $WordArray[0].substring(0, $maxlen-3)+"... " } # if foldername is one large word shorten it to maxlen and end it  with ... ( = foldernameblablablaba... )
			else { $CutPath += "... " } # if foldername consist of words and they exced maxlen, append ...
			break; # if maxlen reached then break loop
		} else {
			$CutPath += "..."
			break; # if maxlen reached then break loop
		}
	}
	
	return $CutPath
}
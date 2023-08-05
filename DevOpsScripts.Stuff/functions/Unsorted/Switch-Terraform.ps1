<#
    .SYNOPSIS
    Switches the current Terraform Version.

    .DESCRIPTION
    Switches the current Terraform Version, based on an API-Call quering the latest versions.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None.

    
    .LINK
        
#>
function Switch-Terraform {
    
    [CmdletBinding()]
    param ()

    <#
# CREDITS: Tim Krehan (tim.krehand@brz.eu)
# Dynamic Parameters
#>
    DynamicParam {
        $AttributCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
        $ParameterAttribute = [System.Management.Automation.ParameterAttribute]::new()
        $ParameterAttribute.Mandatory = $false
        $ParameterAttribute.DontShow = $false
        $ParameterAttribute.Position = 0
        $ParameterAttribute.ParameterSetName = 'specificversion'
        $ParameterAttribute.ValueFromPipeline = $true
        $ParameterAttribute.ValueFromPipelineByPropertyName = $false
        $ParameterAttribute.ValueFromRemainingArguments = $false
        $AttributCollection.Add($ParameterAttribute)

        $tfBinarys = 'https://releases.hashicorp.com/terraform'
        $res = Invoke-WebRequest "$tfBinarys"
        $remoteVersions = $res.Links |
        Select-Object @{
            Name       = 'Version'
            Expression = {
                [version]($_.href -replace '^\/terraform\/(\d.\d{1,2}.\d{1,2})\/', "`$1")
            }
        } |
        Select-Object *, @{
            Name       = 'Target'
            Expression = {
                # I use WSL, because of that, i must allways use the windows exe file :)
                # if (!$IsLinux) {
                $tfBinarys + $_.href + "/$($_.version)/terraform_$($_.version)_windows_amd64.zip"
                # }
                # else {
                #   $tfBinarys + $_.href + "/$($_.version)/terraform_$($_.version)_linux_arm.zip"
                # }
            }
        } |
        Where-Object Version -Is [Version] |
        Where-Object Version -GE ([Version]'1.0.0') 

        $ValidateSetOptions = [string[]]($remoteVersions.Version | ForEach-Object { $_.toString() })
        $ValidateSetOptions = $ValidateSetOptions | Sort-Object -Descending
        $AttributCollection.Add((New-Object System.Management.Automation.ValidateSetAttribute($ValidateSetOptions)))
        $RunTimeParameter = [System.Management.Automation.RuntimeDefinedParameter]::new('TFVersion', [version], $AttributCollection)
        $RuntimeParamDic = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
        $RuntimeParamDic.Add('TFVersion', $RunTimeParameter)

        return $RuntimeParamDic
    }

    Begin {
        $null = $PsBoundParameters.GetEnumerator() | ForEach-Object { New-Variable -Name $_.Key -Value $_.Value -ErrorAction 'SilentlyContinue' }

        $TerraformInstallationFolder = (![System.String]::isNullOrEmpty($env:TerraformPath) ? $env:TerraformPath : "$env:USERPROFILE/terraform")
        $TerraformActiveFolder = "$env:APPDATA\terraform\active"

        if (!(Test-Path $TerraformActiveFolder)) {
            $TerraformActiveFolder = New-Item -ItemType Directory -Path $TerraformActiveFolder
        }
        else {
            $TerraformActiveFolder = Get-Item -Path $TerraformActiveFolder
        }

        if (!(Test-Path $TerraformInstallationFolder)) {
            $TerraformInstallationFolder = New-Item -ItemType Directory -Path $TerraformInstallationFolder
        }
        else {
            $TerraformInstallationFolder = Get-Item -Path $TerraformInstallationFolder
        }

        $TerraformInstallations = Get-ChildItem -Path $TerraformInstallationFolder
        $EnvironmentPaths = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::User) -split ';' | `
            Where-Object { $_ -notlike "$($TerraformActiveFolder.FullName)*" }

        $EnvironmentPaths = @($TerraformActiveFolder.Fullname, ($EnvironmentPaths -join ';')) -join ';'
        [System.Environment]::SetEnvironmentVariable('Path', $EnvironmentPaths, [System.EnvironmentVariableTarget]::User)
        [System.Environment]::SetEnvironmentVariable('Path', $EnvironmentPaths, [System.EnvironmentVariableTarget]::Process)
  
    }
    Process {

        if ([string]::IsNullOrEmpty($TFVersion)) {
            $TFVersion = $ValidateSetOptions | Sort-Object | Select-Object -Last 1
        }
        else {
            $null = Set-UtilsCache -Object $TFVersion.ToString() -Type TerraformVersion -Identifier Active -Forever
        }
        

        if ("v$TFVersion" -notin $TerraformInstallations.Name) {
            $TerraformTarget = "$($TerraformInstallations[0].Parent)/v$TFVersion"
            $TerraformInstallations += New-Item -Path $TerraformTarget -ItemType Directory -Force
                           
            $remoteTarget = $remoteVersions | Where-Object -Property 'Version' -EQ -Value $TFVersion
            Invoke-WebRequest -Method GET -Uri $remoteTarget.Target -OutFile "$TerraformTarget/terraform.zip"
            $terraformZip = [System.IO.Compression.ZipFile]::OpenRead("$terraformTarget/terraform.zip")
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($terraformZip.Entries[0], "$TerraformTarget/terraform.exe", $true)
        }

    }
    End {
        $activeVersion = Get-UtilsCache -Type TerraformVersion -Identifier Active
        if ([System.String]::IsNullOrEmpty($activeVersion)) {
            $activeVersion = Set-UtilsCache -Object $TFVersion.ToString() -Type TerraformVersion -Identifier Active -Forever
        }

        $terraformExists = (Get-Command -Name 'terraform' -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0
        $terraformOutdated = $terraformExists -AND (terraform --version --json | ConvertFrom-Json).terraform_version -ne $activeVersion
        if (!$terraformExists -OR $terraformOutdated) {
            $terraformTarget = $TerraformInstallations | Where-Object -Property Name -EQ "v$activeVersion"
            $terraformZip = [System.IO.Compression.ZipFile]::OpenRead("$terraformTarget/terraform.zip")
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($terraformZip.Entries[0], "$TerraformActiveFolder/terraform.exe", $true)
        }

        Write-Host 
        terraform --version
        Write-Host

    }
}
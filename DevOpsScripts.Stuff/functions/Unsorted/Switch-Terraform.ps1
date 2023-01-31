

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
    
    [Alias('tf')]
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
        $TerraformFolder = $env:TerraformPath
        $TerraformInstallations = Get-ChildItem -Path $env:TerraformPath
        $TerraformTarget = ''
    }
    Process {

        if ([string]::IsNullOrEmpty($TFVersion)) {
            $TFVersion = $ValidateSetOptions | Sort-Object | Select-Object -Last 1
        }
        
        $TerraformTarget = Join-Path -Path $TerraformFolder -ChildPath "v$($TFVersion)"
        if ("v$($TFVersion)" -notin $TerraformInstallations.Name) {
           
            $remoteTarget = $remoteVersions | Where-Object -Property 'Version' -EQ -Value $TFVersion
            $downloadZipFile = "$env:USERPROFILE\downloads/terraform_$TFVersion`_temp-$(Get-Random).zip"
            Invoke-WebRequest -Method GET -Uri $remoteTarget.Target -OutFile $downloadZipFile
            $null = New-Item -Path $TerraformTarget -ItemType Directory -Force
            $terraformZip = [System.IO.Compression.ZipFile]::OpenRead($downloadZipFile)
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($terraformZip.Entries[0], "$TerraformTarget\terraform.exe", $true)
        }

    }
    End {
        Add-EnvPaths -AdditionalPath Terraform -AdditionalValue $TerraformTarget

        Write-Host
        terraform --version
        Write-Host
    }
}
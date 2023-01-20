function Open-RepositoryDynamic {

    [Alias('VCD')]
    [cmdletbinding()]
    param (
        [Parameter()]
        [System.String]
        $name,

        [Parameter()]
        [switch]
        $onlyDownload,

        [Parameter()]
        [PSCustomObject]
        $RepositoryId
    )

    DynamicParam {
        $AttributCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
        $ParameterAttribute = [System.Management.Automation.ParameterAttribute]::new()
        $ParameterAttribute.Mandatory = $false
        $ParameterAttribute.DontShow = $false
        $ParameterAttribute.Position = 0
        $ParameterAttribute.ParameterSetName = 'repository'
        $ParameterAttribute.ValueFromPipeline = $false
        $ParameterAttribute.ValueFromPipelineByPropertyName = $false
        $ParameterAttribute.ValueFromRemainingArguments = $false
        $AttributCollection.Add($ParameterAttribute)
  
        $ValidateSetOptions = [String[]]((Get-ProjectInfo 'repositories.name') | Sort-Object -Property name)
        $AttributCollection.Add((New-Object System.Management.Automation.ValidateSetAttribute($ValidateSetOptions)))
        $RunTimeParameter = [System.Management.Automation.RuntimeDefinedParameter]::new('RepositoryName', [System.String], $AttributCollection)
        $RuntimeParamDic = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
        $RuntimeParamDic.Add('RepositoryName', $RunTimeParameter)

        return $RuntimeParamDic
    }

    Begin {

        $repositories = Get-ProjectInfo 'repositories'
        if ($RepositoryId) {
            $repository = $repositories | Where-Object -Property id -EQ -Value $RepositoryId
        }
        else {
            $repositoryName = [System.String]::IsNullOrEmpty($RepositoryName) ? $name : $repositoryName
            $repository = $repositories | Where-Object -Property name -EQ -Value $RepositoryName
        }

        if (!$repository) {
            Write-Host -Foreground RED 'No Repository Found!'
            return
        }
    }
    Process {

        #$adUser = Get-AzADUser -Mail (Get-AzContext).Account.Id # Takes long initialy
        #$userName = $adUser.DisplayName
        #$userMail = $adUser.UserPrincipalName

        $userName = (Get-AzContext).Account.Id -replace '(@{1}.+)', '' -replace '\.', ' ' -replace '', ''
        $userMail = (Get-AzContext).Account.Id

        $TextInfo = (Get-Culture -Name 'de-DE').TextInfo
        $userName = $TextInfo.ToTitleCase($userName)

        if (!(Test-Path $repository.Localpath)) {
            New-Item -Path $repository.Localpath -ItemType Directory
            git -C $repository.Localpath clone $repository.remoteUrl .
        }      

        $item = Get-Item -Path $repository.Localpath 
        $null = git config --global --add safe.directory ($item.Fullname -replace '[\\]+', '/' )
        $null = git -C $repository.Localpath config --local commit.gpgsign false
        $null = git -C $repository.Localpath config --local user.name "$userName" 
        $null = git -C $repository.Localpath config --local user.email "$userMail"

        if (-not $onlyDownload) {
            code $repository.Localpath
        } 

        return $item

    }
    End {}
}
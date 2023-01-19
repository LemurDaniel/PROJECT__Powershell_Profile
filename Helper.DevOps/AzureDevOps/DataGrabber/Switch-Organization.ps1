
function Switch-Organization {

    [Alias('Set-OrgContext', 'swo')]
    [CmdletBinding()]
    param ()

    DynamicParam {
        $AttributCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
        $ParameterAttribute = [System.Management.Automation.ParameterAttribute]::new()
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.DontShow = $false
        $ParameterAttribute.Position = 0
        $ParameterAttribute.ParameterSetName = 'organization'
        $ParameterAttribute.ValueFromPipeline = $false
        $ParameterAttribute.ValueFromPipelineByPropertyName = $false
        $ParameterAttribute.ValueFromRemainingArguments = $false
        $AttributCollection.Add($ParameterAttribute)
  
        $ValidateSetOptions = [String[]]((Get-DevOpsOrganizations).accountName | Sort-Object -Property name)
        $AttributCollection.Add((New-Object System.Management.Automation.ValidateSetAttribute($ValidateSetOptions)))
        $RunTimeParameter = [System.Management.Automation.RuntimeDefinedParameter]::new('Organization', [System.String], $AttributCollection)
        $RuntimeParamDic = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
        $RuntimeParamDic.Add('Organization', $RunTimeParameter)

        return $RuntimeParamDic
    }

    Begin {        
        $null = $PsBoundParameters.GetEnumerator() | `
            ForEach-Object { New-Variable -Name $_.Key -Value $_.Value -ErrorAction 'SilentlyContinue' }
    }
    Process {
        $null = Set-DevOpsCurrentContext -Organization $Organization
        Write-Host -ForegroundColor GREEN "`n   Set Organization Context to '$Organization'`n"
    }
    End {}
    
}
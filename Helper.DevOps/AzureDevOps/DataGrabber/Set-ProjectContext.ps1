
function Set-ProjectContext {

    [Alias('Switch-Project', 'swp')]
    [CmdletBinding()]
    param ()

    DynamicParam {
        $AttributCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
        $ParameterAttribute = [System.Management.Automation.ParameterAttribute]::new()
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.DontShow = $false
        $ParameterAttribute.Position = 0
        $ParameterAttribute.ParameterSetName = 'project'
        $ParameterAttribute.ValueFromPipeline = $false
        $ParameterAttribute.ValueFromPipelineByPropertyName = $false
        $ParameterAttribute.ValueFromRemainingArguments = $false
        $AttributCollection.Add($ParameterAttribute)
  
        $ValidateSetOptions = [String[]]((Get-DevOpsProjects).name | Sort-Object -Property name)
        $AttributCollection.Add((New-Object System.Management.Automation.ValidateSetAttribute($ValidateSetOptions)))
        $RunTimeParameter = [System.Management.Automation.RuntimeDefinedParameter]::new('Project', [System.String], $AttributCollection)
        $RuntimeParamDic = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
        $RuntimeParamDic.Add('Project', $RunTimeParameter)

        return $RuntimeParamDic
    }

    Begin {        
        $null = $PsBoundParameters.GetEnumerator() | `
            ForEach-Object { New-Variable -Name $_.Key -Value $_.Value -ErrorAction 'SilentlyContinue' }
    }
    Process {
        $null = Set-DevOpsCurrentContext -Project $Project
        Write-Host -ForegroundColor GREEN "Set Project Context to '$Project'"
    }
    End {}
    
}

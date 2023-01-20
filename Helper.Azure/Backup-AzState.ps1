
function Switch-AzTenant {

    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]
        $NoDisconnect
    )

    DynamicParam {
        $AttributCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
        $ParameterAttribute = [System.Management.Automation.ParameterAttribute]::new()
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.DontShow = $false
        $ParameterAttribute.Position = 0
        $ParameterAttribute.ParameterSetName = 'tenant'
        $ParameterAttribute.ValueFromPipeline = $false
        $ParameterAttribute.ValueFromPipelineByPropertyName = $false
        $ParameterAttribute.ValueFromRemainingArguments = $false
        $AttributCollection.Add($ParameterAttribute)
  
        $tenants = Get-AzTenant
        $ValidateSetOptions = [String[]]($tenants.Name | Sort-Object -Property name)
        $AttributCollection.Add((New-Object System.Management.Automation.ValidateSetAttribute($ValidateSetOptions)))
        $RunTimeParameter = [System.Management.Automation.RuntimeDefinedParameter]::new('Tenant', [System.String], $AttributCollection)
        $RuntimeParamDic = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
        $RuntimeParamDic.Add('Tenant', $RunTimeParameter)

        return $RuntimeParamDic
    }

    Begin {        
        $null = $PsBoundParameters.GetEnumerator() | `
            ForEach-Object { New-Variable -Name $_.Key -Value $_.Value -ErrorAction 'SilentlyContinue' }
    }
    Process {
        if (!$NoDisconnect) {
            Disconnect-AzAccount
        }
   
        $tenantId = ($tenants | Where-Object -Property Name -EQ -Value $Tenant).id
        Connect-AzAccount -Tenant $tenantId
        az login --tenant $tenantId
    }
    End {}
    
}
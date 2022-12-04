
function Load-SecretObject {
  param (
    [parameter()]
    [PSObject]
    $SecretObject,

    [parameter()]
    [System.String]
    $SecretPrefix,

    [parameter()]
    [System.String]
    $indendation
  )


  $_LOADORDER = $SecretObject.'_LOADORDER' ?? @() 
  $_LOADSILENT = $SecretObject.'_LOADSILENT' ?? @()
  $_LOAD = $_LOADORDER + $_LOADSILENT 
  $SecretObject = $SecretObject | Sort-Object -Property { $_LOADORDER.IndexOf($_.Name) } 

  foreach ($Secret in $SecretObject.PSObject.Properties) {

    if (!$_LOAD.contains($Secret.Name)) {
      continue
    } 
    if (!$_LOADSILENT.contains($Secret.Name)) {
      Write-Host "$indendation + Loading '$($SecretPrefix+$Secret.name)' from Secret Store" # Verbosing
    }

    # Convert to ENV if String or Value
    if ($Secret.value.GetType() -eq [System.String]) {
      $SecretValue = $Secret.value[0] -eq '´' ? (Invoke-Expression -Command $Secret.value.substring(1)) : $Secret.value
      $null = New-Item -Path "env:$($Secret.name)" -Value $SecretValue -Force  
    }
    elseif ($Secret.value.GetType().BaseType -eq [System.Array]) {
      Throw "Can't Load 'System.Array' to ENV"
    }
    else {
      Load-SecretObject -SecretObject $Secret.value -SecretPrefix ($SecretPrefix + $Secret.Name + '_') -indendation ($indendation+'   ')
    }

  }

}
function Get-SecretsFromStore {

  param ( 
    [parameter()]
    [Switch]
    $Show,

    [parameter()]
    [Switch]
    $ShowFull,

    [parameter()]
    [Switch]
    $ShowJSON,

    [parameter()]
    [validateSet('ALL', 'ORG', 'PERSONAL')]
    $SecretStoreSource = 'ALL'
  )

  Load-SecretObject -SecretObject (Get-SecretStore -SecretStoreSource $SecretStoreSource)

}

######################################################################################

function Get-PersonalSecretStore {

  $tokenStore = Get-Content -Path "$env:SECRET_STORE.private.tokenstore.json" | `
    ConvertFrom-Json -Depth 6 | `
    Add-Member -MemberType NoteProperty -Name 'SECRET_STORE_PER__FILEPATH___TEMP' `
    -Value "$env:SECRET_STORE.private.tokenstore.json" -PassThru -Force


  $env:DEVOPS_CURRENT_ORGANIZATION_CONTEXT = $tokenStore.CONFIG.DEVOPS_CURRENT_ORGANIZATION

  return $tokenStore
}

function Get-OrgSecretStore {

  $tokenstore = "$env:SECRET_STORE.$env:DEVOPS_CURRENT_ORGANIZATION_CONTEXT.tokenstore.json"
  return Get-Content -Path $tokenstore | `
    ConvertFrom-Json -Depth 6 | `
    Add-Member -MemberType NoteProperty -Name 'SECRET_STORE_ORG__FILEPATH___TEMP' `
    -Value $tokenstore -PassThru -Force

}

function Get-UnifiedSecretStore {

  $SECRETS_PER = Get-PersonalSecretStore
  $SECRETS_ORG = Get-OrgSecretStore

  return  Get-UnifiedObject -Object1 $SECRETS_PER -Object2 $SECRETS_ORG

}

function Get-SecretStore {
  param (
    [parameter()]
    [validateSet('ALL', 'ORG', 'PERSONAL')]
    $SecretStoreSource = 'ALL'
  )

  if ($SecretStoreSource -eq 'PERSONAL') {
    return Get-PersonalSecretStore
  }
  elseif ($SecretStoreSource -eq 'ORG') {
    return Get-OrgSecretStore
  }
  else {
    return Get-UnifiedSecretStore
  }
}

#############################################################################

function Get-SecretFromStore {
  param (
    [parameter(Mandatory = $true)]
    [System.String]
    $SecretType,

    [parameter()]
    [validateSet('ALL', 'ORG', 'PERSONAL')]
    $SecretStoreSource = 'ALL'
  )

  return (Get-SecretStore -SecretStoreSource $SecretStoreSource)."$SecretType"

}


function Update-SecretStore {
  param (
    [parameter(Mandatory = $true)]
    [System.String]
    $SecretType,

    [parameter(Mandatory = $true)]
    [PSCustomObject]
    $SecretValue,

    [parameter()]
    [System.String]
    $SubSecret,

    [parameter()]
    [Switch]
    $LoadVerbose = $false,

    [parameter()]
    [Switch]
    $LoadSilent = $false,

    [parameter()]
    [validateSet('ALL', 'ORG', 'PERSONAL')]
    $SecretStoreSource = 'ORG'
  )

  if ($LoadVerbose -AND $LoadSilent) {
    Throw 'Both Flags Silent and Verbose Set'
  }

  $SecretObject = Get-SecretStore -SecretStoreSource $SecretStoreSource
  if ($SubSecret.length -gt 0) {
    $SecretObject = $SecretObject."$SecretType"
  }


  $SecretObject | Add-Member -MemberType NoteProperty -Name $SecretType -Value $SecretValue -Force
  if ($LoadVerbose) {
    $_LOADVERBOSE = @((@($SecretType) + $SecretObject._LOADVERBOSE) | Sort-Object | Get-Unique)
    $SecretObject | Add-Member -MemberType NoteProperty -Name '_LOADVERBOSE' -Value $_LOADVERBOSE -Force
  }
  elseif ($LoadSilent) {
    $_LOADSILENT = @((@($SecretType) + $SecretObject._LOADSILENT) | Sort-Object | Get-Unique)
    $SecretObject | Add-Member -MemberType NoteProperty -Name '_LOADSILENT' -Value $_LOADSILENT -Force
  }

  
  if ($SecretStoreSource -eq 'ORG') {
    $SECRET_STORE | ConvertTo-Json -Depth 6 | Out-File -FilePath "$($SECRET_STORE.SECRET_STORE_ORG__FILEPATH___TEMP)" 
  }
  elseif ($SecretStoreSource -eq 'PERSONAL') {
    $SECRET_STORE | ConvertTo-Json -Depth 6 | Out-File -FilePath "$($SECRET_STORE.SECRET_STORE_PER__FILEPATH___TEMP)"
  } 
  
}




function Update-AzTenantSecret {
  param ()
  
  Connect-AzAccount
  $Tenants = Get-AzTenant
  Update-SecretStore -SecretType AZURE_TENANTS -SecretValue $Tenants

}

if (!$env:LOADED_PERSONAL_SECRETS) {
  Write-Host 'ssss'
  Get-SecretStore ALL
  Get-SecretsFromStore -SecretStoreSource 'PERSONAL'
  $env:LOADED_PERSONAL_SECRETS = $true
}

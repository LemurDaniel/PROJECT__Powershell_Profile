
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
    $indendation,

    [parameter()]
    [switch]
    $envFlaggedGlobal,

    [parameter()]
    [switch]
    $loadFlaggedGlobal,

    [parameter()]
    [Switch]
    $show,

    [Parameter()]
    [System.int32]
    $recursionDepth = 0
  )


  $_ORDER = $SecretObject.'_ORDER' ?? @() 
  $_SILENT = $SecretObject.'_SILENT' ?? @()
  $_LOAD = $_ORDER + $_SILENT 
  $SecretObject = $SecretObject | Sort-Object -Property { $_ORDER.IndexOf($_.Name) } 


  $verbosing = ''

  foreach ($Secret in $SecretObject.PSObject.Properties) {

    if (@('_ORDER', '_SILENT').contains($Secret.Name.ToUpper())) {
      continue;
    }

    $envFlaggedLocal = $Secret.name.length -gt 5 -AND $Secret.name.substring(0, 5).ToUpper() -eq '$ENV:'
    $cleanedName = $envFlaggedLocal ? $Secret.name.substring(5) : $secret.name
    $secretPrefixedName = $SecretPrefix + $cleanedName
    $envFlagged = $envFlaggedGlobal -OR $envFlaggedLocal

    # A load flag sets load for all subobjects, and searches for envs
    $loadFlagged = $_LOAD.contains($Secret.Name) -OR $loadFlaggedGlobal

    # $Secret.value.GetType() -eq [PSCustomObject] doesn't work
    if ($Secret.value.GetType().Name -eq 'PSCustomObject' -AND ($envFlagged -OR $loadFlagged)) {
      $verboseStuff = Load-SecretObject -show:$($show) -recursionDepth ($recursionDepth + 1) -envFlagged:$($envFlagged) -loadFlaggedGlobal:$($loadFlagged) `
        -SecretObject $Secret.value -SecretPrefix ($SecretPrefix + $cleanedName + '_') -indendation ($indendation + '   ')

      if ($verboseStuff.length -gt 0) {
        $verbosing = $verbosing + "`n$indendation + Loading '$($secretPrefixedName)' from Secret Store" + $verboseStuff
      }

    }
    elseif ($envFlagged -AND $Secret.value.GetType() -eq [System.String]) {
      $SecretValue = $Secret.value[0] -eq '´' ? (Invoke-Expression -Command $Secret.value.substring(1)) : $Secret.value
      $null = New-Item -Path "env:$secretPrefixedName" -Value $SecretValue -Force  
      $verbosing += "`n$indendation + Loading '$($secretPrefixedName)' from Secret Store"
    }
    elseif ($envFlagged -AND $Secret.value.GetType().BaseType -eq [System.ValueType]) {
      $SecretValue = $Secret.value.toString()
      $null = New-Item -Path "env:$secretPrefixedName" -Value $SecretValue -Force  
      $verbosing += "`n$indendation + Loading '$($secretPrefixedName)' from Secret Store"
    }
    elseif ($envFlagged -AND $Secret.value.GetType().BaseType -eq [System.Array]) {
      Throw "Can't Load 'System.Array' to ENV"
    }

    if ($recursionDepth -eq 0 -AND $verbosing.Length -gt 0 -AND $show) {
      Write-Host $verbosing.Substring(1)
      $verbosing = ''
    }
  }

  return $show ? $verbosing : '' 
}


function Get-SecretsFromStore {

  param ( 
    [parameter()]
    [Switch]
    $Show,

    [parameter()]
    [validateSet('ALL', 'ORG', 'PERSONAL')]
    $SecretStoreSource = 'ALL'
  )

  Load-SecretObject -SecretObject (Get-SecretStore -SecretStoreSource $SecretStoreSource) -show:($Show)

}

######################################################################################

function Get-PersonalSecretStore {

  $tokenStore = Get-Content -Path "$env:SECRET_STORE.private.tokenstore.json" | `
    ConvertFrom-Json -Depth 6 | `
    Add-Member -MemberType NoteProperty -Name 'SECRET_STORE_PER__FILEPATH___TEMP' `
    -Value "$env:SECRET_STORE.private.tokenstore.json" -PassThru -Force

  return $tokenStore
}

function Get-OrgSecretStore {
  
  if ($env:CONFIG_DEVOPS_CURRENT_ORGANIZATION.length -eq 0) {
    $env:CONFIG_DEVOPS_CURRENT_ORGANIZATION = (Get-PersonalSecretStore).CONFIG.DEVOPS.DEFAULT_ORGANIZATION
  }
  if ($env:CONFIG_DEVOPS_CURRENT_ORGANIZATION.length -eq 0) {
    return [PSCustomObject]@{}
  }

  $tokenstore = "$env:SECRET_STORE.$env:CONFIG_DEVOPS_CURRENT_ORGANIZATION.tokenstore.json"
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
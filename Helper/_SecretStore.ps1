
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

  $SECRET_STORE = ''
  if ($SecretStoreSource -eq 'PERSONAL') {
    $SECRET_STORE = Get-PersonalSecretStore
  }
  elseif ($SecretStoreSource -eq 'ORG') {
    $SECRET_STORE = Get-OrgSecretStore
  }
  else {
    $SECRET_STORE = Get-UnifiedSecretStore
  }


  $_NOLOAD = $SECRET_STORE.'_NOLOAD'
  $_SILENT = $SECRET_STORE.'_SILENT'
  if ($SECRET_STORE.'_ORDER') {
    $SECRET_STORE = $SECRET_STORE `
    | Sort-Object -Property { $SECRET_STORE.'_ORDER'.IndexOf($_.Name) } 
  }

  # Load Secrets
  foreach ($BaseSecret in $SECRET_STORE.PSObject.Properties) {
    
    if ($_NOLOAD.contains($BaseSecret.Name)) {
      continue
    }

    $SECRET_BASE_NAME = $BaseSecret.name
    $SECRET_TYPE = $BaseSecret.value.GetType()
    
    # Convert to ENV if String or Value
    if ($SECRET_TYPE -eq [System.String] -OR $SECRET_TYPE.BaseType -eq [System.Array]) {
      if ($ShowFull -or ($Show -and !($_SILENT.contains($BaseSecret.Name)))) {
        Write-Host "Loading '$($SECRET_BASE_NAME)' from Secret Store" # Verbosing
      }

      # Evaluate if expression
      if ($BaseSecret.value[0] -eq '´') {
        $value = Invoke-Expression -Command $BaseSecret.value.substring(1)
        $null = New-Item -Path "env:$($SECRET_BASE_NAME)" -Value $value -Force
      }
      # Load Secret
      else {
        $null = New-Item -Path "env:$($SECRET_BASE_NAME)" -Value $BaseSecret.Value -Force  
      }

      if ($ShowFull) {
        Write-Host "  => $( (Get-ChildItem -Path "env:$SECRET_BASE_NAME").value )" # Verbosing
      }
    }


    # Parse further if Object
    else {

      if ($ShowFull -or ($Show -and !($_SILENT.contains($BaseSecret.Name)))) {
        Write-Host "Loading '$($SECRET_BASE_NAME)' Secrets from Secret Store" # Verbosing
      }

      # Load Sub-Secrets
      $BaseSecretProperties = $BaseSecret.Value.PSObject.Properties
      if ($BaseSecret['_ORDER']) {
        $BaseSecret = $BaseSecret | Sort-Object -Property { $BaseSecret['_ORDER'].Value.IndexOf($_.Name) }
      }

      # Iterate over Subsecrets
      foreach ($Secret in $BaseSecretProperties ) {

        if ($null -ne $BaseSecretProperties['_NOLOAD'] -AND $BaseSecretProperties['_NOLOAD'].value.contains($Secret.name)) {
          continue
        }

        $SecretName = "$($SECRET_BASE_NAME)_$($Secret.name)"
        if ($null -eq $BaseSecretProperties['_SILENT'] -OR !$BaseSecretProperties['_SILENT'].value.contains($Secret.name)) {
           Write-Host "Loading '$($SecretName)' from Secret Store"
        }
   
        if ($Secret.value[0] -eq '´') {
          $value = Invoke-Expression -Command $Secret.value.substring(1)
          $null = New-Item -Path "env:$($SecretName)" -Value $value -Force
        }
        else {
          $null = New-Item -Path "env:$($SecretName)" -Value $Secret.Value -Force  
        }

        if ($ShowFull) {
          Write-Host "  => $( (Get-ChildItem -Path "env:$SecretName").value )"
        }

      }
    } 

  }
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

if (!$env:LOADED_PERSONAL_SECRETS) {
  Get-SecretsFromStore -SecretStoreSource 'PERSONAL'
  $env:LOADED_PERSONAL_SECRETS = $true
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

#############################################################################

function Get-SecretFromStore {
  param (
    [parameter(Mandatory = $true)]
    [System.String]
    $SecretType
  )
  
  return (Get-UnifiedSecretStore)."$SecretType"

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
    [Switch]
    $NoLoad = $false,

    [parameter()]
    [validateSet('ALL', 'ORG', 'PERSONAL')]
    $SecretStoreSource = 'ORG',

    # TODO
    [parameter()]
    [System.String]
    $Organization = 'ORG'
  )

  $SECRET_STORE = ''
  if ($SecretStoreSource -eq 'PERSONAL') {
    $SECRET_STORE = Get-PersonalSecretStore
  }
  elseif ($SecretStoreSource -eq 'ORG') {
    $SECRET_STORE = Get-OrgSecretStore
  }
  else {
    $SECRET_STORE = Get-UnifiedSecretStore
  }
  
  $SECRET_STORE = $SECRET_STORE | `
    Add-Member `
    -MemberType NoteProperty `
    -Name $SecretType `
    -Value $SecretValue  `
    -PassThru -Force

  if ($NoLoad) {
    $SECRET_STORE._NOLOAD = @((@($SecretType) + $SECRET_STORE._NOLOAD) | Sort-Object | Get-Unique)
  }
  
  if ($SecretStoreSource -eq 'ORG') {
    $SECRET_STORE | ConvertTo-Json -Depth 6 | Out-File -FilePath "$($SECRET_STORE.SECRET_STORE_ORG__FILEPATH___TEMP)" 
  }
  elseif ($SecretStoreSource -eq 'PERSONAL') {
    $SECRET_STORE | ConvertTo-Json -Depth 6 | Out-File -FilePath "$($SECRET_STORE.SECRET_STORE_PER__FILEPATH___TEMP)"
  }

  Get-SecretsFromStore
  
}




function Update-AzTenantSecret {
  param ()
  
  Connect-AzAccount
  $Tenants = Get-AzTenant
  Update-SecretStore -SecretType AZURE_TENANTS -SecretValue $Tenants -NoLoad 

}


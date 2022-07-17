

# TODO Make recursive
function Load-PersonalSecrets {

  param ( 
    [parameter()]
    [Switch]
    $Show,

    [parameter()]
    [Switch]
    $ShowFull,

    [parameter()]
    [Switch]
    $ShowJSON
  )


  $SECRET_STORE = (Get-Content -Path $env:SECRET_TOKEN_STORE | ConvertFrom-Json).PSObject.Properties

  if($ShowJson) {
    Get-Content -Path $env:SECRET_TOKEN_STORE
  }

  if($SECRET_STORE["_ORDER"]) {
    $SECRET_STORE = $SECRET_STORE `
    | Sort-Object -Property { $SECRET_STORE["_ORDER"].Value.IndexOf($_.Name) } 
  }

  foreach ($BaseSecret in $SECRET_STORE) {
    
    if($BaseSecret.Name -eq "_ORDER"){
      continue
    }
    $SECRET_BASE_NAME = $BaseSecret.name
    
    # Convert to ENV if String or Value
    if ($BaseSecret.TypeNameOfValue -eq "System.String") {
      if ($ShowFull -or $Show) {
        Write-Host "Loading '$($SECRET_BASE_NAME)' from Secret Store"
      }

      if ($BaseSecret.value[0] -eq '´') {
        $value = Invoke-Expression -Command $BaseSecret.value.substring(1)
        $null = New-Item -Path "env:$($SECRET_BASE_NAME)" -Value $value -Force
      }
      else {
        $null = New-Item -Path "env:$($SECRET_BASE_NAME)" -Value $BaseSecret.Value -Force  
      }

      if($ShowFull) {
        Write-Host "  => $( (Get-ChildItem -Path "env:$SECRET_BASE_NAME").value )"
      }

    }
    # Parse further if Object
    else {

      if ($ShowFull -or $Show) {
        Write-Host "Loading '$($SECRET_BASE_NAME)' Secrets from Secret Store"
      }

      $BaseSecretProperties = $BaseSecret.Value.PSObject.Properties
      if($BaseSecret["_ORDER"]) {
        $BaseSecret = $BaseSecret | Sort-Object -Property { $BaseSecret["_ORDER"].Value.IndexOf($_.Name) }
      }

      foreach ($Secret in $BaseSecretProperties ) {
  
        if($Secret.Name -eq "_ORDER"){
          continue
        }
        $SecretName = "$($SECRET_BASE_NAME)_$($Secret.name)"
        # Write-Host "Loading '$($SecretName)' from Secret Store"
  
        if ($Secret.value[0] -eq '´') {
          $value = Invoke-Expression -Command $Secret.value.substring(1)
          $null = New-Item -Path "env:$($SecretName)" -Value $value -Force
        }
        else {
          $null = New-Item -Path "env:$($SecretName)" -Value $Secret.Value -Force  
        }

        if($ShowFull) {
          Write-Host "  => $( (Get-ChildItem -Path "env:$SecretName").value )"
        }

      }
    } 

  }
}

function Get-PersonalSecret {
  param (
    [parameter(Mandatory = $true)]
    [System.String]
    $SecretType
  )
  
  return (Get-Content -Path $env:SECRET_TOKEN_STORE | ConvertFrom-Json -Depth 3)."$SecretType"

}

function Update-PersonalSecret {
  param (
    [parameter(Mandatory = $true)]
    [System.String]
    $SecretType,

    [parameter(Mandatory = $true)]
    [PSCustomObject]
    $SecretValue
  )
  
  $SECRET_STORE = Get-Content -Path $env:SECRET_TOKEN_STORE | `
    ConvertFrom-Json -Depth 3 | `
    Add-Member `
    -MemberType NoteProperty `
    -Name $SecretType `
    -Value $SecretValue `
    -PassThru -Force | `
    ConvertTo-Json -Depth 3
  
  Out-File -FilePath $env:SECRET_TOKEN_STORE -InputObject $SECRET_STORE

  Load-PersonalSecrets
  
}



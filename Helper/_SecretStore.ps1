

function Load-PersonalSecrets {

  param ( 
    [parameter()]
    [System.Boolean]
    $Quiet = $true,

    [parameter()]
    [System.Boolean]
    $Show = $false
  )


  $SECRET_STORE = (Get-Content -Path $env:SECRET_TOKEN_STORE | ConvertFrom-Json).PSObject.Properties
  
  foreach ($BaseSecret in $SECRET_STORE) {

    $SECRET_BASE_NAME = $BaseSecret.name
    
    if ($BaseSecret.TypeNameOfValue -eq "System.String") {
      if (!$Quiet -or $Show) {
        Write-Host "Loading '$($SECRET_BASE_NAME)' from Secret Store"
      }

      if ($BaseSecret.value[0] -eq '´') {
        $value = Invoke-Expression -Command $BaseSecret.value.substring(1)
        $null = New-Item -Path "env:$($SECRET_BASE_NAME)" -Value $value -Force
      }
      else {
        $null = New-Item -Path "env:$($SECRET_BASE_NAME)" -Value $BaseSecret.Value -Force  
      }

      if($Show) {
        Write-Host "  => $( (Get-ChildItem -Path "env:$SECRET_BASE_NAME").value )"
      }

    }
    else {

      if (!$Quiet -or $Show) {
        Write-Host "Loading '$($SECRET_BASE_NAME)' Secrets from Secret Store"
      }

      foreach ($Secret in $BaseSecret.Value.PSObject.Properties ) {
  
        $SecretName = "$($SECRET_BASE_NAME)_$($Secret.name)"
        # Write-Host "Loading '$($SecretName)' from Secret Store"
  
        if ($Secret.value[0] -eq '´') {
          $value = Invoke-Expression -Command $Secret.value.substring(1)
          $null = New-Item -Path "env:$($SecretName)" -Value $value -Force
        }
        else {
          $null = New-Item -Path "env:$($SecretName)" -Value $Secret.Value -Force  
        }

        if($Show) {
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



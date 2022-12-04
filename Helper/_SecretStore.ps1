
function Convert-SecretObject {
  param (
    [parameter()]
    [PSObject]
    $SecretObject,

    [parameter()]
    [System.String]
    $indendation,

    [parameter()]
    [System.String]
    $SecretPrefixGlobal,

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


  $_OMITPREFIX = $SecretObject.'_OMITPREFIX' ?? @() 
  $_ORDER = $SecretObject.'_ORDER' ?? @() #TODO Order nit working anymore when merging secret stores
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
    $secretPrefixedName = $SecretPrefixGlobal + $cleanedName
    $envFlagged = $envFlaggedGlobal -OR $envFlaggedLocal

    # A load flag sets load for all subobjects, and searches for envs
    $loadFlagged = $_LOAD.contains($Secret.Name) -OR $loadFlaggedGlobal

    # $Secret.value.GetType() -eq [PSCustomObject] doesn't work
    if ($Secret.value.GetType().Name -eq 'PSCustomObject' -AND ($envFlagged -OR $loadFlagged)) {
      $SecretPrefix = $SecretPrefixGlobal + ($_OMITPREFIX.contains($cleanedName) ? '' : "$cleanedName`_")
      $verboseStuff = Convert-SecretObject -show:$($show) -recursionDepth ($recursionDepth + 1) -envFlagged:$($envFlagged) -loadFlaggedGlobal:$($loadFlagged) `
        -SecretObject $Secret.value -SecretPrefix ($SecretPrefix ) -indendation ($indendation + '   ')

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

  Convert-SecretObject -SecretObject (Get-SecretStore -SecretStoreSource $SecretStoreSource -noCleanNames) -show:($Show)

}

######################################################################################

function Get-PersonalSecretStore {

  param (
    [parameter()]
    [switch]
    $noCleanNames
  )

  $path = "$env:SECRET_STORE.private.tokenstore.json" 
  $content = Get-Content -Path $path 
  $content = $noCleanNames ? $content : $content.replace('$env:', '')
        
  return $content | ConvertFrom-Json -Depth 6 | `
    Add-Member -MemberType NoteProperty -Name 'SECRET_STORE_PER__FILEPATH___TEMP' `
    -Value $path -PassThru -Force
}

function Get-OrgSecretStore {

  param (
    [parameter()]
    [switch]
    $noCleanNames,

    [parameter()]
    [ValidateSet([DevOpsORG])]
    $Organization = $env:DEVOPS_DEFAULT_ORGANIZATION
  )

  # TODO Implement Supress Error Option
  if ($Organization.length -eq 0) {
    Throw "Not Found"
    return [PSCustomObject]@{}
  }

  # TODO Implement Check Onedrive before creating secret store
  $path = "$env:SECRET_STORE.$Organization.tokenstore.json"
  if (!(Test-Path $path)) {
    $null = (Get-Content -Path "$env:PROFILE_HELPERS_PATH\.blueprint.tokenstore.json").Replace('${{ORGANIZATION}}', $Organization) | `
      Out-File -FilePath $path
  } 

  $content = Get-Content -Path $path 
  $content = $noCleanNames ? $content : $content.replace('$env:', '')

  return $content | `
    ConvertFrom-Json -Depth 6 | `
    Add-Member -MemberType NoteProperty -Name 'SECRET_STORE_ORG__FILEPATH___TEMP' `
    -Value $path -PassThru -Force

}

function Get-UnifiedSecretStore {

  param (
    [parameter()]
    [switch]
    $noCleanNames
  )

  $SECRETS_PER = Get-PersonalSecretStore -noCleanNames:$($noCleanNames)
  $SECRETS_ORG = Get-OrgSecretStore -noCleanNames:$($noCleanNames)

  return  Join-PsObject -Object1 $SECRETS_PER -Object2 $SECRETS_ORG

}


function Get-SecretStore {
  param (
    [parameter()]
    [validateSet('ALL', 'ORG', 'PERSONAL')]
    $SecretStoreSource = 'ALL',

    [parameter()]
    [ValidateSet([DevOpsORG])]
    $Organization,

    [parameter()]
    [switch]
    $noCleanNames
  )

  if ($SecretStoreSource -eq 'PERSONAL') {
    return Get-PersonalSecretStore -noCleanNames:$($noCleanNames)
  }
  elseif ($SecretStoreSource -eq 'ORG') {
    return Get-OrgSecretStore -noCleanNames:$($noCleanNames) -Organization $Organization
  }
  else {
    return Get-UnifiedSecretStore -noCleanNames:$($noCleanNames)
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

  [cmdletbinding()]
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

    [parameter(Mandatory = $true)]
    [validateSet('ORG', 'PERSONAL')]
    $SecretStoreSource,

    [parameter()]
    [ValidateSet([DevOpsORG])]
    $Organization = $env:DEVOPS_CURRENT_ORGANIZATION
  )

  $SECRET_STORE = Get-SecretStore -SecretStoreSource $SecretStoreSource -Organization $Organization
  
  $SecretObject = $SubSecret.length -gt 0 ? $SecretObject."$SecretType" : $SECRET_STORE
  $SecretObject | Add-Member -MemberType NoteProperty -Name $SecretType -Value $SecretValue -Force


  if ($SecretStoreSource -eq 'ORG') {
    Write-Verbose $SECRET_STORE.SECRET_STORE_ORG__FILEPATH___TEMP
    $SECRET_STORE | ConvertTo-Json -Depth 6 | Out-File -FilePath "$($SECRET_STORE.SECRET_STORE_ORG__FILEPATH___TEMP)"
  }
  elseif ($SecretStoreSource -eq 'PERSONAL') {
    Write-Verbose $SECRET_STORE.SECRET_STORE_PER__FILEPATH___TEMP
    $SECRET_STORE | ConvertTo-Json -Depth 6 | Out-File -FilePath "$($SECRET_STORE.SECRET_STORE_PER__FILEPATH___TEMP)"
  } 
  
}

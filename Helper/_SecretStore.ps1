$global:GlobalScope = [psmoduleinfo]::new($true)

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
    $enumFlagged = $Secret.name.length -gt 6 -AND $Secret.name.substring(0, 6).ToUpper() -eq '$ENUM:'

    $cleanedName = $secret.name
    if ($envFlaggedLocal) {
      $cleanedName = $Secret.name.substring(5)
    }
    elseif ($enumFlagged) {
      $cleanedName = $Secret.name.substring(6)
    }

    $secretPrefixedName = $SecretPrefixGlobal + $cleanedName
    $envFlagged = $envFlaggedGlobal -OR $envFlaggedLocal

    # A load flag sets load for all subobjects, and searches for envs
    $loadFlagged = $_LOAD.contains($Secret.Name) -OR $loadFlaggedGlobal

    # $Secret.value.GetType() -eq [PSCustomObject] doesn't work
    # Search all Subsequent Objects if load or env flagged
    if ($Secret.value.GetType().Name -eq 'PSCustomObject' -AND ($envFlagged -OR $loadFlagged)) {
      $SecretPrefix = $SecretPrefixGlobal + ($_OMITPREFIX.contains($cleanedName) ? '' : "$cleanedName`_")
      $verboseStuff = Convert-SecretObject -show:$($show) -recursionDepth ($recursionDepth + 1) -envFlagged:$($envFlagged) -loadFlaggedGlobal:$($loadFlagged) `
        -SecretObject $Secret.value -SecretPrefix ($SecretPrefix ) -indendation ($indendation + '   ')

      if ($verboseStuff.length -gt 0) {
        $verbosing = $verbosing + "`n$indendation + Loading '$($secretPrefixedName)' from Secret Store" + $verboseStuff
      }

    }
    # If env-flagged and string convert to env
    elseif ($envFlagged -AND $Secret.value.GetType() -eq [System.String]) {
      $SecretValue = $Secret.value[0] -eq '´' ? (Invoke-Expression -Command $Secret.value.substring(1)) : $Secret.value
      $null = New-Item -Path "env:$secretPrefixedName" -Value $SecretValue -Force  
      $verbosing += "`n$indendation + Loading ENV:'$($secretPrefixedName)' from Secret Store"
    }
    # If env-flagged and valutetype convert to env string (Like Dates will throw Errors)
    elseif ($envFlagged -AND $Secret.value.GetType().BaseType -eq [System.ValueType]) {
      $SecretValue = $Secret.value.toString()
      $null = New-Item -Path "env:$secretPrefixedName" -Value $SecretValue -Force  
      $verbosing += "`n$indendation + Loading ENV:'$($secretPrefixedName)' from Secret Store"
    }
    elseif ($envFlagged -AND $Secret.value.GetType().BaseType -eq [System.Array]) {
      Throw "Can't Load 'System.Array' to ENV"
    }
    elseif ($enumFlagged -AND $Secret.value.GetType().BaseType -eq [System.Array]) {
      $verbosing += "`n$indendation + Loading ENUM:'$($cleanedName)' from Secret Store"
      $enumString = @"
          enum $($cleanedName) { 
            $($Secret.Value -join '; ') 
          }
"@

#TODO Not working yet
      & $global:GlobalScope {
        param($params)
        # Splatting doesn't
        Write-Host "Execute Global $($Params.Command)"
        $null = Invoke-Expression @params
      } @{
        Command = $enumString
      }

      <#
      # Check if the enum exists, if it doesn't, create it.
      if (!($cleanedName -as [Type])) {
        Add-Type -TypeDefinition "
            public enum $($cleanedName){
                anonymousAuthentication,
                basicAuthentication,
                clientCertificateMappingAuthentication,
                digestAuthentication,
                iisClientCertificateMappingAuthentication,
                windowsAuthentication    
            }
        "
      }
      #>
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
  $content = $noCleanNames ? $content : ($content -replace '[$]{1}[A-Za-z]+:{1}')
        
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
    Throw 'Not Found'
    return [PSCustomObject]@{}
  }

  # TODO Implement Check Onedrive before creating secret store
  $path = "$env:SECRET_STORE.$Organization.tokenstore.json"
  if (!(Test-Path $path)) {
    $null = (Get-Content -Path "$env:PROFILE_HELPERS_PATH\.blueprint.tokenstore.json").Replace('${{ORGANIZATION}}', $Organization) | `
      Out-File -FilePath $path
  }

  $content = Get-Content -Path $path 
  $content = $noCleanNames ? $content : ($content -replace '[$]{1}[A-Za-z]+:{1}')

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
    $SecretPath,

    [parameter()]
    [validateSet('ALL', 'ORG', 'PERSONAL')]
    $SecretStoreSource = 'ALL',

    [parameter()]
    [switch]
    $Unprocessed
  )

  $splitPath = $SecretPath -split '[\/\.]+'

  $SecretObject = (Get-SecretStore -SecretStoreSource $SecretStoreSource) # Gets Cleaned Names 
  foreach ($segment in $splitPath) {

    if ($null -eq $SecretObject) {
      Throw "Path: $SecretPath - Error at Segment $segment - Object is NULL"
    }

    if ($SecretObject.GetType().Name -notin @('PSObject', 'PSCustomObject') ) {
      Throw "Path: $SecretPath - Error at Segment $segment - Object is $($SecretObject.GetType().Name)"
    }

    if ($null -eq $SecretObject."$segment") {
      Throw "Path: $SecretPath - Error at Segment $segment - Segment does not exist "
    }

    $SecretObject = $SecretObject."$segment"
  
  }

  if (!$Unprocessed -AND $SecretObject.GetType() -eq [System.String] -AND $SecretObject[0] -eq '´') {
    Write-Verbose $SecretObject
    return (Invoke-Expression -Command $SecretObject.substring(1))
  }
  else {
    return $SecretObject  
  }

}


function Update-SecretStore {

  [cmdletbinding(
    SupportsShouldProcess,
    ConfirmImpact = 'high'
  )]
  param (
    [parameter(Mandatory = $true)]
    [SecretScope]
    $SecretStoreSource,

    [parameter()]
    [AllowNull()]
    [ValidateSet([DevOpsORG])]
    $Organization = $env:DEVOPS_CURRENT_ORGANIZATION, #TODO

    [parameter(Mandatory = $true)]
    [System.String]
    $SecretPath,

    [parameter(Mandatory = $true)]
    [PSCustomObject]
    $SecretValue,

    [parameter()]
    [switch]
    $ENV,

    [parameter()]
    [switch]
    $ENUM
  )
         
  if ($ENUM -AND $ENV) {
    Throw 'Both ENUM and ENV set'
  }

  $SECRET_STORE;
  switch ($SecretStoreSource) {
    'ORG' {
      $SECRET_STORE = Get-SecretStore -SecretStoreSource $SecretStoreSource -Organization $Organization -noCleanNames
    }
    'PERSONAL' {
      $SECRET_STORE = Get-SecretStore -SecretStoreSource $SecretStoreSource -noCleanNames
    }
    default {
      Throw 'Not supported'
    }
  }

  $OUT_PATH = $SecretStoreSource -eq 'ORG' ? $SECRET_STORE.SECRET_STORE_ORG__FILEPATH___TEMP : $SECRET_STORE.SECRET_STORE_PER__FILEPATH___TEMP


  $splitPath = $SecretPath -split '[\/\.]+'

  $SecretObject = $SECRET_STORE
  $secretName = $splitPath[-1]
  $parentPath = $splitPath.Length -eq 1 ? @(): $splitPath[0..($splitPath.Length - 2)]

  Write-Verbose "SecretName $SecretName"
  Write-Verbose "ParentPath $parentPath"

  # Only iterate to Parent, last element of path is Secret Name
  foreach ($segment in $parentPath) {

    if ($SecretObject.GetType().Name -notin @('PSObject', 'PSCustomObject') ) {
      Throw "Path: $SecretPath - Error at Segment $segment - Object is $($SecretObject.GetType().Name)"
    }

    $candidate = $SecretObject.PSObject.Properties | `
      Where-Object { $_.Name -like "*$segment" }

    if ($candidate.GetType().BaseType -eq [System.Array]) {
      Throw "Path: $SecretPath - Error at Segment $segment - Multiple Candidates found"
    }

    if ($null -eq $candidate) {
      $SecretObject = $SecretObject | Add-Member -MemberType NoteProperty -Name $segment -Value ([PSCustomObject]::new()) -PassThru
    }
    # Automatically takes care of Keys having keywords ($:env) before name, by passing value of noteproperty found
    else {
      $SecretObject = $candidate.value
    }
  
  }

  Write-Verbose "Write Secret '$SecretName' to Path '$SecretPath'"
  if ($PSCmdlet.ShouldProcess("$SecretPath" , 'Write Secret to Path')) {

    # Delete Property with same name
    # In case if ENV is enabled and same Property exists without $env: prefix, it gets deleted so not appearing twice!
    if ($null -ne $SecretObject."$SecretName") {
      $SecretObject.PSObject.Properties.Remove($SecretName)
    }

    $SecretName = $ENV ? "`$env:$SecretName" : ($ENUM ? "`$enum:$SecretName" : $SecretName)
    $SecretObject | Add-Member -MemberType NoteProperty -Name $SecretName -Value $SecretValue

    Write-Verbose $OUT_PATH
    $SECRET_STORE | ConvertTo-Json -Depth 6 | Out-File -FilePath $OUT_PATH

  }
  
}

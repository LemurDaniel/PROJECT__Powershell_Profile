function Get-SecretFromStore {

  param (
    [parameter(Mandatory = $true)]
    [System.String]
    $SecretPath,

    [parameter()]
    [SecretScope]
    $SecretStoreSource = [System.Enum]::GetNames([SecretScope])[0],

    [parameter()]
    [switch]
    $Unprocessed,

    # Test
    [Parameter()]
    $CustomPath 
  )


  $SecretObject = (Get-SecretStore -SecretStoreSource $SecretStoreSource -CustomPath $CustomPath)
  $SecretObject = Get-Property -Object $SecretObject -PropertyPath $SecretPath

  if (!$Unprocessed -AND $SecretObject.GetType() -eq [System.String] -AND $SecretObject[0] -eq '´') {
    return (Invoke-Expression -Command $SecretObject.substring(1))
  }
  else {
    return $SecretObject  
  }

}

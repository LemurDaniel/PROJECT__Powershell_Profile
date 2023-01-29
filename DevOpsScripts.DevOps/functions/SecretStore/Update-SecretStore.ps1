function Update-SecretStore {

    [cmdletbinding(
        SupportsShouldProcess,
        ConfirmImpact = 'high'
    )]
    param (
        [parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [parameter(Mandatory = $true)]
        [PSCustomObject]
        $Value,

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

    $SECRET_STORE = Get-SecretStore -noCleanNames
    $OUT_PATH = $SECRET_STORE.SECRET_STORE__FILEPATH
    $SecretObject = $SECRET_STORE
    $splitPath = $Path -split '[\/\.]+'
    $secretName = $splitPath[-1]
    $parentPath = $splitPath.Length -eq 1 ? @(): $splitPath[0..($splitPath.Length - 2)]

    Write-Verbose "SecretName $SecretName"
    Write-Verbose "ParentPath $parentPath"

    # Only iterate to Parent, last element of path is Secret Name
    foreach ($segment in $parentPath) {

        if ($SecretObject.GetType().Name -notin @('PSObject', 'PSCustomObject') ) {
            Throw "Path: $Path - Error at Segment $segment - Object is $($SecretObject.GetType().Name)"
        }

        $candidate = $SecretObject.PSObject.Properties | Where-Object -Property Name -Like -Value "*$segment"

        if ($null -ne $candidate -AND $candidate.GetType().BaseType -eq [System.Array]) {
            Throw "Path: $Path - Error at Segment $segment - Multiple Candidates found"
        }

        if ($null -eq $candidate) {
            $SecretObject | Add-Member -MemberType NoteProperty -Name $segment -Value ([PSCustomObject]::new())
            $SecretObject = $SecretObject."$segment"
        }
        else {
            $SecretObject = $candidate.value
        }
  
    }

    Write-Verbose "Write Secret '$SecretName' to Path '$Path'"
    if ($PSCmdlet.ShouldProcess("$Path" , 'Write Secret to Path')) {

        # Delete Property with same name TODO
        if ($null -ne $SecretObject."$SecretName") {
            $SecretObject.PSObject.Properties.Remove($SecretName)
        }
        if ($null -ne $SecretObject."`$env:$SecretName") {
            $SecretObject.PSObject.Properties.Remove("`$env:$SecretName")
        }
        if ($null -ne $SecretObject."`$enum:$SecretName") {
            $SecretObject.PSObject.Properties.Remove("`$enum:$SecretName")
        }

        $SecretName = $ENV ? "`$env:$SecretName" : ($ENUM ? "`$enum:$SecretName" : $SecretName)
        $SecretObject | Add-Member -MemberType NoteProperty -Name $SecretName -Value $Value

        Write-Verbose $OUT_PATH
        $SECRET_STORE | ConvertTo-Json -Depth 6 | Out-File -FilePath $OUT_PATH

    }
  
}

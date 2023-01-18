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
        [ValidateSet([DevOpsOrganization])]
        $Organization = $env:AZURE_DEVOPS_ORGANIZATION_CURRENT, #TODO

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
            $SECRET_STORE = Get-SecretStore -SecretStoreSource $SecretStoreSource -noCleanNames
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

        if ($null -ne $candidate -AND $candidate.GetType().BaseType -eq [System.Array]) {
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
        $SecretObject | Add-Member -MemberType NoteProperty -Name $SecretName -Value $SecretValue

        Write-Verbose $OUT_PATH
        $SECRET_STORE | ConvertTo-Json -Depth 6 | Out-File -FilePath $OUT_PATH

    }
  
}

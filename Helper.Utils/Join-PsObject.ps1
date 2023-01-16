function Join-PsObject {

    param ( 
        [parameter()]
        [PSObject]
        $Object1,

        [parameter()]
        [PSObject]
        $Object2
    )

    $PropertyNamesList = (@($Object1.PSObject.Properties.Name) + @($Object2.PSObject.Properties.Name)) | Sort-Object | Get-Unique

    foreach ($PropertyName in $PropertyNamesList) {

        $isPropertyInObj1 = $PropertyName -in $Object1.PSObject.Properties.Name
        $isPropertyInObj2 = $PropertyName -in $Object2.PSObject.Properties.Name

        if ($isPropertyInObj1 -AND !$isPropertyInObj2) {
            continue
        }
        elseif (!$isPropertyInObj1 -AND $isPropertyInObj2) {
            $Property = $Object2.PSObject.Properties[$PropertyName]
            $Object1 | Add-Member -MemberType $Property.MemberType -Name $Property.Name -Value $Property.Value
            continue
        }

        $Type = $Object1."$PropertyName".GetType();

        if ( $Type -ne $Object2."$PropertyName".GetType() ) {
            Throw 'Mismatching Types'
        }
        if ( $Type.BaseType -eq [System.ValueType] || $Type -eq [System.String] ) {
            Throw "Operation not Supported for $($Property.PSObject.Properties.Value.GetType())"
        }
        elseif ( $Type.BaseType -eq [System.Array]) {
            $Object1."$($PropertyName)" = (@($Object1."$($PropertyName)") + @($Object2."$($PropertyName)")) | Sort-Object | Get-Unique
        }
        else {
            $Object1."$($PropertyName)" = Join-PsObject -Object1 ($Object1."$($PropertyName)") -Object2 ($Object2."$($PropertyName)") 
        }

    }
    return $Object1
}
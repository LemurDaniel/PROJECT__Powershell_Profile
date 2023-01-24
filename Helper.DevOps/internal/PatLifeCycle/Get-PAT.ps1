function Get-PAT {
    param (
        [Parameter()]
        [System.String]
        $Organization = 'baugruppe'
    )

    if (!$Global:DevOpsPAT) {
        $Global:DevOpsPAT = New-PAT -Organization $Organization -DaysValid 1
    }

    $TIMESPAN = New-TimeSpan -Start ([System.DateTime]::now) -End $Global:DevOpsPAT.validTo
    if ($TIMESPAN.Days -lt 1) {
        $Global:DevOpsPAT = Update-PAT -Organization $Organization -DaysValid 1
    }

    return [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("$((Get-AZContext).Account.Id):$($Global:DevOpsPAT.token)"))
}



function Add-OrganizationPAT {
    
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $Organization,

        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $PAT
    )


    $organizations = Read-SecureStringFromFile -Identifier organizations.pat.all -AsJSON

    if (!$organizations) {
        $organizations = [System.Collections.Hashtable]::new()
    }

    $organizations | Add-Member -Force -MemberType NoteProperty -Name $Organization -Value (New-RandomBytes Hex 16)
    Save-SecureStringToFile -Identifier $organizations."$Organization" -PlainText $PAT
    Save-SecureStringToFile -Identifier organizations.pat.all -PlainText ($organizations | ConvertTo-Json)

    return Get-DevOpsOrganizations -Refresh
}




function Remove-OrganizationPAT {
    
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $Organization
    )


    $organizations = Read-SecureStringFromFile -Identifier organizations.pat.all -AsHashtable
    if (!$organizations) {
        return $null
    }

    $null = $organizations.Remove($Organization)
    Save-SecureStringToFile -Identifier organizations.pat.all -PlainText ($organizations | ConvertTo-Json)
    return Get-DevOpsOrganizations -Refresh
}

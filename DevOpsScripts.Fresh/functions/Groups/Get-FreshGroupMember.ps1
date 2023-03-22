function Get-FreshGroupMember {

    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $Group
    )

    $agents = [System.Collections.ArrayList]::new()
    foreach ($agentId in $Group.members) {
        $agents += Invoke-FreshApi -Method GET -ApiEndpoint agents -ApiResource ($agentId -replace '[^\d]', '')
    }

    return $agents.agent
}


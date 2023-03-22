function Get-FreshTicket {

    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $TicketId
    )

    return (Invoke-FreshApi -Method GET -ApiEndpoint tickets -ApiResource ($TicketId -replace '[^\d]', '')).ticket
}
function Set-FreshTicketAgent {

    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $Ticket,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AgentId
    )

    $ticketAgentUpdate = [PSCustomObject]@{
        description  = [String]( ($null -ne $Ticket.description -AND $Ticket.description.length -gt 0) ? $Ticket.description : $Ticket.subject )
        responder_id = [Int64]( $AgentId )
    }

    return (Invoke-FreshApi -Method PUT -ApiEndpoint tickets -ApiResource ($Ticket.id) -Body $ticketAgentUpdate).ticket
}

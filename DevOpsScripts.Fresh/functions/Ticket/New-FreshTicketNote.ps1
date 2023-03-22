function New-FreshTicketNote {

    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $Ticket,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Content,

        [Parameter()]
        [switch]
        $Private
    )

    $RequestBody = [PSCustomObject]@{
        body    = $Content
        private = ($Private ? $true : $false)
    }

    return Invoke-FreshApi -Method POST -ApiEndpoint tickets -ApiResource "$($Ticket.id)/notes" -Body $RequestBody
}
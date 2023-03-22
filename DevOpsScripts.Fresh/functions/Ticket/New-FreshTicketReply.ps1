function New-FreshTicketReply {

    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $Ticket,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Content,

        [Parameter()]
        [ValidateSet('Open', 'Pending', 'Resolved', 'Closed')]
        $State
    )

    $RequestBody = [PSCustomObject]@{
        body = $Content
    }


    Invoke-FreshApi -Method POST -ApiEndpoint tickets -ApiResource "$($Ticket.id)/reply" -Body $RequestBody
    switch ($State) {
        'Open' { 
            Invoke-FreshApi -Body @{ status = 2 } -Method PUT -ApiEndpoint tickets -ApiResource "$($Ticket.id)"
        }
        'Pending' { 
            Invoke-FreshApi -Body @{ status = 3 } -Method PUT -ApiEndpoint tickets -ApiResource "$($Ticket.id)"
        }
        'Resolved' { 
            $body = @{ 
                custom_fields = @{
                    lsungsart    = 'gelöst ohne Selfservice'
                    erfolgreich  = 'Erfolgreich'
                    reaktionzeit = (Get-Date).ToString('dd.MM.yyyy hh:mm:ss')
                }
                status        = 4 
                category      = 'Azure'
                sub_category  = 'Sandbox'
            }
            Invoke-FreshApi -Body $body -Method PUT -ApiEndpoint tickets -ApiResource "$($Ticket.id)"
        }
        'Closed' { 
            Invoke-FreshApi -Body @{ status = 5 } -Method PUT -ApiEndpoint tickets -ApiResource "$($Ticket.id)"
        }
        Default {
            #No Status Change
        }
    }
    
}

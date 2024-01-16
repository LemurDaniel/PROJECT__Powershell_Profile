<#
    .SYNOPSIS
        Similar to Select-AzContext. Uses Set-AzContext with selected subscription in current tenant.

    .DESCRIPTION
        Similar to Select-AzContext. Uses Set-AzContext with selected subscription in current tenant.

    .EXAMPLE
        Switch subscription on current context:

        PS> Switch-AzSubscription <autocompleted_subscription>

    .LINK
     

#>

function Switch-AzSubscription {
 
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = (Get-AzSubscription -WarningAction SilentlyContinue).Name

                $validValues
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Name
    )

    $SubscriptionId = Get-AzSubscription -WarningAction SilentlyContinue
    | Where-Object -Property Name -EQ -Value $Name
    | Select-Object -ExpandProperty Id

    return Set-AzContext -SubscriptionId $SubscriptionId -WarningAction SilentlyContinue

}

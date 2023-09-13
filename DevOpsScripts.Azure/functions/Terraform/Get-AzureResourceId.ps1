

<#

.SYNOPSIS
    TODO

.DESCRIPTION
    TODO


.EXAMPLE
    TODO

.LINK
  

#>



function Get-AzureResourceId {

    [CmdletBinding()]
    [Alias('az-id')]
    param(
        # The name of the azure resource in the cloud
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)
            
                $validValues = Get-AzureResourceTypes
                            
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [ValidateScript(
            {
                $_ -in (Get-AzureResourceTypes)
            },
            ErrorMessage = "Not a valid module path in the current path."
        )]
        $AzType,


        [Parameter(
            Position = 1,
            Mandatory = $false
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)
            
                $validValues = Get-AzResource -ResourceType $fakeBoundParameters['AzType']
                | ForEach-Object {
                    "$($_.ResourceGroupName)/$($_.Name)"
                }
                            
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        $Name
    )

    $azureResource = Get-AzResource -ResourceType $AzType

    if ($PSBoundParameters.ContainsKey('Name')) {
        $azureResource = $azureResource 
        | Where-Object {
            "$($_.ResourceGroupName)/$($_.Name)" -EQ $Name
        }
    }

    return $azureResource.resourceId
}
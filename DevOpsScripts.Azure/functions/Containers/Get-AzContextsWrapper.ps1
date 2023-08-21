

function Get-AzContextsWrapper {
    param ()

    $tenants = Get-AzTenant
    (Get-AzContext -ListAvailable) 
    | Where-Object -Property Subscription -NE -Value $null
    | ForEach-Object {

        $associatedTenant = $tenants 
        | Where-Object -Property Id -EQ $_.Tenant.Id

        [PSCustomObject]@{
            name = "[$($associatedTenant.Name)] $($_.Subscription.Name)"
            azContext = $_
        }
    }

}
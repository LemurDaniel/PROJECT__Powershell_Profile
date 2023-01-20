
function Get-DevOpsOrganizations {

    [cmdletbinding()]
    param()

    $Cache = Get-UtilsCache -Type Organization -Identifier 'all'
    if($Cache){
        return $Cache
    }

    # Get Organizations the user is member of.
    $Request = @{
        Method = 'GET'
        Call   = 'None'
        Domain = 'app.vssps.visualstudio'
        API    = '_apis/accounts?api-version=6.0'
        Query  = @{
            memberId = Get-CurrentUser 'publicAlias'
        }
    }

    $Organizations = Invoke-DevOpsRest @Request -return 'value'
    return Set-UtilsCache -Object $Organizations -Type Organization -Identifier 'all'

}
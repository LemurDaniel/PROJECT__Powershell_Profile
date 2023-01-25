
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

    if(($Organizations | Measure-Object).Count -eq 0) {
        Throw "Couldnt find any DevOps Organizations associated with User: '$(Get-CurrentUser 'displayName')' - '$(Get-CurrentUser 'emailAddress')'"
    }
    return Set-UtilsCache -Object $Organizations -Type Organization -Identifier 'all'

}
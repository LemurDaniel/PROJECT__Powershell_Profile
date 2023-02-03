function Get-GitUser {

    param()

    $user = Get-UtilsCache -Type User -Identifier Current
    if(!$user){
        $user = Invoke-GitRest -Method GET -API 'user'
        $user.email = (Invoke-GitRest -Method GET -API 'user/emails') | ` 
            Where-Object -Property primary -eq $true | Select-Object -First 1 -ExpandProperty email

        $user = Set-UtilsCache -Object $user -Type User -Identifier Current
    }
    return $user
}
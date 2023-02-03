function Get-GitUser {

    param()

    $user = Get-UtilsCache -Type User -Identifier Current
    if(!$user){
        $user = Invoke-GitRest -Method GET -API 'user'
        $user = Set-UtilsCache -Object $user -Type User -Identifier Current
    }
    return $user
}
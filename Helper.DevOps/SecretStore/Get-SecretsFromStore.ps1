function Get-SecretsFromStore {

    param ( 
        [parameter()]
        [Switch]
        $Show,

        # Test
        [Parameter()]
        $CustomPath 
    )

    Convert-SecretObject -SecretObject (Get-SecretStore -noCleanNames -CustomPath $CustomPath) -show:($Show)

}
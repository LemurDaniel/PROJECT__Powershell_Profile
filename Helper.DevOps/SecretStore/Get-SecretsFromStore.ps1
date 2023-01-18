function Get-SecretsFromStore {

    param ( 
        [parameter()]
        [Switch]
        $Show,

        [parameter()]
        [AllowNull()]
        [SecretScope]
        $SecretStoreSource = [System.Enum]::GetNames([SecretScope])[0],

        # Test
        [Parameter()]
        $CustomPath 
    )

    Convert-SecretObject -SecretObject (Get-SecretStore -SecretStoreSource $SecretStoreSource -noCleanNames -CustomPath $CustomPath) -show:($Show)

}
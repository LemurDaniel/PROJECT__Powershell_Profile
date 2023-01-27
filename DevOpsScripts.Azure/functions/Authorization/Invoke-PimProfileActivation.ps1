function Invoke-PimProfileActivation {

    [cmdletbinding()]
    param(
        # The name of the Context to switch to.
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ValidateScript(
            { 
                $_ -in (Get-PimProfiles).Keys
            },
            ErrorMessage = 'Please specify the correct Context.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-PimProfiles).Keys
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $ProfileName,


        [Parameter(
            Position = 1,
            Mandatory = $true
        )]
        [System.String]
        $justification,

        [Parameter()]
        [ValidateSet(       
            'SelfActivate',
            'SelfExtend',
            'SelfRenew'
        )]
        [System.String]
        $requestType = 'SelfActivate'
    )

    $pimProfile = (Get-PimProfiles).GetEnumerator() | Where-Object -Property Key -EQ -Value $ProfileName

    return New-PimSelfActivationRequest -justification $justification -duration $pimProfile.Duration -scope $pimProfile.Scope -role $pimProfile.Role -requestType $requestType
}
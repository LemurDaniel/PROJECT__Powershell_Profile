
<#
    .SYNOPSIS
    Adds a Pim-Profile for a role and a scope.

    .DESCRIPTION
    Adds a Pim-Profile for a role and a scope for quick activation, without clicking throug the Portal.
    Multiple Pim-Roles can be easly activated parralel this way.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    All current PIM-Profiles. The resulting activation API-Response with links to the roleAssignment and Eligibility schedule Id.


    .EXAMPLE

    Add a Pim-Profile for Resource Policy Contributor on acfroot-prod with an activation duration of 3 hours:

    PS> Add-PimProfile -ProfileName PolicyContrib -Scope acfroot-prod -Role 'Resource Policy Contributor' -duration 3 -Force
    
    
    .LINK
        
#>
function Invoke-PimProfileActivation {

    [cmdletbinding()]
    [Alias('pim')]
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

    $pimProfile = (Get-PimProfiles).GetEnumerator() | Where-Object -Property Key -EQ -Value $ProfileName | Select-Object -ExpandProperty Value
    return New-PimSelfActivationRequest -justification $justification -duration $pimProfile.Duration -scope $pimProfile.Scope -role $pimProfile.Role -requestType $requestType
}
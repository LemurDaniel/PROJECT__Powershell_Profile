


function Get-OrganizationPAT {
    
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true
        )]
        [ArgumentCompleter({
            param($cmd, $param, $wordToComplete)

            return (Read-SecureStringFromFile -Identifier organizations.pat.all -AsJSON).PSObject.Properties.Name
        })]
        [System.String]
        $Organization
    )

    $organizations = Read-SecureStringFromFile -Identifier organizations.pat.all -AsJSON
    if ($organizations) {
        return Read-SecureStringFromFile -Identifier $organizations."$Organization" -AsPlainText
    } 

}

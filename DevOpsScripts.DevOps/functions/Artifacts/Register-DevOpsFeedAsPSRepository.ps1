
<#
    .SYNOPSIS
    Registers a DevOps Artifact-Feed with as a PSRepository to Pull Packages from.

    .DESCRIPTION
    Registers a DevOps Artifact-Feed with as a PSRepository to Pull Packages from. 

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None

    .LINK
        
#>
function Register-DevOpsFeedAsPSRepository {
    
    [cmdletbinding()]
    param (
        # The Pipeline name in the current Project autocompleted.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Organization, 
        
        # An optional Project Name for Project-scoped feeds.
        [Parameter(Mandatory = $true)]
        [System.String]
        $ProjectName,
        
        # The AzureDevOps Feed Name.
        [Parameter(Mandatory = $true)]
        [System.String]
        $ArtifactFeed, 

        # An optional path where to save created credentials for operations.
        [Parameter(Mandatory = $false)]
        [System.String]
        $CredentialPath
    )


    $PSRepositoryName = "$ArtifactFeed-DevOpsFeed"
    $credentials = Get-PAT -Organization $Organization -Path $CredentialPath -patScopes 'vso.packaging' -HoursValid 24
    $PSRepository = Get-PSRepository -Name $PSRepositoryName -ErrorAction SilentlyContinue

    if([System.String]::IsNullOrEmpty($ProjectName)){
        $source = "https://pkgs.dev.azure.com/$Organization/_packaging/$ArtifactFeed/nuget/v2" -replace ' ','%20'
    } else {
        $source = "https://pkgs.dev.azure.com/$Organization/$ProjectName/_packaging/$ArtifactFeed/nuget/v2" -replace ' ','%20'
    }


    if($PSRepository){
        $PSRepository = Set-PSRepository -Name $PSRepositoryName -Credential $credentials
    } else {
        $PSRepository = Register-PSRepository `
            -Name $PSRepositoryName `
            -SourceLocation $source -PublishLocation $source `
            -InstallationPolicy Trusted -Credential $credentials
    }

    return Get-PSRepository -Name $PSRepositoryName
}

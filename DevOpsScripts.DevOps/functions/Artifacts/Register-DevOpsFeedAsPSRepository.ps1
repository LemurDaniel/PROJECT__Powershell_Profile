
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
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = 'autocomplete'
        )]
        [ValidateScript(
            {
                $_ -in (Get-DevOpsArtifactFeeds -Scope All | Select-Object -ExpandProperty name)
            }
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = Get-DevOpsArtifactFeeds -Scope All | Select-Object -ExpandProperty name
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Feedname,

        # The Pipeline name in the current Project autocompleted.
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'specific'
        )]
        [System.String]
        $Organization, 
        
        # An optional Project Name for Project-scoped feeds.
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'specific'
        )]
        [System.String]
        $ProjectName,
        
        # The AzureDevOps Feed Name.
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'specific'
        )]
        [System.String]
        $ArtifactFeed, 

        # An optional path where to save created credentials for operations.
        [Parameter(Mandatory = $false)]
        [System.String]
        $CredentialPath
    )

    if($PSBoundParameters.ContainsKey('Feedname')){
        $PSRepositoryName = "$Feedname-DevOpsFeed"
        $source = Get-DevOpsArtifactFeeds -Scope All | Where-Object -Property Name -EQ -Value $Feedname | Select-Object -ExpandProperty url
    }
    else {
        $PSRepositoryName = "$ArtifactFeed-DevOpsFeed"
        if([System.String]::IsNullOrEmpty($ProjectName)){
            $source = "https://pkgs.dev.azure.com/$Organization/_packaging/$ArtifactFeed/nuget/v2" -replace ' ','%20'
        } else {
            $source = "https://pkgs.dev.azure.com/$Organization/$ProjectName/_packaging/$ArtifactFeed/nuget/v2" -replace ' ','%20'
        }
    }


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

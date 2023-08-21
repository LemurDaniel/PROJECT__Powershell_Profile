
<#
    .SYNOPSIS
    Imports a repository from a source project to a target project.

    .DESCRIPTION
    Imports a repository from a source project to a target project.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    return the number of replacements

    .EXAMPLE

    Import a repository from a source to a target Project and open it in the Browser:

    PS> Start-RepositoryImport -SourceProject <project> -SourceRepositoryName <repository> -TargetProject <project> -openBrowser

    .LINK
        
#>

function Start-RepositoryImport {

    param(
        # The Source Project to Import the repository from.
        [Parameter(
            Mandatory = $true
        )]
        [ValidateScript(
            { 
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-DevOpsProjects).name
            },
            ErrorMessage = 'Please specify a correct Projectname.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-OrganizationInfo).projects.name
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $SourceProject,

        # The Target Project to Import the repository into.
        [Parameter(
            Mandatory = $true
        )]
        [ValidateScript(
            { 
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-DevOpsProjects).name
            },
            ErrorMessage = 'Please specify a correct Projectname.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-OrganizationInfo).projects.name
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $TargetProject,

        # The name of a repository in the source project.
        [Parameter(
            Mandatory = $true
        )]   
        [ValidateScript(
            { 
                # NOTE cannot access Project when changes dynamically with tab-completion
                $true # $_ -in (Get-ProjectInfo 'repositories.name')
            },
            ErrorMessage = 'Please specify an correct Name.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = Get-ProjectInfo -Name $fakeBoundParameters['SourceProject'] -return 'repositories.name'
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $SourceRepositoryName,

        # A custom Pat token to provie. If not provided will create a pat token with minimal permissions in current Organization Context.
        [Parameter(
            Mandatory = $false
        )]
        [System.Management.Automation.PSCredential]
        $patToken,

        # Switch to open the repository in the Browser.
        [Parameter(
            Mandatory = $true
        )]
        [switch]
        $openBrowser
    )


    if ($SourceProject -eq $TargetProject) {
        throw "TargetProject can't be the same as the SourceProject!"
    }


    $patToken = $patToken ?? (Get-Pat -Name 'AUTO_importrepository' -Organization (Get-DevOpsContext -Organization) -PatScopes vso.code_manage -HoursValid 1)
 
    $repositoryInfoTarget = $null
    $repositoryInfoSource = Get-RepositoryInfo -Project $SourceProject -Name $SourceRepositoryName
    $projectInfoSource = Get-ProjectInfo -Name $SourceProject
    $projectInfoTarget = Get-ProjectInfo -Name $TargetProject

    try {
        $Request = @{
            Project = $projectInfoTarget.Name
            Method  = 'GET'
            SCOPE   = 'PROJ'
            API     = "/_apis/git/repositories/$($repositoryInfoSource.name)?api-version=7.0"
        }
        $repositoryInfoTarget = Invoke-DevOpsRest @Request
    }
    catch {
        if ($_.ErrorDetails.Message.contains('GitRepositoryNotFoundException')) {
            
            $Request = @{
                Project = $projectInfoTarget.Name
                Method  = 'POST'
                SCOPE   = 'PROJ'
                API     = '/_apis/git/repositories?api-version=7.0'
                Body    = @{
                    name = $repositoryInfoSource.name
                }
            }
            $repositoryInfoTarget = Invoke-DevOpsRest @Request

        }
        else {
            throw $_
        }
    }

    try {

        $Request = @{
            Method = 'POST'
            SCOPE  = 'ORG'
            API    = '/_apis/serviceendpoint/endpoints?api-version=7.0'
            Body   = @{
                authorization                    = @{
                    scheme     = 'UsernamePassword'
                    parameters = @{
                        username = $null
                        password = $patToken.password | ConvertFrom-SecureString -AsPlainText
                    }
                }
                type                             = 'git'
                name                             = "endpoint-o.O-$($projectInfoSource.id)-$($repositoryInfoSource.name)"
                url                              = $repositoryInfoSource.webUrl
                serviceEndpointProjectReferences = @(
                    @{ 
                        projectReference = @{
                            id   = $projectInfoSource.id
                            name = $projectInfoSource.Name
                        }
                        name             = "endpoint-o.O-$($projectInfoSource.id)-$($repositoryInfoSource.id)"
                    },
                    @{ 
                        projectReference = @{
                            id   = $projectInfoTarget.id
                            name = $projectInfoTarget.Name
                        }
                        name             = "endpoint-o.O-$($projectInfoTarget.id)-$($repositoryInfoTarget.id)"
                    }
                )
            }
        }
        $serviceEndpoint = Invoke-DevOpsRest @Request

        Start-Sleep -Milliseconds 500
        
        # Import Repository
        $Request = @{
            Project = $projectInfoTarget.Name
            Method  = 'POST'
            SCOPE   = 'PROJ'
            API     = "/_apis/git/repositories/$($repositoryInfoTarget.id)/importRequests?api-version=7.0"
            Body    = @{
                parameters = @{
                    #deleteServiceEndpointAfterImportIsDone = $true
                    serviceEndpointId = $serviceEndpoint.id
                    tfvcSource        = $null
                    gitSource         = @{
                        overwrite = $false
                        url       = $repositoryInfoSource.webUrl
                    }
                }
            }
        }
        Invoke-DevOpsRest @Request

        if ($openBrowser) {
            Start-Process $repositoryInfoTarget.webUrl
        }
    }
    catch {
        Write-Host -ForegroundColor Red $_
    }
    finally {
        if ($null -ne $serviceEndpoint) {
            $Request = @{
                Method = 'DELETE'
                SCOPE  = 'ORG'
                API    = "/_apis/serviceendpoint/endpoints/$($serviceEndpoint.id)?api-version=7.0"
                Query  = @{
                    projectIds = @($projectInfoSource.id, $projectInfoTarget.Id) -join ','
                }
            }
            Invoke-DevOpsRest @Request
        }
    }
}
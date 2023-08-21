
<#
    .SYNOPSIS
    Gets all recent terraform-submodule tags of repositories named terraform. (Project DC Migration specific)

    .DESCRIPTION
    Gets all recent terraform-submodule tags of repositories named terraform. (Project DC Migration specific)

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    return the number of replacements


    .EXAMPLE

    Gets all recent terraform-submodule tags:

    PS> Get-RecentSubmoduleTags


    .LINK
        
#>

function Get-RecentSubmoduleTags {

    param(
        # The Name of the Project. If null will default to current Project-Context.
        [Parameter(
            Mandatory = $false,
            Position = 0
        )]
        [ValidateScript(
            { 
                $null -eq $_ -OR [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-DevOpsProjects).name
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
        $Project = "DC Azure Migration",

        # Refresh any cached values.
        [Parameter()]
        [switch]
        $Refresh
    )



    $moduleSourceReferenceCached = Get-AzureDevOpsCache -Type ModuleTags -Identifier $Project

    if ($null -ne $moduleSourceReferenceCached -AND $Refresh -ne $true) {
        Write-Host -ForegroundColor Yellow 'Fetching Cached Tags'
        return $moduleSourceReferenceCached
    }



    Write-Host -ForegroundColor Yellow 'Fetching Latest Tags'

    # Query All Repositories in DevOps
    $repositories = (Get-ProjectInfo -Name $Project).repositories

    foreach ($repository in $repositories) {

        Write-Host "Fetching Repository $($repository.name)"
        # Call Api to get all tags on Repository and sort them by newest
        $sortedTags = Get-RepositoryRefs -Project $repository.project.name -Name $repository.name -Tags | `
            Select-Object -Property `
        @{
            Name       = 'Tag'; 
            Expression = { $_.name.Split('/')[2] } 
        }, `
        @{
            Name       = 'TagIntSorting'; 
            Expression = { 
                return [String]::Format('{0:d4}.{1:d4}.{2:d4}', 
                    @($_.name.split('/')[2].Split('.') | ForEach-Object { [int32]::parse($_) })
                ) 
            }
        } | Sort-Object -Property TagIntSorting -Descending
    

        # If no tag is present, skip further processing
        if ($null -eq $sortedTags -OR $sortedTags.Count -eq 0) {
            $repository | Add-Member -MemberType NoteProperty -Name _TagsAssigned -Value $false
            continue
        }
        else {
            $repository | Add-Member -MemberType NoteProperty -Name _TagsAssigned -Value $true

            $regexQuery = "source\s*=\s*`"git::$($repository.remoteUrl.Replace('/', '\/{0,10}'))\/{0,10}[^\/]*?ref=\d+.\d+.\d+`"".Replace('\\/{0,1}', '\/{0,1}')
            $repository | Add-Member -MemberType NoteProperty -Name CurrentTag -Value $sortedTags[0].Tag
            $repository | Add-Member -MemberType NoteProperty -Name regexQuery -Value $regexQuery

            # Following not done, because it misses subpaths on repos like:
            #   - git::https://<...>/terraform-azurerm-acf-monitoring//alert-processing-rules?ref=1.0.52
            #   - git::https://<...>/terraform-azurerm-acf-monitoring//action-groups?ref=1.0.52

            # $regexReplacement = "source = `"git::$($repository.remoteUrl)?ref=$($sortedTags[0].Tag)`""
            #$repository | Add-Member -MemberType NoteProperty -Name regexReplacement -Value $regexReplacement
        }
    
    }

    $moduleSourceReferenceCached = $repositories | Where-Object -Property _TagsAssigned -EQ -Value $true
    return Set-AzureDevOpsCache -Object $moduleSourceReferenceCached -Type ModuleTags -Identifier $Project
}
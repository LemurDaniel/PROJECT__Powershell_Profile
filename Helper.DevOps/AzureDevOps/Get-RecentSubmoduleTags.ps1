function Get-RecentSubmoduleTags {

    param(
        [Parameter()]
        [switch]
        $forceApiCall = $false
    )

    $ProjectName = Get-DevOpsCurrentContext -Project
    $moduleSourceReferenceCached = Get-AzureDevOpsCache -Type ModuleTags -Identifier $ProjectName
    if ($null -ne $moduleSourceReferenceCached -AND $forceApiCall -ne $true) {
        Write-Host -ForegroundColor Yellow 'Fetching Cached Tags'
        return $moduleSourceReferenceCached
    }

    Write-Host -ForegroundColor Yellow 'Fetching Latest Tags'

    # Query All Repositories in DevOps
    $devopsRepositories = Get-ProjectInfo 'repositories'
    $preferencedRepos = Search-In $devopsRepositories -is 'terraform' -Multiple  

    
    foreach ($repository in $preferencedRepos) {

        # Call Api to get all tags on Repository and sort them by newest
        $sortedTags = Get-RepositoryRefs -repositoryId $repository.id | Where-Object { $_.name.contains('tags') } | `
            Select-Object -Property `
        @{Name = 'Tag'; Expression = { $_.name.Split('/')[2] } }, `
        @{Name = 'TagIntSorting'; Expression = { 
                return [String]::Format('{0:d4}.{1:d4}.{2:d4}', @($_.name.split('/')[2].Split('.') | ForEach-Object { [int32]::parse($_) })) 
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

    $moduleSourceReferenceCached = $preferencedRepos | Where-Object { $_._TagsAssigned }
    return Set-AzureDevOpsCache -Object $moduleSourceReferenceCached -Type ModuleTags -Identifier $ProjectName
}
function Remove-AutomatedTags {

    param()

    $currentTags = Get-RepositoryRefs | Where-Object { $_.name.contains('tags') }
    $repositoryId = Get-RepositoryInfo -Property 'id'
    $Request = @{
        Method  = 'POST'
        CALL    = 'PROJ'
        API     = "/_apis/git/repositories/$repositoryId/refs?api-version=6.1-preview.1"
        AsArray = $true
        Body    = @(
            $currentTags | `
                Where-Object { $_.creator.uniqueName -eq (Get-AzContext).Account.Id } | `
                ForEach-Object {
                @{
                    repositoryId = $repositoryId
                    name         = $_.name
                    oldObjectId  = $_.objectId
                    newObjectId  = '0000000000000000000000000000000000000000'  
                }
            }
        ) 
    }

    Invoke-DevOpsRest @Request 
}
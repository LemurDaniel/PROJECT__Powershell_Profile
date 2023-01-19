function New-AutomatedTag {

    param()

    $currentTags = Get-RepositoryRefs | Where-Object { $_.name.contains('tags') } | `
        ForEach-Object { return $_.name.split('/')[-1] } | `
        ForEach-Object { 
        return [String]::Format('{0:d4}.{1:d4}.{2:d4}', 
            [int32]::parse($_.split('.')[0]), [int32]::parse($_.split('.')[1]), 
            [int32]::parse($_.split('.')[2]))
    } | Sort-Object -Descending

    $newTag = '1.0.0'
    if ($currentTags) {
        $currentTags = $currentTags[0].split('.')
        $carry = 1;
        for ($i = $currentTags.length - 1; $i -ge 0; $i--) {
            $nextNum = [int32]::parse($currentTags[$i]) + $carry
            $carry = [math]::floor($nextNum / 10)
            $currentTags[$i] = $nextNum % 10
        }
        $newTag = $currentTags -join '.'
    }   

    $repositoryId = Get-RepositoryInfo -Property 'id'

    $Request = @{
        Method = 'POST'
        CALL   = 'PROJ'
        API    = "/_apis/git/repositories/$repositoryId/annotatedtags"
        Body   = @{
            name         = $newTag
            taggedObject = @{
                objectId = git rev-parse HEAD
            }
            message      = "Automated Test Tag ==> $newTag"
        }
    }
    Invoke-DevOpsRest @Request

    Write-Host "🎉 New Tag '$newTag' created  🎉"
}

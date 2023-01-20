function New-BranchFromWorkitem {

    [Alias('gitW')]
    param (
        [Parameter()]
        [System.String[]]
        $SearchTags
    )    

    git -C . rev-parse >nul 2>&1; 
    if (!$?) {
        throw 'Please exexcute command inside a Repository'
    }


    $workItem = Search-WorkItemInIteration -SearchTags $SearchTags -Current -Personal -Single

    if (!$workItem) {
        Write-Host -ForegroundColor RED 'Error: Work Item not found!'
    }
    else {
        $transformedTitle = $workItem.'System.Title'.toLower() -replace '[?!:\/\\\-\s]+', '_'
        $branchName = "features/$($workItem.'System.id')-$transformedTitle"
        
        git checkout master
        git pull origin master
        git checkout dev
        git pull origin dev
        git checkout -b "$branchName"
    }

}

function Start-Pipeline {
  [cmdletbinding()]
  param (
    [Parameter()]
    [Alias('is')]
    [System.String[]]
    $SearchTags,

    [Parameter()]
    [ValidateSet('Branch', 'Dev', 'Master', 'Both')]
    [System.String]
    $environment = 'Branch',

    [Parameter()]
    [Alias('not')]
    [System.String[]]
    $excludedTags = @(),

    [Parameter()]
    [switch]
    $Multiple
  )


  $Organization =  Get-DevOpsCurrentContext -Organization
  $projectNameUrlEncoded = (Get-ProjectInfo 'name') -replace ' ', '%20'
  
  # Get Pipelines.
  $Request = @{
    Method = 'GET'
    Domain = 'dev.azure'
    SCOPE  = 'PROJ'
    API    = '_apis/pipelines?api-version=7.0'
  }
  $Pipelines = Invoke-DevOpsRest @Request

  # Search Pipelines by tags.
  $Pipelines = Search-In ($Pipelines.value) -where 'name' -is $SearchTags -not $excludedTags -Multiple:$Multiple

  # Action for each Pipeline.
  $Pipelines | ForEach-Object { 

    # Run Pipeline from Branch, dev or master
    if ($environment -eq 'Branch') {
      $currentBranch = git branch --show-current
      Start-PipelineOnBranch -id $_.id -ref "refs/heads/features/$currentBranch"
    }

    if ($environment -eq 'dev' -OR $environment -eq 'both') {
      Start-PipelineOnBranch -id $_.id -ref 'refs/heads/dev'
    }

    if ($environment -eq 'master' -OR $environment -eq 'both') {
      Start-PipelineOnBranch -id $_.id -ref 'refs/heads/master'
    }

    # Open in Browser.
    $pipelineUrl = "https://dev.azure.com/$Organization/$projectNameUrlEncoded/_build?definitionId=$($_.id)"

    Write-Host -Foreground Green '      '
    Write-Host -Foreground Green " 🎉 Started Pipeline '$($_.folder)/folder$($_.name)'  on $environment 🎉  "
    Write-Host -Foreground Green "    $pipelineUrl "
    Write-Host -Foreground Green '      '

    Start-Process $pipelineUrl
  }

}
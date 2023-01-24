function Get-WorkItemRelationType {

    [CmdletBinding()]
    param (

        [Parameter()]
        [ValidateScript(
            {
                $_ -in ((Get-Content "$PSScriptRoot\WorkItemRelationTypes.json") | ConvertFrom-Json).value.name
            }
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = ((Get-Content "$PSScriptRoot\WorkItemRelationTypes.json") | ConvertFrom-Json).value.name
     
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $RelationType,


        [Alias('return')]
        [Parameter()]
        [System.String]
        $Property
    )

    $workItemRelationType = ((Get-Content "$PSScriptRoot\WorkItemRelationTypes.json") | ConvertFrom-Json).value | Where-Object -Property name -EQ -Value $RelationType
    return Get-Property -Object $workItemRelationType -Property $Property
}
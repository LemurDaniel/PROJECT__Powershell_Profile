
<#
    .SYNOPSIS
    Start sveral Pipelines in successive order.

    .DESCRIPTION
    Start sveral Pipelines in successive order.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Start sveral Pipelines in successive order on the Dev-Branch

    PS> Start-PipelinesInOrder Dev


    .LINK
        
#>
function Start-PipelinesInOrder {
    
    [cmdletbinding()]
    param (
        # The Branch to start all Pipelines on
        [Parameter(
            Position = 0
        )]
        [ValidateSet('Dev', 'Master')]
        [System.String]
        $environment = 'Dev',

        # All Layers of Pipelines in DC Azure Migration
        [Parameter()]
        [System.String[][]]
        $Layers = @(
            @(
                'level1_landingzone_foundations'
            ),
            @(
                'level2_landingzone_acf_hub', 
                'level2_landingzone_acf_hub_dns_zones'
            ),
            @(
                'level3_landingzone_shared_services'
            ),
            @(
                'level4_landingzone_appzone-nonprod', 
                'level4_landingzone_appzone-prod'
            )
        ),

        # Whether to open the Pipeline in the Browser.
        [Parameter()]
        [switch]
        $OpenBrowser
    )

    foreach ($pipelines in $Layers) {
    
        # Start one Layer of Pipelines as Jobs.
        $jobs = [System.Collections.Hashtable]::new()
        $pipelines | ForEach-Object {
            
            Write-Host -ForegroundColor Green "Started Pipeline: '$($_)'"
            $pipelineId = Search-In (Get-DevOpsPipelines) -where name -has $_ -return id
            $build = Start-PipelineOnBranch -id $pipelineid -ref "refs/heads/$($environment.ToLower())"

            if ($OpenBrowser) {
                $Organization = Get-DevOpsContext -Organization
                $projectNameUrlEncoded = (Get-ProjectInfo 'name') -replace ' ', '%20'
                $pipelineUrl = "https://dev.azure.com/$Organization/$projectNameUrlEncoded/_build?definitionId=$($Pipeline.id)"
                Start-Process $pipelineUrl
            }

            $Helper = Get-Item "$PSScriptRoot/../../../DevOpsScripts"
            $job = Start-Job `
                -ArgumentList $Helper.FullName, $build.id, $OpenBrowser `
                -ScriptBlock {

                Import-Module Microsoft.PowerShell.Utility
                Import-Module $args[0]
            
                $buildId = $args[1]

                $Request = @{
                    METHOD   = 'GET'
                    DOMAIN   = 'dev.azure'
                    CALL     = 'PROJ'
                    Property = 'status'
                }

                $running = $true
                while ($running) {
                    Start-Sleep -Seconds 20
                    $status = Invoke-DevOpsRest @Request -API "/_apis/build/builds/$($buildId)?api-version=7.0"
                    $running = $status -eq 'notStarted' -or $status -eq 'inProgress'
                }

                return $status
            }
            $null = $jobs.add($_, $job)
        } 


        # Check for completion of Pipelines.
        while ($jobs.Keys.length -gt 0) {
            Start-Sleep -Seconds 15

            $completed = [System.Collections.ArrayList]::new()
            $jobs.GetEnumerator() | ForEach-Object {
                Write-Host -ForegroundColor Yellow "    Check for completion of Pipeline: '$($_.Key)'"
                $job = Get-Job -Id $_.Value.id

                if ($job.State -ne 'running') {
                    $result = Receive-Job -Job $_.Value
                    if ($result -ne 'completed') {
                        throw "An Error occured in Pipeline '$($_.Key)' - $result"
                    }
                    else {
                        Write-Host -ForegroundColor Green "Completion of Pipeline: '$($_.Key)'"
                        $null = $completed.Add($_.Key)
                    }
                }
            }
            $null = $completed | ForEach-Object { $jobs.Remove($_) }
        }
    }
}
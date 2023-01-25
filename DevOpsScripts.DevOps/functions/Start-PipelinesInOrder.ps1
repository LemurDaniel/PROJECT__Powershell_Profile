
function Start-PipelinesInOrder {
    
    [cmdletbinding()]
    param (
        [Parameter(
            Position = 0
        )]
        [ValidateSet('Dev', 'Master')]
        [System.String]
        $environment = 'Dev',

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
        )
    )

    foreach ($pipelines in $Layers) {
    
        # Start one Layer of Pipelines as Jobs.
        $jobs = [System.Collections.Hashtable]::new()
        $pipelines | ForEach-Object {
            
            Write-Host -ForegroundColor Green "Started Pipeline: '$($_)'"
            $pipelineId = Search-In (Get-DevOpsPipelines) -where name -is $_ -return id

            $Helper = Get-Item "$PSScriptRoot/../../Helper"
            $job = Start-Job `
                -ArgumentList $Helper.FullName, $pipelineId, $environment `
                -ScriptBlock {

                Import-Module Microsoft.PowerShell.Utility
                Import-Module $args[0]
            
                $pipelineid = $args[1]
                $environment = $args[2]
                $build = Start-PipelineOnBranch -id $pipelineid -ref "refs/heads/$($environment.ToLower())"

                $Request = @{
                    METHOD   = 'GET'
                    DOMAIN   = 'dev.azure'
                    CALL     = 'PROJ'
                    Property = 'status'
                }

                $running = $true
                while ($running) {
                    Start-Sleep -Seconds 20
                    $status = Invoke-DevOpsRest @Request -API "/_apis/build/builds/$($build.id)?api-version=7.0"
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
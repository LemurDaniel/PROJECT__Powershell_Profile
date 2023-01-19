function Invoke-DevOpsRest {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $METHOD,

        [Alias('Type')]
        [Parameter()]
        [System.String]
        [ValidateSet('dev', 'dev.azure', 'vssps', 'vssps.dev.azure', 'vsaex.dev', 'app.vssps.visualstudio')]
        $DOMAIN = 'dev.azure',

        [Alias('Call')]
        [Parameter()]
        [ValidateSet('ORG', 'PROJ', 'TEAM')]
        [System.String]
        $SCOPE = 'ORG',

        [Parameter()]
        [System.String]
        $API,

        [Parameter()]
        [System.Collections.Hashtable]
        $Query,

        [Parameter()]
        [PSCustomObject]
        $Body,

        [Alias('return')]
        [Parameter()]
        [System.String]
        $Property,

        [Parameter()]
        [System.String]
        $team = 'DC Azure Migration Team',

        [Parameter()]
        [System.String]
        $Uri,

        [Parameter()]
        [switch]
        $AsArray,

        [parameter()]
        [string]
        $contentType
    )


    $Organization = Get-DevOpsCurrentContext -Organization
    $apiVersion = [regex]::Matches($API, '\?api-version=.+').Value
    if (!$apiVersion) {
        throw "Please append the Api-Version behind the API: '?api-version=7.0'"
    }

    $APIEndpoint = $API.replace($apiVersion, '')
    $Query = $null -ne $Query ? $Query : [System.Collections.Hashtable]::new()
    $Query.Add('api-version', $apiVersion.split('=')[1])
    $QueryString = ($Query.GetEnumerator() | `
            Sort-Object -Descending { $_.Name -ne 'api-version' } | `
            ForEach-Object { "$($_.Name)=$($_.Value)" }) -join '&'

    if (!($PSBoundParameters.Keys -contains 'contentType')) {
        $calculatedContentType = $Method -eq [Microsoft.PowerShell.Commands.WebRequestMethod]::Get ? 'application/x-www-form-urlencoded' : 'application/json; charset=utf-8'
    }
    else {
        $calculatedContentType = $contentType
    }

    switch ($SCOPE) {
        'NONE' {
            $TargetURL = "https://$Domain.com/$APIEndpoint`?$QueryString"
            break
        }
        'ORG' { 
            $TargetURL = "https://$Domain.com/$Organization/$APIEndpoint`?$QueryString"
            break
        }
        'PROJ' { 
            $project = Get-ProjectInfo 'id'
            $TargetURL = "https://$Domain.com/$Organization/$project/$APIEndpoint`?$QueryString"
            break
        }
        'TEAM' { 
            $project = Get-ProjectInfo 'id'
            $team = Search-In (Get-ProjectInfo 'teams') -where name -is $team
            $TargetURL = "https://$Domain.com/$Organization/$($project)/$($team.id)/$APIEndpoint`?$QueryString"
            break
        }
    }

    $token = (Get-AzAccessToken -ResourceUrl '499b84ac-1321-427f-aa17-267ca6975798').Token
    $Request = @{
        Method  = $Method
        Body    = $body | ConvertTo-Json -Depth 8 -Compress -AsArray:$AsArray
        Headers = @{ 
            username       = 'O.o'
            Authorization  = "Bearer $token"
            'Content-Type' = $calculatedContentType
        }
        Uri     = [System.String]::IsNullOrEmpty($Uri) ? $TargetURL : $Uri
    }

    Write-Verbose 'BODY START'
    Write-Verbose ($Request | ConvertTo-Json -Depth 8)
    Write-Verbose 'BODY END'

    $response = Invoke-RestMethod @Request

    if ($response.GetType() -eq [System.String] -AND $response.toLower().contains('sign out')) {
        Disconnect-AzAccount 
        Connect-AzAccount
        $response | ConvertTo-Json | Out-File test.json
        $response | Out-File test.html
    }

    Write-Verbose ($response | ConvertTo-Json -Depth 8)

    Get-Property -Object $response -Property $Property
}
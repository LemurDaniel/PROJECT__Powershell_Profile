function Invoke-DevOpsRest {

    [cmdletbinding()]
    param(
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet([HttpMethods])]
        $Method,

        [Parameter()]
        [System.String]
        [ValidateSet('dev', 'dev.azure', 'vssps', 'vssps.dev.azure', 'vsaex.dev', 'app.vssps.visualstudio')]
        $Domain = 'dev.azure',

        [Parameter()]
        [ValidateSet('ORG', 'PROJ', 'TEAM')]
        [System.String]
        $CALL = 'ORG',

        [Parameter()]
        [System.String]
        $API,

        [Parameter()]
        [PSCustomObject]
        $Body,

        [Parameter()]
        [System.String]
        $Property,

        [Parameter()]
        [System.String]
        $Uri,

        [Parameter()]
        [System.String[]]
        $TeamQuery = @('Azure', 'Migration'),

        [Parameter()]
        [System.String]
        [ValidateSet([Project])]
        $ProjectName = [Project]::Default,

        [Parameter()]
        [System.String]
        [ValidateSet([DevOpsOrganization])]
        $Organization = [DevOpsOrganization]::Default,

        [Parameter()]
        [switch]
        $AsArray
    )

    switch ($CALL) {
        'ORG' { 
            $TargetURL = "https://$Domain.com/$Organization/$API"
            continue
        }
        'PROJ' { 
            $project = ([Project]::GetByName($ProjectName))
            $TargetURL = "https://$Domain.com/$Organization/$($project.id)/$API"
        }
        'TEAM' { 
            $project = ([Project]::GetByName($ProjectName))
            $team = Search-Int $project.teams -is $TeamQuery
            $TargetURL = "https://$Domain.com/$Organization/$($project.id)/$($team.id)/$API"
        }
    }

    $token = (Get-AzAccessToken -ResourceUrl '499b84ac-1321-427f-aa17-267ca6975798').Token
    $Request = @{
        Method  = $Method
        Body    = $body | ConvertTo-Json -Compress -AsArray:$AsArray
        Headers = @{ 
            username       = 'O.o'
            password       = $token
            Authorization  = "Bearer $($token)"
            #Authorization    = "Basic $token"
            'Content-Type' = $Method.ToLower() -eq 'get' ? 'application/x-www-form-urlencoded' : 'application/json; charset=utf-8'
        }
        Uri     = $Uri.Length -gt 0 ? $Uri : ($TargetURL -replace '/+', '/' -replace '/$', '' -replace ':/', '://')
    }

    if (!$Request.Uri.contains('api-version')) {
        $Request.Uri += ($Request.Uri.contains('?') ? '&' : '?') + 'api-version=7.1-preview.1'
    }

    Write-Verbose 'BODY START'
    Write-Verbose ($Request | ConvertTo-Json)
    Write-Verbose 'BODY END'

    $response = Invoke-RestMethod @Request

    Write-Verbose ($response | ConvertTo-Json)

    if (![string]::IsNullOrEmpty($Property)) {
        return $response | ForEach-Object { $_."$Property" } 
    }
    else {
        return $response
    }
}

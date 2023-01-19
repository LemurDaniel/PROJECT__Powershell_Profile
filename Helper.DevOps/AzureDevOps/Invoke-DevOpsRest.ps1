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
        [PSCustomObject]
        $Body,

        [Parameter()]
        [System.String]
        $Property,

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
    switch ($SCOPE) {
        'NONE' {
            $TargetURL = "https://$Domain.com/$API"
            break
        }
        'ORG' { 
            $TargetURL = "https://$Domain.com/$Organization/$API"
            break
        }
        'PROJ' { 
            $project = Get-ProjectInfo 'id'
            $TargetURL = "https://$Domain.com/$Organization/$project/$API"
            break
        }
        'TEAM' { 
            $project = Get-ProjectInfo 'id'
            $team = Get-ProjectInfo 'teams' | Where-Object -Property name -Like -Value 'DC Azure Migration Team'
            $TargetURL = "https://$Domain.com/$Organization/$($project)/$($team.id)/$API"
            break
        }
    }

    if (!($PSBoundParameters.Keys -contains 'contentType')) {
        $calculatedContentType = $Method -eq [Microsoft.PowerShell.Commands.WebRequestMethod]::Get ? 'application/x-www-form-urlencoded' : 'application/json; charset=utf-8'
    }
    else {
        $calculatedContentType = $contentType
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
        Uri     = $Uri.Length -gt 0 ? $Uri : ($TargetURL -replace '/+', '/' -replace '/$', '' -replace ':/', '://')
    }

    if (!$Request.Uri.contains('api-version')) {
        $Request.Uri += ($Request.Uri.contains('?') ? '&' : '?') + 'api-version=7.1-preview.1'
    }

    Write-Verbose 'BODY START'
    Write-Verbose ($Request | ConvertTo-Json -Depth 8)
    Write-Verbose 'BODY END'


    $response = Invoke-RestMethod @Request

    Write-Verbose ($response | ConvertTo-Json -Depth 8)

    Get-Property -Object $response -Property $Property
}
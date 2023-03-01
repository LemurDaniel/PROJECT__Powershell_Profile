
<#
    .SYNOPSIS
    Function to invoke the DevOps-Rest API.

    .DESCRIPTION
    Function to invoke the DevOps-Rest API. User needs to be connected via Connect-AzAccount for Access-Token Generation.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    return the API-Response.


    .EXAMPLE

    Invoke the DevOps API to return User-Information:

    $Request = @{
        Method = 'GET'
        Call   = 'None'
        Domain = 'app.vssps.visualstudio'
        API    = '_apis/profile/profiles/me?api-version=6.0'
    }

    $User = Invoke-DevOpsRest @Request


    .EXAMPLE

    Invoke the DevOps API to return a batch of workitems from a list of ids:
    - The List of ids is provided as a Query Parameter
    - Specified to automatically return value attribute from response.

    # Note any Query-Parameter can be encoded directly in the API-String:
    #   '_apis/wit/workitems'
    # Or via the Query-Parameter
    # Query = @{
    #      'api-version' = '7.0' 
    # }

    $Request = @{
        Method = 'GET'
        SCOPE  = 'PROJ'
        API    = '_apis/wit/workitems'
        Query  = @{
            'api-version' = '7.0'
            ids = @('84646', '95937') -join ','
        }
    }

    $response = Invoke-DevOpsRest @Request -return 'value'

    .LINK
        
#>

function Invoke-DevOpsRest {

    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        # The Rest-Method to use.
        [Parameter(Mandatory = $true)]
        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $METHOD,

        # The API-Domain. List is incomplete.
        [Alias('Type')]
        [Parameter()]
        [System.String]
        [ValidateSet('dev', 'dev.azure', 'vssps', 'vssps.dev.azure', 'vsaex.dev', 'app.vssps.visualstudio', 'feeds.dev.azure')]
        $DOMAIN = 'dev.azure',

        # The scope to call. None, Organization, Project, Team.
        [Alias('Call')]
        [Parameter()]
        [ValidateSet('ORG', 'PROJ', 'TEAM', 'NONE')]
        [System.String]
        $SCOPE = 'ORG',

        # The API-Endpoint to call.
        [Parameter()]
        [System.String]
        $API,

        # Any Query-Parameters that are not specifed in the API-String
        [Parameter()]
        [System.Collections.Hashtable]
        $Query,

        # Body for POST, PUT, etc. requests.
        [Parameter()]
        [PSCustomObject]
        $Body,

      
        # The Property to return from the items. If null will return full Properties.
        [Alias('return')]
        [Parameter()]
        [System.String]
        $Property,

        # The Team, when calling the team scope.
        [Parameter()]
        [System.String]
        $team = 'DC Azure Migration Team',

        # An optional URI to override the URI genration from Domain, Call, API.
        [Parameter()]
        [System.String]
        $Uri,

        # A switch parameter to Force interpret the Body as an array. (Single Value arrays may cause troubles by being interpreted as an object.)
        [Parameter()]
        [switch]
        $AsArray,

        # A String to override the content-type. Get automatically set for Get and Post. May not be right for specifig Endpoints.
        [parameter()]
        [string]
        $contentType,

        # A String to override the Project-Context.
        [parameter()]
        [string]
        $Organization,

        # A String to override the Project-Context.
        [parameter()]
        [string]
        $Project
    )


    $Organization = [System.String]::IsNullOrEmpty($Organization) ? (Get-DevOpsContext -Organization) : $Organization
    $APIEndpoint = ($API -split '\?')[0]
    
    # Build a hashtable of providedy Query params and Query params in provied api-url.
    $Query = $null -ne $Query ? $Query : [System.Collections.Hashtable]::new()
    $null = ($API -split '\?')[1] -split '&' | `
        Where-Object { ![System.String]::IsNullOrEmpty($_) } | `
        ForEach-Object { $Query.Add($_.split('=')[0], $_.split('=')[1]) }
    $QueryString = ($Query.GetEnumerator() | `
            Sort-Object -Descending { $_.Name -ne 'api-version' } | `
            ForEach-Object { "$($_.Name)=$($_.Value)" }) -join '&'


    if (!$Query['api-version']) {
        throw 'Please specify an api-version to use.'
    }


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
            $projectInfo = Get-ProjectInfo -Name $Project
            $TargetURL = "https://$Domain.com/$Organization/$($projectInfo.id)/$APIEndpoint`?$QueryString"
            break
        }
        'TEAM' { 
            $projectInfo = Get-ProjectInfo -Name $Project
            $teamInfo = Search-In $projectInfo.teams -where name -has $team
            $TargetURL = "https://$Domain.com/$Organization/$($projectInfo.id)/$($teamInfo.id)/$APIEndpoint`?$QueryString"
            break
        }
    }

    try {
        $token = (Get-AzAccessToken -ResourceUrl '499b84ac-1321-427f-aa17-267ca6975798').Token
    }
    catch {
        Connect-AzAccount
        # Automatically call login, when authentication failed
        #if ($_.Exception.Message.Contains('ClientSecretCredential authentication failed')) {
        #    Connect-AzAccount
        #}
    }

    $bodyByteArray = [System.Text.Encoding]::UTF8.GetBytes(($body | ConvertTo-Json -Depth 8 -Compress -AsArray:$AsArray))   
    $Request = @{        
        Method  = $Method       
        Body    = $bodyByteArray        
        Headers = @{            
            username       = 'O.o'          
            Authorization  = "Bearer $token"           
            'Content-Type' = $calculatedContentType       
        }        
        Uri     = [System.String]::IsNullOrEmpty($Uri) ? $TargetURL : $Uri    
    }

    Write-Verbose "Method: $([String]$Request.Method)"
    Write-Verbose "URI: $($Request.Uri)"
    Write-Verbose "BODY: $($body | ConvertTo-Json -Depth 8 -AsArray:$AsArray)"

    
    if ($PSCmdlet.ShouldProcess($Request.Uri, $($Request.Method))) {

        try {
            $response = Invoke-RestMethod @Request
        }
        catch {
            if ($_ -is [System.String]) {
                $excpetion = $_ | ConvertFrom-Json
                $excpetion
                if ($excpetion.typeKey -eq 'UnauthorizedRequestException') {
                    Connect-AzAccount
                    $response = Invoke-RestMethod @Request
                }
            }
        }

        if ($null -eq $response) {
            throw "Request received no value. Current User: $((Get-DevOpsUser).emailAddress)"
        }

        # TODO. If DevOps wants user to sign out and in for security reasons.
        if ($response.GetType() -eq [System.String] -AND $response.toLower().contains('sign out')) {
            Disconnect-AzAccount 
            Connect-AzAccount
            $response | ConvertTo-Json | Out-File test.json
            $response | Out-File test.html
        }

        Write-Verbose ($response | ConvertTo-Json -Depth 8)

        return Get-Property -Object $response -Property $Property

    }

}
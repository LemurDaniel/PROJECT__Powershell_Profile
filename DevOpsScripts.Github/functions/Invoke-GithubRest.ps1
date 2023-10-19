
<#
    .SYNOPSIS
    Function to invoke the Github-Rest API.

    .DESCRIPTION
    Function to invoke the Github-Rest API.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    return the API-Response.

    .EXAMPLE


    .EXAMPLE


    .LINK
        
#>

function Invoke-GithubRest {


    [CmdletBinding(
        SupportsShouldProcess = $true,
        DefaultParameterSetName = "api"
    )]
    param(
        # The Rest-Method to use.
        [Parameter(
            Mandatory = $true
        )]
        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $METHOD,

        # The API-Endpoint to call.
        [Parameter(
            Mandatory = $true,
            ParameterSetName = "api"
        )]
        [System.String]
        $API,


        # Override with complete url
        [Parameter(
            ParameterSetName = "url"
        )]
        [System.String]
        $URL,


        # Any Query-Parameters that are not specifed in the API-String
        [Parameter()]
        [System.Collections.Hashtable]
        $Query,

        # Body for POST, PUT, etc. requests.
        [Parameter()]
        [PSCustomObject]
        $Body,

        # A switch parameter to Force interpret the Body as an array. (Single Value arrays may cause troubles by being interpreted as an object.)
        [Parameter()]
        [switch]
        $AsArray,



        # When using scope Orgs.
        [parameter(
            Mandatory = $false
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = (Get-GithubContexts).login
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        #[validateScript(
        #    {
        #        $_ -in (Get-GithubContexts).login
        #    }
        #)]
        [System.String]
        $Context,

        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        #[ArgumentCompleter(
        #    {
        #        param($cmd, $param, $wordToComplete)
        #        $validValues = (Get-GithubAccountContext -ListAvailable).name
        #        
        #        $validValues | `
        #            Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
        #            ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
        #    }
        #)]
        #[validateScript(
        #    {
        #        $_ -in (Get-GithubAccountContext -ListAvailable).name
        #    }
        #)]
        $Account,



        # The affiliation of requested resources. owner for example only returns repositories that you are owner of.
        [parameter()]
        [ValidateScript(
            {
                ('owner,collaborator,organization_member'.split(',') | 
                Where-Object { 
                    $_ -NotIn @('owner', 'collaborator', 'organization_member') 
                } | Measure-Object).Count -eq 0
            }
        )]
        [System.String]
        $affiliation = 'owner,collaborator,organization_member',

        # The content type for the requests. Set to github default.
        [parameter()]
        [System.String]
        $ContentType = 'application/vnd.github+json',

        # The visibilty of requested resources. public for example only return public repositories, etc.
        [parameter()]
        [validateSet('all', 'public', 'private')]
        [System.String]
        $visibility = 'all',

        # The content type for the requests. Set to github default.
        [parameter()]
        [System.String]
        $apiVersion = '2022-11-28'
    )

    # Build a hashtable of providedy Query params and Query params in provied api-url.
    $Query = $null -ne $Query ? $Query : [System.Collections.Hashtable]::new()
    $Query.Add('affiliation', $affiliation)
    $Query.Add('visibility', $visibility)
    $Query.Add('per_page', 100)

    $APIEndpoint = ($API -split '\?')[0].replace('{org}', $Context)
    $null = ($API -split '\?')[1] -split '&' | `
        Where-Object { ![System.String]::IsNullOrEmpty($_) } | `
        ForEach-Object { $Query.Add($_.split('=')[0], $_.split('=')[1]) }


    $QueryString = ($Query.GetEnumerator() | `
            Sort-Object -Descending { $_.Name -ne 'api-version' } | `
            ForEach-Object { "$($_.Name)=$($_.Value)" }) -join '&'
    
    $bodyByteArray = [System.Text.Encoding]::UTF8.GetBytes(($body | ConvertTo-Json -Depth 8 -Compress -AsArray:$AsArray))   
    
    $AccountContext = Get-GithubAccountContext -Account $Account
    $PAT = Get-GithubPAT -Account $AccountContext.name -AsPlainText
    $Request = @{
        Method = $Method
        header = @{
            Accept                 = $contentType
            'X-GitHub-Api-Version' = $apiVersion
            Authorization          = "Bearer $PAT"
        }
        uri    = $PSBoundParameters.ContainsKey('URL') ? $URL : "https://" + ([System.String]::Format("{0}/{1}?{2}", $AccountContext.domain, $APIEndpoint, $QueryString) -replace '/+', '/')
        Body   = $bodyByteArray   
    }

    Write-Verbose $Request.uri

    Write-Verbose "Method: $([String]$Request.Method)"
    Write-Verbose "URI: $($Request.Uri)"
    Write-Verbose "BODY: $($body | ConvertTo-Json -Depth 8 -AsArray:$AsArray)"

    
    if ($PSCmdlet.ShouldProcess($Request.Uri, $($Request.Method))) {
        try {
            return Invoke-RestMethod @Request | ForEach-Object { $_ }
        }
        catch {
            Write-Host $_.ErrorDetails
            $ErrorDetails = $_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($ErrorDetails.message -eq "Bad credentials") {
                Write-Host -ForegroundColor Red "Request failed due to invalid Credentials!"
                Get-GithubPAT -Clear

                return Invoke-GithubRest @PSBoundParameters
            }
        }
    }

}

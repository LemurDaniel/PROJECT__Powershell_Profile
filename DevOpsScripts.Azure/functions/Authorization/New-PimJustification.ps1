
<#
    .SYNOPSIS
    Create a PIM-Justification based on the current branch.

    .DESCRIPTION
    Create a PIM-Justification based on the current branch.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Create a new PIM-Justification asking for a workitem:

    PS> New-PimJustification


    .LINK
        
#>

function New-PimJustification {

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            ValueFromRemainingArguments = $true
        )]
        [System.String]
        $Justification,

        [Parameter()]
        [switch]
        $noClipboard,

        [Parameter()]
        [switch]
        $ignoreBranch,

        [Parameter()]
        [System.String]
        $Organization = 'baugruppe',

        [Parameter()]
        [System.String]
        $Project = 'DC Azure Migration',

        [Parameter()]
        [Switch]
        $Refresh
    )

    Write-Host "`n"
    Write-Host -ForegroundColor Yellow ('**Checking branch for WorkItem Id**' | ConvertFrom-Markdown -AsVT100EncodedString).VT100EncodedString
    $currentBranchName = git branch --show-current
    if (!$ignoreBranch -AND $currentBranchName -match 'features/\d+-.*') {
        $workItemId = [regex]::Match(($currentBranchName -replace 'features/', ''), '^\d+').Value
        Write-Host -ForegroundColor Green "... Found Feature-Branch with workitem-Id: $workitemId"
    }
    else {

        
        Write-Host -ForegroundColor Red "`n... Your not on a Feature-Branch!`n"
        ############################################################
        ################# Getting active workitems #################
        ############################################################

        $workItemsActive = Get-UtilsCache -Type PimWorkItem -Identifier active
        if (!$workitemsActive -OR $PSBoundParameters.ContainsKey('Refresh')) {

            $QueryStatement = @'
SELECT  [System.Id], [System.Title], [System.State], [System.WorkItemType] 

FROM    WorkItems 

WHERE   [System.TeamProject]  = @project
AND [System.AssignedTo] = '{{USER}}'

ORDER BY [System.WorkItemType] ASC, [System.CreatedDate] DESC
'@ -replace '{{USER}}', (Get-AzContext).Account.Id

            if ((Get-AzContext).Account.Id.Contains('aadmin')) {
                Write-Host -ForegroundColor Yellow ('**Please Choose your normal User to validate the Workitem!**' | ConvertFrom-Markdown -AsVT100EncodedString).VT100EncodedString

                Connect-AzAccount 
                Write-Host -ForegroundColor Green "... Connected to Account '$((Get-AzContext).Account.Id)'"
            }
            # Custom Request to aviod dependency on DevOpsScripts.DevOps
            $token = (Get-AzAccessToken -ResourceUrl '499b84ac-1321-427f-aa17-267ca6975798').Token   
            $Request = @{
                Headers = @{            
                    username       = 'O.o'          
                    Authorization  = "Bearer $token"           
                    'Content-Type' = 'application/json; charset=utf-8'      
                }   
                Uri     = "https://dev.azure.com/$Organization/$Project/_apis/wit/wiql?api-version=5.1" -replace ' ', '%20'
                Method  = 'POST'
                Body    = @{
                    query = $QueryStatement
                } | ConvertTo-Json -Compress
            }
            $workItemsActive = Invoke-RestMethod @Request

            $Request.Uri = "https://dev.azure.com/$Organization/$Project/_apis/wit/workitemsbatch?`$expand=fields&api-version=7.0" -replace ' ', '%20'
            $Request.Body = @{
                ids = $workItemsActive.workItems.id
            } | ConvertTo-Json -Compress
            $workItemsActive = Invoke-RestMethod @Request

            #$workItemsActive = Set-UtilsCache -Object $workItemsActive.value -Type PimWorkItem -Identifier active -Alive 1440
        }
   
        $lastItem = Get-UtilsCache -Type PimWorkItem -Identifier last
        $workItemsActive = $workItemsActive | Where-Object -Property id -NE $lastItem.Id
        $Options = @(
            @{ display = 'Enter new Workitem ID'; workItemId = $null }
        )

        if ($lastItem) {
            $options += @(
                @{ 
                    display    = "Last Workitem: [$($lastItem.fields.'System.WorkItemType') - $($($lastItem.id))] $($lastItem.fields.'System.Title')"
                    workItemId = $lastItem.id
                }
            )
        }
        $workItemsActive | ForEach-Object {
            $options += @(
                @{ 
                    display    = "[$($_.fields.'System.WorkItemType') - $($($_.id))] $($_.fields.'System.Title')"
                    workItemId = $_.id
                }
            )
        }
  
        $pimWorkItemPollResult = Select-ConsoleMenu -Description "Please choose one of your active Workitems:" -Property display -Options $options

        if ($null -eq $pimWorkItemPollResult.workItemId) {
            $workItemId = [regex]::Match((Read-Host -Prompt "`n... Please Enter a valid WorkItem ID"), '^\d+').Value
        }
        else {
            $workItemId = $pimWorkItemPollResult.workItemId
        }

    }


    ############################################################
    # Validating chosen Workitem.
    ############################################################

    ################# Getting WorkItem from Cache #################
    Write-Host "`n"
    Write-Host -ForegroundColor Yellow ('**Validating WorkItem ID**' | ConvertFrom-Markdown -AsVT100EncodedString).VT100EncodedString
    $workItem = Get-UtilsCache -Type PimWorkItem -Identifier $workItemId

    ################# Getting WorkItem from API #################
    if (!$workItem) {
        if ((Get-AzContext).Account.Id.Contains('aadmin')) {
            Write-Host -ForegroundColor Yellow ('**Please Choose your normal User to validate the Workitem!**' | ConvertFrom-Markdown -AsVT100EncodedString).VT100EncodedString

            Connect-AzAccount 
            Write-Host -ForegroundColor Green "... Connected to Account '$((Get-AzContext).Account.Id)'"
        }
        $token = (Get-AzAccessToken -ResourceUrl '499b84ac-1321-427f-aa17-267ca6975798').Token   

        # Custom Request to aviod dependency on DevOpsScripts.DevOps
        $Request = @{
            Headers = @{            
                username       = 'O.o'          
                Authorization  = "Bearer $token"           
                'Content-Type' = 'application/x-www-form-urlencoded'      
            }   
            Uri     = "https://dev.azure.com/$Organization/$Project/_apis/wit/workitems/$workItemId`?api-version=7.0" -replace ' ', '%20'
            Method  = 'GET'
        }
  
        try {
            $workItem = Invoke-RestMethod @Request
            $workItem = Set-UtilsCache -Object $workItem -Type PimWorkItem -Identifier $workItemId -Alive 1440
            Write-Host -ForegroundColor Green "Found [$($workItem.fields.'System.WorkItemType')] '$workitemId' - $($workItem.fields.'System.Title')"
        }
        catch {
            Throw "... Workitem with ID '$workItemId' was not found!"
        }

    }

    Write-Host -ForegroundColor Green '... Workitem was validated successfully!'
    $null = Set-UtilsCache -Object $workItem -Type PimWorkitem -Identifier last -Alive 1440
  
    ############################################################
    ##################### Generate Reason ######################
    ############################################################

    $reason = "
    $justification

  - Reason:
    [$($workItem.fields.'System.WorkItemType') - $($($workItem.id))] $($workItem.fields.'System.Title')

  - WorkItem URL:
    $($workItem.url -replace '/_apis/wit/workItems/', '/_workitems/edit/' )
"

    if (!$noClipboard) {
        $null = Set-Clipboard -Value $reason

        Write-Host
        Write-Host -ForegroundColor Green 'PIM Message copied to Clipboard:'
        Write-Host -ForegroundColor Cyan $reason
        Write-Host
    } 
    else {
        return $reason
    }

}
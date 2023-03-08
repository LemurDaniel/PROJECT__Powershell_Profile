
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
        $noClipboard
    )

    Write-Host "`n"
    Write-Host -ForegroundColor Yellow ('**Checking branch for WorkItem Id**' | ConvertFrom-Markdown -AsVT100EncodedString).VT100EncodedString
    $currentBranchName = git branch --show-current
    if ($currentBranchName -match 'features/\d+-.*') {
        $workItemId = [regex]::Match(($currentBranchName -replace 'features/', ''), '^\d+').Value
        Write-Host -ForegroundColor Green "... Found Feature-Branch with workitem-Id: $workitemId"
    }
    else {
        Write-Host -ForegroundColor Red "`n... Your not on a Feature-Branch!`n"

        $lastItem = Get-UtilsCache -Type PimWorkItem -Identifier last
        if ($lastItem) {

            $pimWorkItemPollResult = Select-ConsoleMenu -Property display -Options @(
                @{ display = "Use Last Workitem: [$($lastItem.fields.'System.WorkItemType') - $($($lastItem.id))] $($lastItem.fields.'System.Title')"; option = 0 },
                @{ display = 'Enter new Workitem ID'; option = 1 }
            )

            if ($pimWorkItemPollResult.option -eq 0) {
                $workItemId = $lastItem.id
            }
            Write-Host
        }
  
        if (!$workItemId) {
            $workItemId = [regex]::Match((Read-Host -Prompt 'Please Enter a valid WorkItem ID'), '^\d+').Value
        }

    }


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
            Uri     = "https://dev.azure.com/baugruppe/625cb37d-7374-4306-b7e9-98f0ef6958a5/_apis/wit/workitems/$workItemId`?api-version=7.0"
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

    return $reason
}
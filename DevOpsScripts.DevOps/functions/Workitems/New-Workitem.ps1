<#
    .SYNOPSIS
    Creates a workitem with several fields.

    .DESCRIPTION
    Creates a worktime of a specific type, with several field an an optional parent.

    .INPUTS
    None. You cannot pipe objects into New-Workitem

    .OUTPUTS
    System.PSCustomObject A single created workitem.

    .EXAMPLE

    Create a User Story with a Title:

    PS> New-Workitem -Type 'User Story' -Title 'Document Powershell Module'

    .EXAMPLE

    Create a Task with a Title and a Parent Workitem:

    PS> $userStory = New-Workitem -Type 'User Story' -Title 'Document Powershell Module'
    PS> New-Workitem -Type Task -Title 'Document Powershell Module' -ParentId $userStory.id


    .LINK
        
#>

function New-Workitem {

    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        # Type of the new workitem.
        [Parameter(
            Position = 0
        )]
        [ValidateSet(
            'Epic',
            'Feature',
            'User Story',
            'Task',
            'Bug',
            'Issue'
        )]
        [System.String]
        $Type = 'User Story',

        # Title of the new Workitem
        [parameter(
            Position = 1,
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [System.String]
        $Title,

        # Description of the new Workitem.
        [Parameter()]
        [System.String]
        $Description = $null,

        # Iteration Path.
        [Parameter()]
        [ValidateScript(
            { 
                $_ -in (@('Backlog', 'Current') + (Get-SprintIterations).name)
            },
            ErrorMessage = 'Please specify the correct Iteration path.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = @('Backlog', 'Current') + ((Get-SprintIterations).name | Select-Object -Last 10)

                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $IterationPath = 'Backlog',

        # Optional Parent of newly created workitem.
        [Parameter()]
        [System.Int32]
        $ParentId,

        # Optional Id of a related workitem
        [Parameter()]
        [System.Int32]
        $RelatedId,

        # Optional use the image saved in the clipboard
        [Parameter()]
        [switch]
        $useImageFromClipboard,

        # Optional use the image saved in the clipboard
        [Parameter()]
        [switch]
        $openInBrowser
    )

    BEGIN {

        if ($IterationPath -ieq 'Backlog') {
            $sprintIteration = Get-ProjectInfo name
        }
        elseif ($IterationPath -ieq 'Current') {
            $sprintIteration = Get-SprintIterations -Current | Select-Object -ExpandProperty Path
        }
        else {
            $sprintIteration = Get-SprintIterations | Search -has $IterationPath | Select-Object -ExpandProperty Path
        }


        
        $DescriptionHtml = "
            <div>
            $Description
            {{IMAGE}}
            </div>
        " 
    
        if ($useImageFromClipboard -AND [System.Windows.Clipboard]::containsImage()) {
            $bitmapFrame = [System.Windows.Media.Imaging.BitmapFrame]::Create([System.Windows.Clipboard]::GetImage())
            $jpegEncoder = [System.Windows.Media.Imaging.JpegBitmapEncoder]::new()
            $jpegEncoder.Frames.add($bitmapFrame)
            $stream = [System.IO.MemoryStream]::new()
            $jpegEncoder.save($stream)
            $base64 = [System.Convert]::ToBase64String($stream.ToArray())
            $imageUrl = "data:image/jpg;base64,$base64"

            $DescriptionHtml = $DescriptionHtml -replace '{{IMAGE}}', "<img src=`"$imageUrl`" alt=`"Image`">"
        }
        else {
            $DescriptionHtml = $DescriptionHtml -replace '{{IMAGE}}', ''
        }

    }
    PROCESS {

        $Request = @{
            Method = 'POST'
            SCOPE  = 'PROJ'
            API    = "/_apis/wit/workitems/`$${Type}?api-version=7.0"
            Body   = @(
                @{
                    op    = 'add'
                    path  = '/fields/System.Title'
                    from  = $null
                    value = $Title
                },
                @{
                    op    = 'add'
                    path  = '/fields/System.TeamProject'
                    from  = $null
                    value = Get-ProjectInfo name
                },
                @{
                    op    = 'add'
                    path  = '/fields/System.AreaPath'
                    from  = $null
                    value = Get-ProjectInfo name
                },
                @{
                    op    = 'add'
                    path  = '/fields/System.Description'
                    from  = $null
                    value = $DescriptionHtml
                },
                @{
                    op    = 'add'
                    path  = '/fields/System.IterationPath'
                    from  = $null
                    value = $sprintIteration
                }
            )
        }

        if ($PSBoundParameters.ContainsKey('ParentId')) {
            $Request.Body += @{
                op    = 'add'
                path  = '/relations/-'
                value = @{
                    rel        = Get-WorkItemRelationTypes -RelationType Parent | Select-Object -ExpandProperty referenceName
                    url        = (Get-WorkItem -Id $ParentId).url
                    attributes = @{}
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('RelatedId')) {
            $Request.Body += @{
                op    = 'add'
                path  = '/relations/-'
                value = @{
                    rel        = Get-WorkItemRelationTypes -RelationType Related | Select-Object -ExpandProperty referenceName
                    url        = (Get-WorkItem -Id $RelatedId).url
                    attributes = @{}
                }
            }
        }

        if ($PSCmdlet.ShouldProcess("[$Type] - '$Title' in $IterationPath", 'Create')) {
            $workitem = Invoke-DevOpsRest @Request -ContentType 'application/json-patch+json' 

            if ($openInBrowser) {
                Start-Process ($workItem.url -replace '/_apis/wit/workItems/', '/_workitems/edit/')
            }

            return $workitem
        } 
    }
    END {}
}
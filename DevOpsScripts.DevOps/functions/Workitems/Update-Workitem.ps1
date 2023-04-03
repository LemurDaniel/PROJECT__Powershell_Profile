<#
    .SYNOPSIS
    Updates a workitem.

    .DESCRIPTION
    Updates a workitem.

    .INPUTS
    None. You cannot pipe objects into New-Workitem

    .OUTPUTS
    System.PSCustomObject A single created workitem.

    .EXAMPLE


    .EXAMPLE


    .LINK
        
#>

function Update-Workitem {

    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        # Title of the new Workitem. Will use workitem of current Branch if found.
        [parameter(
            Position = 0,
            Mandatory = $false,
            ValueFromPipeline = $true
        )]
        [System.int32]
        $Id,

        # The target state of the workitem.
        [Parameter()]
        [ValidateSet(
            'New',
            'Active',
            'Paused',
            'Resolved',
            'Closed',
            'Removed'
        )]
        [System.String]
        $State,

        # Optional Parent of the updated created workitem.
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

        if (!$PSBoundParameters.ContainsKey('Id')) {
            $repository = Get-RepositoryInfo
            $branch = git -C $repository.Localpath branch --show-current
            $workitemId = [regex]::Match($branch, 'features/\d+')
            $workitemId = [regex]::Match($workitemId, '\d+')

            if (!$workitemId.Success) {
                throw "Can't find associated workitem for branch '$branch'"
            }
            else {
                $workitemId = $workitemId.Value
            }
        }
      
        $DescriptionHtml = "
            <div>
            {{EXISTING}}
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

        $workitem = Get-WorkItem -Id $Id
        $Request = @{
            Method  = 'PATCH'
            SCOPE   = 'PROJ'
            API     = "/_apis/wit/workitems/$Id`?api-version=7.0"
            Body    = @()
            AsArray = $true
        }

        if ($PSBoundParameters.ContainsKey('State')) {
            $Request.Body += @{
                op    = 'add'
                path  = '/fields/System.State'
                value = $State
            }
        }

        if ($useImageFromClipboard -AND [System.Windows.Clipboard]::containsImage()) {
            $DescriptionHtml = "$($workitem.fields.'System.Description')$DescriptionHtml"
            $Request.Body += @{
                op    = 'add'
                path  = '/fields/System.Description'
                value = $DescriptionHtml
            }
        }

        if ($PSBoundParameters.ContainsKey('ParentId')) {
            $Request.Body += @{
                op    = 'add'
                path  = '/relations/-'
                value = @{
                    rel        = Get-WorkItemRelationTypes -RelationType Parent | Select-Object -ExpandProperty referenceName
                    url        = $workItem.url
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
                    url        = $workItem.url
                    attributes = @{}
                }
            }
        }
        $Request.Body
        if ($PSCmdlet.ShouldProcess("[$($workitem.fields.'System.WorkItemType')] - '$($workitem.fields.'System.Title')' in $($workitem.fields.'System.IterationPath')", 'Update')) {
            $workitem = Invoke-DevOpsRest @Request -ContentType 'application/json-patch+json' 

            if ($openInBrowser) {
                Start-Process ($workItem.url -replace '/_apis/wit/workItems/', '/_workitems/edit/')
            }

            return $workitem
        } 
    }
    END {}
}
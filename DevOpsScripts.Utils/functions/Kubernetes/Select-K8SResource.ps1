

<#
    .SYNOPSIS
    Filter return values from the function Get-K8SResources or Get-K8SClusterResources.

    .DESCRIPTION
    Filter return values from the function Get-K8SResources or Get-K8SClusterResources.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None

    .EXAMPLE

    Select a single Deployment with a certain name:

    PS> Read-K8SLogs <autcompleted_deployment> -Follow -Timestamps


    .EXAMPLE

     Follow logs with timestamps for the first pod in a deployment in another namespace:

    PS> Read-K8SLogs -n <autocompleted_namespace> <autcompleted_deployment> -Follow -Timestamps


    .LINK
        
#>


function Select-K8SResource {

    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [System.String]
        $apiVersion,

        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [System.String]
        $kind,

        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [System.Object]
        $metadata,

        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [System.Object]
        $spec,

        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [System.Object]
        $status,


        #
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [System.String]
        $Attribute,

        [Parameter(
            Mandatory = $true,
            Position = 1
        )]
        [ValidateSet('EQ', 'NE', 'LIKE')]
        [System.String]
        $Filter,

        [Parameter(
            Mandatory = $true,
            Position = 2
        )]
        [System.String]
        $Value
    )


    BEGIN {
        $Selection = @()
    }

    PROCESS {

        $resource = [PSCustomObject]@{
            apiVersion = $apiVersion
            kind       = $kind
            metadata   = $metadata
            spec       = $spec
            status     = $status
        }


        $attributeValue = $resource
        $Attribute -split '\.(?![^\[]*])' 
        | ForEach-Object {
            $attributeValue = $attributeValue | Select-Object -ExpandProperty $_
        } 

        switch ($Filter) {

            EQ { 
                if ($attributeValue -EQ $Value) {
                    $Selection += $resource
                }
            }
            NE { 
                if ($attributeValue -NE $Value) {
                    $Selection += $resource
                }
            }
            LIKE { 
                if ($attributeValue -LIKE $Value) {
                    $Selection += $resource
                }
            }
            Default {
                throw "Not supported"
            }
        }

    }

    END {
        return $Selection
    }
}
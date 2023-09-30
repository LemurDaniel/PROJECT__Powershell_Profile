


<#

.SYNOPSIS
    Get resource-options for the given provider resource of the azurerm_provider.
    Takes resources from the current set cluster and all namespaces except kubesystem.
    Used by New-TerraformAzureImportStatement.ps1
    Kubectl needs to be installed. 

.DESCRIPTION
    Get resource-options for the given provider resource of the azurerm_provider.
    Takes resources from the current set cluster and all namespaces except kubesystem.
    Used by New-TerraformAzureImportStatement.ps1
    Kubectl needs to be installed. 

.OUTPUTS
    A list of resource options of
    @{
        slug      = ""
        import_id = ""
        .
        .
        .
        other properties depending on type
    }

.EXAMPLE

    Get all resources for provider type 'kubernetes_deployment_v1':

    PS> Get-KubernetsResources -KubernetesResource 'kubernetes_deployment_v1' | Select-Object -Property slug, importId

.LINK
  
#>


function Get-KubernetsResources {

    param (
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [System.String]
        $KubernetesResource
    )

    $KubernetesResource = $KubernetesResource -replace 'kubernetes_|_v\d|_', ''
    $KubernetesResurceKind = Get-K8SResourceKind -Kind $KubernetesResource

    if ($KubernetesResurceKind.namespaced) {
        return Get-K8SResources -Kind $KubernetesResurceKind.kind -AllNamespaces
        | Select-K8SResource metadata.namespace NE kube-system
        | Select-Object -Property *, 
        @{
            Name       = "slug"; 
            Expression = { 
                @($_.metadata.namespace, $_.metadata.name) -join '/'
            }
        },
        @{
            Name       = "importId"; 
            Expression = {
                @($_.metadata.namespace, $_.metadata.name) -join '/'
            }
        }
    }
    else {
        return Get-K8SClusterResources -Kind $KubernetesResurceKind.kind
        | Select-Object -Property *, 
        @{
            Name       = "slug"; 
            Expression = { 
                @("cluster", $_.name) -join '/'
            }
        },
        @{
            Name       = "importId"; 
            Expression = { 
                $_.name
            }
        }
    }

}
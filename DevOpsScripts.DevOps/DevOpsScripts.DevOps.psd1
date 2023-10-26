#
# Module manifest for module 'DevOpsScripts.DevOps'
#
# Generated by: o.O
#
# Generated on: 10/26/2023
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'DevOpsScripts.DevOps.psm1'

# Version number of this module.
ModuleVersion = '1.0.1'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = 'df2da90c-0a5a-46be-9b3f-7e93f4dc86c9'

# Author of this module
Author = 'o.O'

# Company or vendor of this module
CompanyName = 'Unknown'

# Copyright statement for this module
Copyright = '(c) o.O. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Contains several function regarding the DevOps-API, managing repositories, workitmes, projects, etc.'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '7.2'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @('DevOpsScripts.Utils')

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = 'Invoke-DevOpsRest', 'New-AutomatedTag', 'Remove-AutomatedTags', 
               'Get-DevOpsPAT', 'Get-DevOpsPATList', 'New-DevOpsPAT', 
               'Revoke-DevOpsPAT', 'Save-DevOpsPAT', 'Update-DevOpsPAT', 
               'Add-QuickContext', 'Get-DevOpsContext', 'Get-OrganizationInfo', 
               'Get-ProjectInfo', 'Get-RepositoryInfo', 'Remove-QuickContext', 
               'Set-DevOpsContext', 'Show-DevOpsContext', 'Switch-Organization', 
               'Switch-Project', 'Switch-QuickContext', 'Add-SprintIncrement', 
               'Add-SprintMember', 'Add-SprintTeamDaysOff', 'Connect-Workitem', 
               'Get-SprintIterations', 'Get-Workitem', 'Get-WorkItemQueries', 
               'New-BranchFromWorkItem', 'New-SprintIteration', 'New-Workitem', 
               'Open-WorkItemInBrowser', 'Search-WorkItemInIteration', 
               'Select-Workitems', 'Update-Workitem', 'Get-BuildLogs', 'New-Pipeline', 
               'Open-BuildInBrowser', 'Start-Pipeline', 'Start-PipelineOnBranch', 
               'Start-PipelinesInOrder', 'Add-OrganizationPAT', 
               'Get-AzureDevOpsCache', 'Get-DevOpsOrganizationData', 
               'Get-DevOpsOrganizations', 'Get-DevOpsPipelines', 'Get-DevOpsUser', 
               'Get-OrganizationPAT', 'Get-QuickContexts', 
               'Get-WorkItemRelationTypes', 'Remove-OrganizationPAT', 
               'Set-AzureDevOpsCache', 'Get-DevOpsArtifactFeeds', 
               'Register-DevOpsFeedAsPSRepository', 
               'Edit-RepositoriesForRedeployment', 'Get-RecentSubmoduleTags', 
               'Get-RepositoryRefs', 'Invoke-ScriptInRepositories', 'New-FeaturePR', 
               'New-MasterPR', 'New-PullRequest', 'New-Repository', 
               'Open-DevOpsRepository', 'Open-DevOpsRepositoryInBrowser', 
               'Remove-MovedBlocksAllRepositories', 'Start-RepositoryImport', 
               'Update-ModuleSourcesAllRepositories', 'Update-ModuleSourcesInPath'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
# VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = 'Set-OrgContext', 'swo', 'Set-ProjectContext', 'swp', 'swc', 'gitW', 'vc', 
               'repoBrowser'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        # Tags = @()

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        # ProjectUri = ''

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}


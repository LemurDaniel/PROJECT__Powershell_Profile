

## Powershell Profile

Contains a few useful Functions for Calling DevOps-Api, Azure-Api, etc.

----

## Basic Steps:

Refers only to the DevOpsScripts-Module.

1. Install Azure Az-Module.
2. Install/Import DevOpsScripts-Module
3. Run Connect-AzAccount.
4. Set the correct DevOps Context
   1. Switch-Organization - Short 'swo'
   > PS> swo 'autocompleted_org_names' 'autocompleted_project_names'
   2. Project-Context can be switched in Organization with
   > PS> swp 'autocompltede_project_names'
5. All DevOps related functions should now use current context.
   1. Get-ProjectInfo get info of current Project 
   2. Get-RepositoryInfo gets info about a repository in the curren Project.
   3. Open-Repository automatically downloads and opens repository in VScode (if on path)

----


#### Started out as Personal-Project, now Group-Effort of Team-DevOps:
- Tim Krehan
- Nicoals Neunert
- Daniel Landau

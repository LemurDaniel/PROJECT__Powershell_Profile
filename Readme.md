

## Powershell Profile

Contains a few useful Functions for Calling DevOps-Api, Azure-Api, etc.

----

## Basic Steps:

Refers only to the Helper-Module.

1. Install Azure Az-Module.
2. Install/Import Helper-Module
3. Run Connect-AzAccount.
4. Set the correct DevOps Context
   1. Switch-Organization changes the current DevOps-Organiztaion-Context.
      1. Should provide a autcomplete list of all DevOps Organizations accessable via API by user logged in.
   2. Switch-Project: changes the current DevOps-Project-Context. 
      1. should provide a Autocomplete List of all Projects in Current Organization, accessable via API by user logged in.
5. All DevOps related functions should now use current context.
   1. Get-ProjectInfo get info of current Project 
   2. Get-RepositoryInfo gets info about a repository in the curren Project.
   3. Open-Repository automatically downloads and opens repository in VScode (if on path)

----


#### Started out as Personal-Project, now Group-Effort of Team-DevOps:
- Tim Krehan
- Nicoals Neunert
- Daniel Landau
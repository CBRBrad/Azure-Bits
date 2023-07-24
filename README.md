# Azure-Bits

This repository contains a variety of items related to Azure.

**PowerShell Scripts to collect all Azure Diagnostics settings for Azure Resources**
- Script cycles through all Subscriptions available to account, and checks every resource for Diagnostic Settings configuration.
- All configuration details are stored in an array ($DiagResults) as well as exported to a CSV in the current running directory.

  **Azure-Get-ResouctDiagnosticSettings.ps1** **-**
  - Results are returned with a new line for each and diagnostic setting.
  - If a resource has multiple diagnostic settings configured, there will be multiple rows for the resource.

  **Get-AzureResouceDiagnosticSettings-compressed.ps1** **-**
  - Results are returned with a single line for all resources.
  

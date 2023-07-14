# Azure-Bits

This repository contains a variety of items related to Azure.

**Azure-Get-ResouctDiagnosticSettings.ps1** **-** PowerShell Script to collect all Azure Diagnostics settings for Azure Resources
- Script cycles through all Subscriptions available to account, and checks every resource for Diagnostic Settings configuration.
- All configuration details are stored in an array ($DiagResults) as well as exported to a CSV in the current running directory.

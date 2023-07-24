<#
.SYNOPSIS
    Get all Azure Diagnostics settings for Azure Resources
.DESCRIPTION
    Script cycles through all Subscriptions available to account, and checks every resource for Diagnostic Settings configuration.
    All configuration details are stored in an array ($DiagResults) as well as exported to a CSV in the current running directory.
.NOTES
Original:    Ivan Dretvic | 2020-01-07 | https://ivan.dretvic.com/?p=1085
V2:          Brad McKenna | 12/8/2021
  Updates:
   - Removed where switch on AzureDiagnostics
   - Added If/Then to record data for all resources
   - Updated PowerShell Object for the array
     + Each Diagnostic Setting configuration will have a line (meaning resources may occupy multiple lines)
   - Updated Export-CSV command to include -NotypeInformation switch to aide the results appearance
   - Added Parameter and IF block for Subscription (All, Disabled or Enabled)
   - Added Clear Variable to prevent duplicate/inaccurate data

Required:
  Az Module - will attempt to install if Az Module not found
            - Module install requires Administrator permissions
#>

[CmdletBinding()]
param (
    [Parameter()]
    [ValidateSet ("All", "Enabled", "Disabled")]
    [String[]]
    $SubscriptionState
)

# Install Az if not Installed
If (!(Get-InstalledModule -name Az)) {
    Write-Host "Installing Az module from default repository"
    Install-Module -Name Az -AllowClobber
}

# Import Az module, if not imported & Connect to AzAccount
if (!(Get-module -Name Az)) {
    Write-Host "Importing Az"
    Import-Module -Name Az
    
    Write-Host "Connecting to Az"
    Connect-AzAccount
}
else {
    Write-Host "Connecting to Az"
    Connect-AzAccount    
}

# Get all Azure Subscriptions
if ($SubscriptionState -eq "All") {
    $Subs = Get-AzSubscription    
}
elseif ($SubscriptionState -eq "Enabled") {
    $Subs = Get-AzSubscription | Where-Object {$_.State -eq "Enabled"}
}
elseif ($SubscriptionState -eq "Disabled") {
    $Subs = Get-AzSubscription | Where-Object {$_.State -eq "Disabled"}
}
else {
    $Subs = Get-AzSubscription | Where-Object {$_.State -eq "Enabled"}
}

# Set array
$DiagResults = @()

# Set Delimiter character
$strDelimiter = '|'

# Loop through all Azure Subscriptions
foreach ($Sub in $Subs) {
    Set-AzContext $Sub.id | Out-Null
    Write-Host "Processing Subscription:" $($Sub).name

    # Get all Azure resources for current subscription
    $Resources = Get-AZResource #-ResourceType Microsoft.KeyVault/vaults - used for testing
   
    # Get all Azure resources which have Diagnostic settings enabled and configured
    foreach ($res in $Resources) {
        $resId = $res.ResourceId

        # Construct object for data
        $item = [PSCustomObject]@{
	        Subscription = ""
	        ResourceName = ""
	        ResourceId = ""
	        ResourceType = ""
	        ResourceGroup = ""
	        DiagnosticSettingsConfigured = ""
	        DiagnosticSettingsName = ""
	        StorageAccountName =  ""
	        EventHubName =  ""
	        WorkspaceName =  ""
	        Metrics = ""
	        Logs =  ""
	        DiagnosticSettingsId = ""
	        StorageAccountId =  ""
	        EventHubId =  ""
	        WorkspaceId = ""
        }		 
		# Update PSObject with Resource information
        $item.Subscription = $Sub.Name
        $item.ResourceName = $res.name
		$item.ResourceId = $resId
		$item.ResourceType = $res.resourcetype
		$item.ResourceGroup = $res.resourcegroupname
		
        $DiagSettings = Get-AzDiagnosticSetting -ResourceId $resId -WarningAction SilentlyContinue -ErrorAction SilentlyContinue #| Where-Object { $_.Id -ne $null } - we want all objects for this script
        if ($DiagSettings) {
            foreach ($diag in $DiagSettings) {
                If ($diag.StorageAccountId) {
                    [string]$StorageAccountId= $diag.StorageAccountId
                    [string]$storageAccountName = $StorageAccountId.Split('/')[-1]
                }
                If ($diag.EventHubAuthorizationRuleId) {
                    [string]$EventHubId = $diag.EventHubAuthorizationRuleId
                    [string]$EventHubName = $EventHubId.Split('/')[-3]
                }
                If ($diag.WorkspaceId) {
                    [string]$WorkspaceId = $diag.WorkspaceId
                    [string]$WorkspaceName = $WorkspaceId.Split('/')[-1]
                }
				
				# Update PSObject with Diagnostic results for resource
					$item.DiagnosticSettingsConfigured = "True"
					if ($item.DiagnosticSettingsName -eq '') {$item.DiagnosticSettingsName = $diag.name} else {$item.DiagnosticSettingsName += $strDelimiter + $diag.name}
					if ($item.StorageAccountName -eq '') {$item.StorageAccountName = $StorageAccountNamee} else {$item.StorageAccountName += $strDelimiter + $StorageAccountName}
					if ($item.EventHubName -eq '') {$item.EventHubName = $EventHubName} else {$item.EventHubName += $strDelimiter + $EventHubName}
					if ($item.WorkspaceName -eq '') {$item.WorkspaceName = $WorkspaceName} else {$item.WorkspaceName += $strDelimiter + $WorkspaceName}
					# Extracting delatied porerties into string format.
					if ($item.Metrics -eq '') {$item.Metrics = ($diag.Metrics | ConvertTo-Json -Compress | Out-String).Trim()} else {$item.Metrics += $strDelimiter + ($diag.Metrics | ConvertTo-Json -Compress | Out-String).Trim()}
					if ($item.Logs -eq '') {$item.Logs = ($diag.Logs | ConvertTo-Json -Compress | Out-String).Trim()} else {$item.Logs += $strDelimiter + ($diag.Logs | ConvertTo-Json -Compress | Out-String).Trim()}
					if ($item.DiagnosticSettingsId -eq '') {$item.DiagnosticSettingsId = $diag.Id} else {$item.DiagnosticSettingsId += $strDelimiter + $diag.Id}
					if ($item.StorageAccountId -eq '') {$item.StorageAccountId = $StorageAccountId} else {$item.StorageAccountId += $strDelimiter + $StorageAccountId}
					if ($item.EventHubId -eq '') {$item.EventHubId = $EventHubId} else {$item.EventHubId += $strDelimiter + $EventHubId}
					if ($item.WorkspaceId -eq '') {$item.WorkspaceId = $WorkspaceId} else {$item.WorkspaceId += $strDelimiter + $WorkspaceId}

                # Clear Variables
                Clear-Variable -Name StorageAccountId,StorageAccountName,EventHubId,EventHubName,WorkspaceId,WorkspaceName,DiagnosticSettingsConfigured  -ErrorAction Ignore
            }
        }
        else {
            # Store all results for resource in PS Object
			$item.DiagnosticSettingsConfigured += "False"
            
            # Clear Variable
            Clear-Variable -Name DiagnosticSettingsConfigured -ErrorAction Ignore
        }
        # Write-Host $item
        Write-Host "Processed:" $($res).name

        $DiagResults += $item
    }
    
}
# Save Diagnostic settings to CSV as tabular data
$DiagResults | Export-Csv -Force -Path ".\AzureResourceDiagnosticSettings-$(get-date -f yyyy-MM-dd-HHmm).csv" -NoTypeInformation
Write-Host 'The array $DiagResults can be used to further refine results within session.'
Write-Host 'eg. $DiagResults | Where-Object {$_.WorkspaceName -like "LAW-LOGS01"}'
<#
.SYNOPSIS
Enabling AMSI body scanning for individual protocols.

.DESCRIPTION
This script creates an override for three protocols (ECP, EWS, and OWA) that enables AMSI body scanning.

.OUTPUT
AMSI body scanning is enabled on the server for ECP, EWS, and OWA.

.NOTES
Optionally modify the Name and Reason parameters.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll (ISBN: 9798262871872)
#>

# Create the override for ECP
New-SettingOverride -Name "EnableAMSIBodyScanForEcp" -Component Cafe -Section AmsiRequestBodyScanning -Parameters ("EnabledEcp=True") -Reason "AMSI body scanning ECP"

# Create the override for EWS
New-SettingOverride -Name "EnableAMSIBodyScanForEws" -Component Cafe -Section AmsiRequestBodyScanning -Parameters ("EnabledEws=True") -Reason "AMSI body scanning EWS"

# Create the override for OWA
New-SettingOverride -Name "EnableAMSIBodyScanForOwa" -Component Cafe -Section AmsiRequestBodyScanning -Parameters ("EnabledOwa=True") -Reason "AMSI body scanning OWA"

# Enable the override
Get-ExchangeDiagnosticInfo -Process Microsoft.Exchange.Directory.TopologyService -Component VariantConfiguration -Argument Refresh

# Restart services
Restart-Service -Name W3SVC, WAS -Force
<#
.SYNOPSIS
Configuring AMSI body scanning size.

.DESCRIPTION
This script creates an override that configures AMSI body scanning with the number of bytes to scan.

.OUTPUT
AMSI body scanning is configured to scan a maximum of 8192 bytes.

.NOTES
The maximum value is 1048576 bytes (1 MB). Replace 8192 with the size you want to use.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is excerpted from the book "Microsoft Exchange Server Subscription Edition for Admins" by Scott Schnoll
#>

# Create the override
New-SettingOverride -Name "ConfigureCustomAMSIBodyScanSize" -Component Cafe -Section AmsiRequestBodyScanning -Parameters ("BodyScanSizeInBytes=8192") -Reason "Adjusting AMSI body Scan size to 8192 bytes"

# Enable the override
Get-ExchangeDiagnosticInfo -Process Microsoft.Exchange.Directory.TopologyService -Component VariantConfiguration -Argument Refresh

# Restart services
Restart-Service -Name W3SVC, WAS -Force
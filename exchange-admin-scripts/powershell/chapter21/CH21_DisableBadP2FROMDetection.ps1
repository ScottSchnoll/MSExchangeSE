<#
.SYNOPSIS
Disabling the Non-RFC compliant P2 FROM headers feature.

.DESCRIPTION
This script disables the malicious P2 FROM header detection feature, including disabling the header and disclaimer.

.OUTPUT
Non-RFC compliant P2 FROM headers detection and disclaimer behaviors are disabled.

.NOTES
Replace the values below with those appropriate for your organization.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll (ISBN: 9798262871872)
#>

New-SettingOverride -Name "DisableP2FromDisclaimer" -Component "Transport" -Section "NonCompliantSenderSettings" -Parameters @("AddDisclaimerforRegexMatch=false") -Reason "Disable disclaimer auto-prepend"
New-SettingOverride -Name "DisableP2FromHeader" -Component "Transport" -Section "NonCompliantSenderSettings" -Parameters @("AddP2FromRegexMatchHeader=false") -Reason "Disable header auto-add"
Get-ExchangeDiagnosticInfo -Process Microsoft.Exchange.Directory.TopologyService -Component VariantConfiguration -Argument Refresh
Restart-Service -Name MSExchangeTransport
<#
.SYNOPSIS
Enabling certificate signing of PowerShell serialization payloads.

.DESCRIPTION
This script creates an override that enables certificate signing of PowerShell serialization payloads.

.OUTPUT
Exchange uses its internal Auth Certificate to cryptographically sign the serialized data before transmission. On the receiving end, the signature is verified to ensure the payload hasn't been altered. This mechanism adds integrity validation to the serialization process, making it significantly harder for attackers to exploit vulnerabilities in EMS communications.

.NOTES
Optionally modify the override Name and Reason, as desired.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll (ISBN: 9798262871872)
#>

New-SettingOverride -Name "EnablePSSigningVerification" -Component Data -Section EnableSerializationDataSigning -Parameters @("Enabled=true") -Reason "Enable Certificate Signing Verification"
Get-ExchangeDiagnosticInfo -Process Microsoft.Exchange.Directory.TopologyService -Component VariantConfiguration -Argument Refresh
Restart-Service -Name W3SVC, WAS -Force
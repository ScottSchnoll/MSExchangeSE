<#
.SYNOPSIS
Recreating missing system or arbitration mailboxes after re-running Setup.exe /PrepareAD.

.DESCRIPTION
This script enables and configure the SystemMailbox{2CE34405-31BE-455D-89D7-A7C7DA7A0DAA}, which contains relevancy features for databases that help Exchange rank and prioritize content for features like search and eDiscovery, supports internal mechanisms that improve relevance scoring across distributed databases, and plays a role in content indexing and retrieval, especially in large environments.

.OUTPUT
SystemMailbox{2CE34405-31BE-455D-89D7-A7C7DA7A0DAA} is enabled and configured with the ShardRelevancyFeatureStore organization capability.

.NOTES


.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll (ISBN: 9798262871872)
#>

# Enable the arbitration mailbox
Enable-Mailbox -Identity "SystemMailbox{2CE34405-31BE-455D-89D7-A7C7DA7A0DAA}" -Arbitration

# Configure mailbox properties
Set-Mailbox -Identity "SystemMailbox{2CE34405-31BE-455D-89D7-A7C7DA7A0DAA}" -Arbitration -DisplayName "Microsoft Exchange" -RequireSenderAuthenticationEnabled $false -UseDatabaseQuotaDefaults $false -SCLDeleteEnabled $false -SCLJunkEnabled $false -SCLQuarantineEnabled $false -SCLRejectEnabled $false -HiddenFromAddressListsEnabled $true -Force

# Retrieve mailbox object and SamAccountName
$SysMBX = Get-Mailbox -Identity "SystemMailbox{2CE34405-31BE-455D-89D7-A7C7DA7A0DAA}" -Arbitration
$SysMBX_Sam = $SysMBX.SamAccountName

# Set AD user attributes including capability and hygiene thresholds
Set-ADUser -Identity $SysMBX_Sam -Add @{ "msExchCapabilityIdentifiers" = "66" }
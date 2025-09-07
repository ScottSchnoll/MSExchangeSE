<#
.SYNOPSIS
Recreating missing system or arbitration mailboxes after re-running Setup.exe /PrepareAD.

.DESCRIPTION
This script enables and configure the SystemMailbox{bb558c35-97f1-4cb9-8ff7d53741dc928c}, which is used for creating OABs, generating group metrics, message tracking, grammar checking in UM, and PST provider services. Also referred to as the Microsoft Exchange Client Extensions or organization mailbox.

.OUTPUT
SystemMailbox{bb558c35-97f1-4cb9-8ff7d53741dc928c} is enabled and configured with the appropriate capabilities.

.NOTES
For the msExchCapabilityIdentifiers, "40" = OABGen, "42" = ClientExtensions, "43" = MessageTracking, "44" = PstProvider, "47" = GMGen, and "46" = MailRouting. If your environment doesn’t have UM, you should exclude "51" (UMGrammar) and "52" (UMGrammarReady) from the msExchCapabilityIdentifiers parameter value.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is excerpted from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll
#>

Enable-Mailbox -Identity "SystemMailbox{bb558c35-97f1-4cb9-8ff7d53741dc928c}" -Arbitration
Get-Mailbox "SystemMailbox{bb558c35-97f1-4cb9-8ff7-d53741dc928c}" -Arbitration | Set-Mailbox -Arbitration -UMGrammar $true -OABGen $true -GMGen $true -ClientExtensions $true -MessageTracking $true -PstProvider $true -MaxSendSize 1GB -Force
$OABMBX_Sam = (Get-Mailbox "SystemMailbox{bb558c35-97f1-4cb9-8ff7d53741dc928c}" -Arbitration).SamAccountName
if ($OABMBX_Sam) {
  Set-ADUser -Identity $OABMBX_Sam -Add @{
    "msExchCapabilityIdentifiers" = @("40","42","43","44","47","51","52","46") } }
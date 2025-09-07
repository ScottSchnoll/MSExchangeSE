<#
.SYNOPSIS
Determine if disconnected mailboxes exist and if they are in a disabled or soft-deleted state.

.DESCRIPTION
This script retrieves all disconnected mailboxes in the organization and the reason for disconnection.

.OUTPUT
List of disconnected mailboxes that includes the display name, GUID, database, and the type of disconnected mailbox.

.NOTES
The value of DisconnectReason will be either Disabled or SoftDeleted.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is excerpted from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll
#>

$dbs = Get-MailboxDatabase 
$dbs | foreach {Get-MailboxStatistics -Database $_.DistinguishedName} | where {$_.DisconnectReason -ne $null} | FL DisplayName,MailboxGuid,Database,DisconnectReason
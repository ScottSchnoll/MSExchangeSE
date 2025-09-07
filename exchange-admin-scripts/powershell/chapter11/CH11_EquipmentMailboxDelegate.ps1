<#
.SYNOPSIS
This script is used for equipment mailbox management.

.DESCRIPTION
This script finds all equipment mailboxes in the AV department and configures them to send booking requests to a delegate.

.OUTPUT
All equipment mailboxes with Audio-Visual in their Department parameter are configured to send booking requests to Robert Taylor.

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

Get-Recipient -RecipientTypeDetails EquipmentMailbox | Where-Object { $_.Department -eq "Audio-Visual" } | ForEach-Object { Set-CalendarProcessing -Identity $_.Alias -AllBookInPolicy $false -AllRequestInPolicy $true -ResourceDelegates "Robert Taylor" }
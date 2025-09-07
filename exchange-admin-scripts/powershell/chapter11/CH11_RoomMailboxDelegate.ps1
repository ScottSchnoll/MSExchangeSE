<#
.SYNOPSIS
This script is used for room mailbox management.

.DESCRIPTION
This script finds all room mailboxes that are private conference rooms and configures them to send booking requests to a delegate.

.OUTPUT
All room mailboxes with Private in their DisplayName parameter are configured to send booking requests to Robert McMichael.

.NOTES
Replace the values below with those appropriate for your organization.

.AUTHOR
Scott Schnoll

.COPYRIGHT
# Copyright © 2025 Scott Schnoll. All Rights Reserved.
# This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.
#
# .SOURCE
This script is excerpted from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll
#>

Get-Mailbox -ResultSize unlimited -Filter "(RecipientTypeDetails -eq 'RoomMailbox') -and (DisplayName -like 'Private*')" | ForEach-Object { Set-CalendarProcessing -Identity $_.PrimarySmtpAddress -AllBookInPolicy $false -AllRequestInPolicy $true -ResourceDelegates "Robert McMichael" }
<#
.SYNOPSIS
This script is used for equipment room mailbox management.

.DESCRIPTION
This script configures equipment mailboxes to allow booking requests to be scheduled only during working hours.

.OUTPUT
All equipment mailboxes are configured to accept booking requests only during working hours.

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

Get-Mailbox -ResultSize unlimited -Filter "RecipientTypeDetails -eq 'EquipmentMailbox'" | ForEach-Object { Set-CalendarProcessing -Identity $_.PrimarySmtpAddress.ToString() -ScheduleOnlyDuringWorkHours $true }
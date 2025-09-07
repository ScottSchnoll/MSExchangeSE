<#
.SYNOPSIS
This script is part 4 of a 4-part series of scripts that create a 4-member DAG extended across two sites.

.DESCRIPTION
This script creates HA copies of DB4 on EX1 and EX3, and a 3-day lagged copy on EX2 that is seeded from EX1. It also suspends the copy of DB4 on EX2 from activation.

.OUTPUT
HA copies of DB4 are created on EX1 and EX3, and a lagged copy with a 3-day lag is created on EX2 by seeding it from EX1. Database copy DB4\EX2 is suspended for activation.

.NOTES
When using this script, be sure you use your database and server names, and choose the lagged copy settings that are appropriate for your organization.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is excerpted from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll
#>

Add-MailboxDatabaseCopy -Identity DB4 -MailboxServer EX1
Add-MailboxDatabaseCopy -Identity DB4 -MailboxServer EX3
Add-MailboxDatabaseCopy -Identity DB4 -MailboxServer EX2 -ReplayLagTime 3.00:00:00 -SeedingPostponed
Suspend-MailboxDatabaseCopy -Identity DB4\EX2 -SuspendComment "Seed from EX1" -Confirm:$false 
Update-MailboxDatabaseCopy -Identity DB4\EX2 -SourceServer EX1 
Suspend-MailboxDatabaseCopy -Identity DB4\EX2 -ActivationOnly
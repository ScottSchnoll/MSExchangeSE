<#
.SYNOPSIS
This script is part 3 of a 4-part series of scripts that create a 4-member DAG extended across two sites.

.DESCRIPTION
This script creates HA copies of DB3 on EX2 and EX4, and a 3-day lagged copy on EX1 that is seeded from EX2. It also suspends the copy of DB3 on EX1 from activation.

.OUTPUT
HA copies of DB3 are created on EX2 and EX4, and a lagged copy with a 3-day lag is created on EX1 by seeding it from EX2. Database copy DB3\EX1 is suspended for activation.

.NOTES
When using this script, be sure you use your database and server names, and choose the lagged copy settings that are appropriate for your organization.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll (ISBN: 9798262871872)
#>

Add-MailboxDatabaseCopy -Identity DB3 -MailboxServer EX2 
Add-MailboxDatabaseCopy -Identity DB3 -MailboxServer EX4 
Add-MailboxDatabaseCopy -Identity DB3 -MailboxServer EX1 -ReplayLagTime 3.00:00:00 -SeedingPostponed
Suspend-MailboxDatabaseCopy -Identity DB3\EX1 -SuspendComment "Seeding" -Confirm:$false 
Update-MailboxDatabaseCopy -Identity DB3\EX1 -SourceServer EX2 
Suspend-MailboxDatabaseCopy -Identity DB3\EX1 -ActivationOnly

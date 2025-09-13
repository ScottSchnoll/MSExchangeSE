<#
.SYNOPSIS
This script is part 1 of a 4-part series of scripts that create a 4-member DAG extended across two sites.

.DESCRIPTION
This script creates HA copies of DB1 on EX2 and EX4, and a 3-day lagged copy on EX3 that is seeded from EX4. It also suspends the copy of DB1 on EX3 from activation.

.OUTPUT
HA copies of DB1 are created on EX2 and EX4, and a lagged copy with a 3-day lag is created on EX3 by seeding it from EX4. Database copy DB1\EX3 is suspended for activation.

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

Add-MailboxDatabaseCopy -Identity DB1 -MailboxServer EX2 
Add-MailboxDatabaseCopy -Identity DB1 -MailboxServer EX4 
Add-MailboxDatabaseCopy -Identity DB1 -MailboxServer EX3 -ReplayLagTime 3.00:00:00 -SeedingPostponed 
Suspend-MailboxDatabaseCopy -Identity DB1\EX3 -SuspendComment "Seeding" -Confirm:$false 
Update-MailboxDatabaseCopy -Identity DB1\EX3 -SourceServer EX4 
Suspend-MailboxDatabaseCopy -Identity DB1\EX3 -ActivationOnly

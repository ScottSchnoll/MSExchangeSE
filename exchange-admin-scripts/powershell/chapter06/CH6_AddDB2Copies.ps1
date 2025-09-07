<#
.SYNOPSIS
This script is part 2 of a 4-part series of scripts that create a 4-member DAG extended across two sites.

.DESCRIPTION
This script creates HA copies of DB2 on EX1 and EX3, and a 3-day lagged copy on EX4 that is seeded from EX3. It also suspends the copy of DB2 on EX4 from activation.


.OUTPUT
HA copies of DB2 are created on EX1 and EX3, and a lagged copy with a 3-day lag is created on EX4 by seeding it from EX3. Database copy DB2\EX4 is suspended for activation.

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

Add-MailboxDatabaseCopy -Identity DB2 -MailboxServer EX1
Add-MailboxDatabaseCopy -Identity DB2 -MailboxServer EX3
Add-MailboxDatabaseCopy -Identity DB2 -MailboxServer EX4 -ReplayLagTime 3.00:00:00 -SeedingPostponed
Suspend-MailboxDatabaseCopy -Identity DB2\EX4 -SuspendComment "Seeding" -Confirm:$false 
Update-MailboxDatabaseCopy -Identity DB2\EX4 -SourceServer EX3 
Suspend-MailboxDatabaseCopy -Identity DB2\EX4 -ActivationOnly

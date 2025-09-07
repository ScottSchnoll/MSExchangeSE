<#
.SYNOPSIS
This example script illustrates how to create a DAG with a cluster administrative access point (AAP).

.DESCRIPTION
This script creates a DAG with a cluster AAP.

.OUTPUT
A DAG named DAG1 with a cluster AAP that contains 3 members (EX1, EX2, and EX3), and uses EX4 as its witness server.

.NOTES
When using this script, be sure you use DAG, member and witness server names that are appropriate for your organization.

.AUTHOR
Scott Schnoll

.COPYRIGHT
# Copyright © 2025 Scott Schnoll. All Rights Reserved.
# This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.
#
# .SOURCE
This script is excerpted from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll
#>

New-DatabaseAvailabilityGroup -Name DAG1 -WitnessServer EX4 -DatabaseAvailabilityGroupIPAddresses 10.0.0.5,192.168.0.5
Add-DatabaseAvailabilityGroupServer -Identity DAG1 -MailboxServer EX1
Add-DatabaseAvailabilityGroupServer -Identity DAG1 -MailboxServer EX2
Add-DatabaseAvailabilityGroupServer -Identity DAG1 -MailboxServer EX3


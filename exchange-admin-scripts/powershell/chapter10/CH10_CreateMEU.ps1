<#
.SYNOPSIS
Creating a mail-enabled user in Exchange Server SE.

.DESCRIPTION
This script creates a mail-enabled user with a preset password in the default user OU.

.OUTPUT
An external user is added as a mail-enabled user in AD and assigned the UPN of rhiranaka@nwnetworks.com and an initial password of P@ssw0rd!.

.NOTES
Replace the values below with values in your organization.

.AUTHOR
Scott Schnoll

.COPYRIGHT
# Copyright © 2025 Scott Schnoll. All Rights Reserved.
# This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.
#
# .SOURCE
This script is excerpted from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll
#>

New-MailUser -Name "Ross Hiranaka" -Alias "rossh" -ExternalEmailAddress "rossh@msexchangese.com" -FirstName "Ross" -LastName "Hiranaka" -UserPrincipalName "rhiranaka@nwnetworks.com" -Password (ConvertTo-SecureString -String 'P@ssw0rd!' -AsPlainText -Force)
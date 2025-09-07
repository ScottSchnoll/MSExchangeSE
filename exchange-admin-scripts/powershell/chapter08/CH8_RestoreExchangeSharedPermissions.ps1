<#
.SYNOPSIS
To switch from AD split permissions to Exchange shared permissions, you must re-run Setup to disable AD split permissions and then create role assignments between a role group and the Mail Recipient Creation role and Security Group Creation and Membership role, and then restart all Exchange servers in your organization.

.DESCRIPTION
This script adds regular role assignments between the Mail Recipient Creation role and Security Group Creation and Management role and the Organization Management and Recipient Management role groups.

.OUTPUT
The Exchange shared permissions role assignments are restored.

.NOTES
Only use this when changing from AD split permissions to Exchange shared permissions.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is excerpted from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll
#>

# Assign Mail Recipient Creation role to the Organization Management group
New-ManagementRoleAssignment "Mail Recipient Creation_Organization Management" -Role "Mail Recipient Creation" -SecurityGroup "Organization Management"

# Assign SG creation role to the Organization Management group
New-ManagementRoleAssignment "Security Group Creation and Membership_Org Management" -Role "Security Group Creation and Membership" -SecurityGroup "Organization Management"

# Assign Mail Recipient Creation role to the Recipient Management group
New-ManagementRoleAssignment "Mail Recipient Creation_Recipient Management" -Role "Mail Recipient Creation" -SecurityGroup "Recipient Management"
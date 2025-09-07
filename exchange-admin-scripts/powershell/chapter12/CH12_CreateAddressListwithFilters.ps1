<#
.SYNOPSIS
This script demonstrates the creation of address lists based on filtered properties.

.DESCRIPTION
This script creates an address list named Northwest Executives under the North America address list with a custom recipient filter that looks for Directors or Managers in WA, OR, or ID (Washington, Oregon, or Idaho).

.OUTPUT
An address list named Northwest Executives is created under the North America address list that contains only those mailbox users who have Director or Manager in their Title and are in Washington, Oregon, and Idaho.

.NOTES
Replace the values below with those appropriate for your organization.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is excerpted from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll
#>

$Titles = @("*Director*", "*Manager*")
$States = @("WA", "OR", "ID")
$Filter = "(RecipientType -eq 'UserMailbox') -and (" +
     ($Titles | ForEach-Object { "Title -like '$_'" }) -join " -or " + ") -and (" +
     ($States | ForEach-Object { "StateOrProvince -eq '$_'" }) -join " -or " + ")"
New-AddressList -Name "Northwest Executives" -Container "\North America" 
-RecipientFilter $Filter
<#
.SYNOPSIS
Implementing IRM in your Exchange Server SE environment.

.DESCRIPTION
This script automates most of the steps needed for Exchange and uses Test-IRMConfiguration end-to-end for issues related to missing or invalid TPDs, incorrect permissions on IRM endpoints, licensing service availability, etc.

.OUTPUT
IRM is configured and verified in the environment.

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

# Variables
$TPDPath = "C:\TPD\ExportedTPD.xml"
$SuperUserGroup = "ADRMS_SuperUsers"
$FederationMailbox = "FederatedEmail.4c1f4d8b-8179-4148-93bf-00a95fa1e042"
$TPDName = "AD RMS TPD"
$LicensingUrl = "https://adrms.msexchangese.com/_wmcs/licensing"

# Add Federation Mailbox to Super Users group
Add-DistributionGroupMember -Identity $SuperUserGroup -Member $FederationMailbox

# Import Trusted Publishing Domain
Import-RMSTrustedPublishingDomain -FileData ([System.IO.File]::ReadAllBytes($TPDPath)) -Name $TPDName -IntranetLicensingUrl $LicensingUrl -ExtranetLicensingUrl $LicensingUrl

# Enable IRM Configuration settings
Set-IRMConfiguration -InternalLicensingEnabled $true
Set-IRMConfiguration -ClientAccessServerEnabled $true
Set-IRMConfiguration -JournalReportDecryptionEnabled $true
Set-IRMConfiguration -TransportDecryptionSetting Mandatory
Set-IRMConfiguration -SearchEnabled $true

# Verify IRM Configuration
Test-IRMConfiguration | FL

# Optional: Show IRM Configuration for review
Get-IRMConfiguration | FL
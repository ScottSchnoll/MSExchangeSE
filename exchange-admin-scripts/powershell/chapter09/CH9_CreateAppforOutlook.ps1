<#
.SYNOPSIS
This script is used when deploying modern authentication using AD FS.

.DESCRIPTION
This script creates an application in AD FS for Outlook.

.OUTPUT
An AD FS client application for Outlook is created.

.NOTES


.AUTHOR
Scott Schnoll

.COPYRIGHT
# Copyright © 2025 Scott Schnoll. All Rights Reserved.
# This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.
#
# .SOURCE
This script is excerpted from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll
#>

Add-AdfsNativeClientApplication -Name "Outlook-Native application" -ApplicationGroupIdentifier "Outlook" -Identifier "d3590ed6-52b3-4102-aeffaad2292ab01c" -RedirectUri @("ms-appxweb://Microsoft.AAD.BrokerPlugin/d3590ed6-52b3-4102-aeffaad2292ab01c","msauth.com.microsoft.Outlook://auth","urn:ietf:wg:oauth:2.0:oob")
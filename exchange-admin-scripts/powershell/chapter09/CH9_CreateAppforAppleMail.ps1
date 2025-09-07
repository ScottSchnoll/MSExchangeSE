<#
.SYNOPSIS
This script is used when deploying modern authentication using AD FS.

.DESCRIPTION
This script creates an application in AD FS for the native mail application on iOS and MacOS.

.OUTPUT
An AD FS client application for the native mail application on iOS and MacOS is created.

.NOTES


.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll (ISBN: 9798262871872)
#>

Add-AdfsNativeClientApplication -Name "iOS and macOS-Native mail application" -ApplicationGroupIdentifier "Outlook" -Identifier "f8d98a960999-43f5-8af3-69971c7bb423" -RedirectUri @("com.apple.mobilemail://oauthredirect","com.apple.preferences.internetaccounts://oauthredirect/","com.apple.Preferences://oauth-redirect/")
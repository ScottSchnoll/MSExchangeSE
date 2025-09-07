<#
.SYNOPSIS
Applying message tracking settings from one server to another.

.DESCRIPTION
This script collects message tracking settings on one server and applies those settings to another.

.OUTPUT
EX2 is configured with the same message tracking settings as EX1.

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

$settings = Get-TransportService EX1 | Select-Object MessageTrackingLogEnabled, MessageTrackingLogPath, MessageTrackingLogMaxAge, MessageTrackingLogMaxDirectorySize, MessageTrackingLogMaxFileSize
Set-TransportService EX2 -MessageTrackingLogEnabled $settings.MessageTrackingLogEnabled -MessageTrackingLogPath $settings.MessageTrackingLogPath -MessageTrackingLogMaxAge $settings.MessageTrackingLogMaxAge -MessageTrackingLogMaxDirectorySize $settings.MessageTrackingLogMaxDirectorySize -MessageTrackingLogMaxFileSize $settings.MessageTrackingLogMaxFileSize
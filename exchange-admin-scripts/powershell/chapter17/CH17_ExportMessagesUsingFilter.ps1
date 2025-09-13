<#
.SYNOPSIS
Exporting specific messages from all queues on a server to individual files that use the InternetMessageID for the filename.

.DESCRIPTION
This script suspends all queues on the server, suspends all messages in the queues from senders in the specified domain, and exports copies of messages from that domain to the specified folder.

.OUTPUT
Messages that match the specified filter conditions are exported to the specified folder and use InternetMessageID for their filename.

.NOTES
Replace the values below with those appropriate for your organization.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll (ISBN: 9798262871872)
#>

# Suspend the queue
Suspend-Queue -Server <Server>

# Set your filter and export folder
$filter = '<MessageFilter>' 		# e.g., "FromAddress -eq '*@msexchangese.com'"
$exportFolder = '<FolderName>'   	# Pre-created folder, e.g., C:\Exports

# Fetch messages
Get-Message -Filter $filter -ResultSize unlimited | ForEach-Object {

# Strip angle brackets from InternetMessageID
$msgId = $_.InternetMessageId.TrimStart('<').TrimEnd('>')

# Replace any invalid filename chars
$safeId = [IO.Path]::GetInvalidFileNameChars() | ForEach-Object { $msgId = $msgId -replace [regex]::Escape($_), '_' }
$filePath = Join-Path $exportFolder ("$safeId.eml")

# Export and assemble
Export-Message -Identity $_.Identity | AssembleMessage -Path $filePath }
<#
.SYNOPSIS
Exporting messages from a queue.

.DESCRIPTION
This script exports all messages in a queue using the InternetMessageID for each message as the exported file name.

.OUTPUT
Messages from the specified queue are exported to individual files in the OutputFolder using the InternetMessageID as the file name.

.NOTES
Optionally replace the value of $OutputFolder below, and replace QueueName with the name of your queue.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is excerpted from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll
#>

# Define the folder where you want the .eml files to land
$OutputFolder = 'C:\Email\'

# Create the folder if it doesn’t exist
if (-not (Test-Path $OutputFolder)) { New-Item -Path $OutputFolder -ItemType Directory | Out-Null }

# Suspend the queue
Suspend-Queue <QueueName> -Confirm:$false

# Process each message in the queue and remove invalid filename chars (including <, >, :, ", /, \, |, ?, *, etc.)
Get-Message -Queue <QueueName> -ResultSize unlimited | ForEach-Object { $safeId = $_.InternetMessageID -replace '[\<\>:"\/\\\|\?\*]', ''

# Build the full file path
$filePath = Join-Path -Path $OutputFolder -ChildPath "$safeId.eml"

# Export the message and assemble into .eml
Export-Message -Identity $_.Identity | AssembleMessage -Path $filePath }
<#
.SYNOPSIS
Exporting all messages from all queues on a server to individual files that use the InternetMessageID for the filename.

.DESCRIPTION
This script exports all messages from all queues on a server using the InternetMessageID for their filename.

.OUTPUT
All messages in all queues on the specified server are exported to the specified ExportRoot.

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

# Set your server and export root folder
$Server = '<Server>'
$ExportRoot = '<Path>'

# Ensure output folder exists
if (!(Test-Path $ExportRoot)) { New-Item -Path $ExportRoot -ItemType Directory | Out-Null }

# Suspend all messages on the server
Get-Message -Server $Server -ResultSize Unlimited | Suspend-Message -Confirm:$false

# Export to .eml files
Get-Message -Server $Server -ResultSize Unlimited | ForEach-Object {
  # Sanitize filename
  $safeName = $_.InternetMessageID.Trim('<','>') -replace '[\\/:*?"<>|]', '_'
  $outFile = Join-Path $ExportRoot ("$safeName.eml")

  try {
   Export-Message -Identity $_.Identity | AssembleMessage -Path $outFile
   Write-Verbose "Exported $_.Identity → $outFile"
  }
  catch {
   Write-Warning "Failed to export $_.Identity: $_"
  }
 }
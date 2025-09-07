<#
.SYNOPSIS
Validating environment readiness for Exchange hybrid migration.

.DESCRIPTION
This script checks for existing public folders in Exchange Online and then exports them and removes them.

.OUTPUT
Exports and deletes any public folders detected in Exchange Online, and optionally permanently removes hierarchy.

.NOTES
Run this script in Exchange Online PowerShell. This script permanently deletes public folders from Exchange Online.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is excerpted from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll
#>

# Set output paths
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$exportFolder = "C:\PFMigrationBackup_$timestamp"
New-Item -ItemType Directory -Path $exportFolder -Force | Out-Null

# Export list of public folder mailboxes
$pfMailboxes = Get-Mailbox -PublicFolder
$pfMailboxes | Select Name, Identity, ExchangeGuid, PrimarySmtpAddress | Export-Csv "$exportFolder\PFMailboxes.csv" -NoTypeInformation
Write-Host "Exported PF mailbox list to $exportFolder\PFMailboxes.csv"

# Export public folder structure and content summary
Get-PublicFolder -Recurse | ForEach-Object {
  $folderPath = $_.Identity.ToString().Replace("\", "_")
  $outputFile = "$exportFolder\PF_$folderPath.csv"
  Get-PublicFolderItemStatistics $_.Identity | Select Identity, Subject, ItemClass, LastModifiedTime | Export-Csv $outputFile -NoTypeInformation
  Write-Host "Exported contents of folder '$($_.Identity)' to $outputFile"
}
# Get hierarchy mailbox GUID
$hierarchyMailboxGuid = (Get-OrganizationConfig).RootPublicFolderMailbox.HierarchyMailboxGuid

# Remove non-hierarchy public folder mailboxes
foreach ($mbx in $pfMailboxes) {
  if ($mbx.ExchangeGuid -ne $hierarchyMailboxGuid) {
    Write-Host "Removing non-hierarchy mailbox: $($mbx.Name)"
    Remove-Mailbox -PublicFolder $mbx.Identity -Confirm:$false -Force
  }
}

# Optional: Remove hierarchy mailbox (PERMANENTLY removes all existing PFs)
# Write-Host "Removing hierarchy mailbox: $($mbx.Name)"
# Remove-Mailbox -PublicFolder $mbx.Identity -Confirm:$false -Force

# Remove soft-deleted mailboxes
$softDeleted = Get-Mailbox -PublicFolder -SoftDeletedMailbox
foreach ($mbx in $softDeleted) {
  Write-Host "Removing soft-deleted mailbox: $($mbx.Name)"
  Remove-Mailbox -PublicFolder $mbx.PrimarySmtpAddress -PermanentlyDelete:$true -Force -Confirm:$false
}

# Remove conflict (CNF) mailboxes
foreach ($mbx in $softDeleted) {
  if ($mbx.Name -like "*CNF:*" -or $mbx.Identity -like "*CNF:*") {
    Write-Host "Removing CNF mailbox: $($mbx.Name)"
    Remove-Mailbox -PublicFolder $mbx.ExchangeGUID.Guid -RemoveCNFPublicFolderMailboxPermanently -Force -Confirm:$false
  }
}

Write-Host "Cleanup complete. All exports saved to: $exportFolder"
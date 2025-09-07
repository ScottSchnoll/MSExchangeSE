<#
.SYNOPSIS
Validating environment readiness for Exchange hybrid migration.

.DESCRIPTION
This script checks for duplicate SMTP addresses for MEPFs.

.OUTPUT
Displays any addresses for an MEPF that are duplicates.

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

$allPFs = Get-ADObject -LDAPFilter "(&(objectClass=publicFolder)(mail=*))" -SearchBase "CN=Microsoft Exchange System Objects,DC=<Domain>,DC=com" -Properties proxyAddresses
$allSMTPs = $allPFs | ForEach-Object {
  $_.proxyAddresses | Where-Object { $_ -like "SMTP:*" } | ForEach-Object {
    [PSCustomObject]@{
      FolderName = $_.Name
      SMTPAddress = $_.ToLower().Replace("smtp:", "")
    }
  }
}
$duplicates = $allSMTPs | Group-Object SMTPAddress | Where-Object { $_.Count -gt 1 }
$duplicates | ForEach-Object {
  Write-Host "Duplicate SMTP address found: $($_.Name)"
  $_.Group | ForEach-Object { Write-Host "Folder: $($_.FolderName)" }
}
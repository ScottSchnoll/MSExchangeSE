<#
.SYNOPSIS
Validating environment readiness for Exchange hybrid migration.

.DESCRIPTION
This script checks for duplicate display names and legacyExchangeDNs for MEPFs.

.OUTPUT
Displays any duplicate display names and legacyExchangeDNs for an MEPF.

.NOTES
Replace <Domain> with your organization's domain.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll (ISBN: 9798262871872)
#>

$allPFs = Get-ADObject -LDAPFilter "(&(objectClass=publicFolder)(mail=*))" -SearchBase "CN=Microsoft Exchange System Objects,DC=<Domain>,DC=com" -Properties displayName, legacyExchangeDN
$dupDisplayNames = $allPFs | Group-Object displayName | Where-Object { $_.Count -gt 1 }
$dupLegacyDNs = $allPFs | Group-Object legacyExchangeDN | Where-Object { $_.Count -gt 1 }
if ($dupDisplayNames) {
  Write-Host "Duplicate display names found:"
  $dupDisplayNames | ForEach-Object { $_.Group | ForEach-Object { Write-Host " $($_.displayName)" } }
}
if ($dupLegacyDNs) {
  Write-Host "Duplicate legacyExchangeDNs found:"
  $dupLegacyDNs | ForEach-Object { $_.Group | ForEach-Object { Write-Host " $($_.legacyExchangeDN)" } }
}
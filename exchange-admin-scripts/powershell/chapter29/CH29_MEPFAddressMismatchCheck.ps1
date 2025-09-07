<#
.SYNOPSIS
Validating environment readiness for Exchange hybrid migration.

.DESCRIPTION
This script normalizes and compares SMTP addresses listed in AD and Exchange for MEPFs. If you find any mismatches, you can use Set-MailPublicFolder to update Exchange or Set-ADObject to update AD.

.OUTPUT
Displays any addresses for an MEPF that are mismatched in AD and Exchange.

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

$adMEPFs = Get-ADObject -LDAPFilter "(&(objectClass=publicFolder)(mail=*))" -SearchBase "CN=Microsoft Exchange System Objects,DC=<Domain>,DC=com" -Properties proxyAddresses, mail
$exMEPFs = Get-MailPublicFolder -ResultSize unlimited
foreach ($adPF in $adMEPFs) {
  $adSMTPs = $adPF.proxyAddresses | Where-Object { $_ -like "SMTP:*" } | ForEach-Object { $_.ToLower().Replace("smtp:", "") }
  $exPF = $exMEPFs | Where-Object { $_.Name -eq $adPF.Name }
  if ($exPF) {
    $exSMTPs = $exPF.EmailAddresses | Where-Object { $_ -like "SMTP:*" } | ForEach-Object { $_.ToLower().Replace("smtp:", "") }
    $missingInExchange = $adSMTPs | Where-Object { $_ -notin $exSMTPs }
    $missingInAD = $exSMTPs | Where-Object { $_ -notin $adSMTPs }
    if ($missingInExchange -or $missingInAD) {
      Write-Host "Mismatch for $($adPF.Name):"
      if ($missingInExchange) { Write-Host "AD-only addresses: $missingInExchange" }
      if ($missingInAD) { Write-Host "Exchange-only addresses: $missingInAD" }
    }
  } else {
    Write-Host "No matching Exchange object for AD public folder: $($adPF.Name)"
  }
}
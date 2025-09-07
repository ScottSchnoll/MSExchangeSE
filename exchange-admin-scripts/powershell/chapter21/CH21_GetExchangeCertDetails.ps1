<#
.SYNOPSIS
Exchange Server certificate management.

.DESCRIPTION
This script displays all relevant Exchange Server certificate properties directly from the Windows Certificate Store.

.OUTPUT
All relevant certificate details are displayed.

.NOTES
Replace the values below with those appropriate for your organization, and modify the script as needed to collect and store the output.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is excerpted from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll
#>

$certs = Get-ExchangeCertificate
foreach ($cert in $certs) {
  $thumbprint = $cert.Thumbprint
  $storeCert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $thumbprint }
  Write-Host "=== Certificate: $thumbprint ==="
  Write-Host "Subject: $($cert.Subject)"
  Write-Host "CertificateDomains: $($cert.CertificateDomains -join ', ')"
  Write-Host "NotBefore: $($cert.NotBefore)"
  Write-Host "NotAfter: $($cert.NotAfter)"
  Write-Host "HasPrivateKey: $($storeCert.HasPrivateKey)"
  Write-Host "PrivateKeyExportable: $($storeCert.PrivateKey.Key.ExportPolicy -contains 'Exportable')"
  Write-Host "PublicKeySize: $($storeCert.PublicKey.Key.KeySize)"
  Write-Host "RootCAType: $($cert.RootCAType)"
  Write-Host "Services: $($cert.Services)"
  Write-Host "IISServices: $($cert.Services -like '*IIS*')"
  Write-Host "IsSelfSigned: $($cert.IsSelfSigned)"
  Write-Host "Issuer: $($cert.Issuer)"
  
# Signature Algorithm and Hash Algorithm
  Write-Host "Signature Algorithm: $($storeCert.SignatureAlgorithm.FriendlyName)"
  Write-Host "Signature Hash Algorithm: $($storeCert.SignatureAlgorithm.Value)"

  # Thumbprint Algorithm (same as hash algorithm used for thumbprint)
  Write-Host "Thumbprint Algorithm: SHA1"

  # Key Usage
  foreach ($ext in $storeCert.Extensions) {
    if ($ext.Oid.FriendlyName -eq "Key Usage") {
      $ku = New-Object System.Security.Cryptography.X509Certificates.X509KeyUsageExtension $ext, $true
      Write-Host "Key Usage: $($ku.KeyUsages)"
    }
  }

  # Basic Constraints
  foreach ($ext in $storeCert.Extensions) {
    if ($ext.Oid.FriendlyName -eq "Basic Constraints") {
      $bc = New-Object System.Security.Cryptography.X509Certificates.X509BasicConstraintsExtension $ext, $true
      Write-Host "Basic Constraints: CA=$($bc.CertificateAuthority), PathLength=$($bc.PathLengthConstraint)"
    }
  }

  # Enhanced Key Usage
  foreach ($ext in $storeCert.Extensions) {
    if ($ext.Oid.FriendlyName -eq "Enhanced Key Usage") {
      $eku = New-Object System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension $ext, $true
      foreach ($oid in $eku.EnhancedKeyUsages) {
        Write-Host "EnhancedKeyUsage: $($oid.FriendlyName) ($($oid.Value))"
      }
    }
  }

  Write-Host ""
}
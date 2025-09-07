<#
.SYNOPSIS
This script can be used as part of Exchange Auth Certificate management. It’s very important to rotate the Auth Certificate, and staging a next Auth Certificate in Exchange is considered a security best practice, especially in environments where uptime, hybrid connectivity, or secure server-to-server authentication is critical. By setting a NextCertificateThumbprint with an effective date at least 48 hours in the future, Exchange can automatically promote the new certificate without downtime.

.DESCRIPTION
This script is used to stage a next Auth Certificate for Exchange.

.OUTPUT
A next Auth Certificate is generated and staged.

.NOTES
IMPORTANT: When prompted in the script to overwrite the existing default SMTP certificate, choose NO.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is excerpted from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll
#>

# Create a new self-signed certificate
$newCert = New-ExchangeCertificate -KeySize 2048 -PrivateKeyExportable $true -SubjectName "CN=Microsoft Exchange Server Auth Certificate" -FriendlyName "Microsoft Exchange Server Auth Certificate" -DomainName @()

# Set it as the next OAuth certificate with a 49-hour delay
Set-AuthConfig -NewCertificateThumbprint $newCert.Thumbprint -NewCertificateEffectiveDate (Get-Date).AddHours(49)

# Publish the new certificate
Set-AuthConfig -PublishCertificate

# Optional: Clear the previous certificate reference
Set-AuthConfig -ClearPreviousCertificate

# Restart services to apply changes
Restart-Service MSExchangeServiceHost
Restart-WebAppPool MSExchangeOWAAppPool
Restart-WebAppPool MSExchangeECPAppPool
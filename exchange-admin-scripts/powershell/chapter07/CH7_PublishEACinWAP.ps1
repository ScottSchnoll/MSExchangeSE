<#
.SYNOPSIS
This script is used when deploying modern authentication using AD FS.

.DESCRIPTION
This script publishes the EAC in Web Application Proxy.

.OUTPUT
OWA is published in WAP.

.NOTES
Replace ExternalUrl, ExternalCertificateThumbprint, and BackendServerUrl with your organization's values

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll (ISBN: 9798262871872)
#>

Add-WebApplicationProxyApplication -ExternalPreauthentication ADFS -ADFSRelyingPartyName "EAC" -Name "EAC" -ExternalUrl "https://mail.msexchangese.com/ecp/" -ExternalCertificateThumbprint FFD6BB51325D4BD4654D0303BE4651B44E5C9BF1 -BackendServerUrl "https://mail.msexchangese.com/ecp/"
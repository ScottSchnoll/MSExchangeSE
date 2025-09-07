<#
.SYNOPSIS
This script is used when deploying modern authentication using AD FS.

.DESCRIPTION
This script publishes OWA in Web Application Proxy.

.OUTPUT
OWA is published in WAP.

.NOTES
Replace ExternalUrl, ExternalCertificateThumbprint, and BackendServerUrl with your organization's values

.AUTHOR
Scott Schnoll

.COPYRIGHT
# Copyright © 2025 Scott Schnoll. All Rights Reserved.
# This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.
#
# .SOURCE
This script is excerpted from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll
#>

Add-WebApplicationProxyApplication -ExternalPreauthentication ADFS -ADFSRelyingPartyName "OWA" -Name "OWA" -ExternalUrl https://mail.msexchangese.com/owa/ -ExternalCertificateThumbprint FFD6BB51325D4BD4654D0303BE4651B44E5C9BF1 -BackendServerUrl "https://mail.msexchangese.com/owa/"
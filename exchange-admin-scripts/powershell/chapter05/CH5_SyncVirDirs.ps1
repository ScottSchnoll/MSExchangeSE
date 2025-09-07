<#
.SYNOPSIS
Synchronizing internal and external URLs across virtual directories for ECP, EWS, EAS, OAB, OWA, and PowerShell.

.DESCRIPTION
This script gets the internal URL for a virtual directory and configures the external URL to be the same.

.OUTPUT
The ExternalURLs for the ECP, EWS, EAS, OAB, OWA, and PowerShell virtual directoryes are configured with the same URL as the InternalURL.

.NOTES


.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll (ISBN: 9798262871872)

#>

Set-EcpVirtualDirectory "$HostName\ECP (Default Web Site)" -InternalUrl ((Get-EcpVirtualDirectory "$HostName\ECP (Default Web Site)").ExternalUrl)
Set-WebServicesVirtualDirectory "$HostName\EWS (Default Web Site)" -InternalUrl ((Get-WebServicesVirtualDirectory "$HostName\EWS (Default Web Site)").ExternalUrl)
Set-ActiveSyncVirtualDirectory "$HostName\Microsoft-Server-ActiveSync (Default Web Site)" -InternalUrl ((Get-ActiveSyncVirtualDirectory "$HostName\Microsoft-Server-ActiveSync (Default Web Site)").ExternalUrl)
Set-OabVirtualDirectory "$HostName\OAB (Default Web Site)" -InternalUrl ((Get-OabVirtualDirectory "$HostName\OAB (Default Web Site)").ExternalUrl)
Set-OwaVirtualDirectory "$HostName\OWA (Default Web Site)" -InternalUrl ((Get-OwaVirtualDirectory "$HostName\OWA (Default Web Site)").ExternalUrl)
Set-PowerShellVirtualDirectory "$HostName\PowerShell (Default Web Site)" -InternalUrl ((Get-PowerShellVirtualDirectory "$HostName\PowerShell (Default Web Site)").ExternalUrl)

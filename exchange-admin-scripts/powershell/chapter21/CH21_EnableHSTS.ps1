<#
.SYNOPSIS
Enabling HTTP Strict Transport Security (HSTS) on an Exchange server.

.DESCRIPTION
This script enables HSTS on the server.

.OUTPUT
HSTS is configured for the Default Web Site.

.NOTES
Run this script from an elevated PowerShell prompt.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is excerpted from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll
#>

Import-Module IISAdministration
Reset-IISServerManager -Confirm:$false
Start-IISCommitDelay
$sitesCollection = Get-IISConfigSection -SectionPath "system.applicationHost/sites" | Get-IISConfigCollection
$siteElement = Get-IISConfigCollectionElement -ConfigCollection $sitesCollection -ConfigAttribute @{"name"="Default Web Site"}
$hstsElement = Get-IISConfigElement -ConfigElement $siteElement -ChildElementName "hsts"
Set-IISConfigAttributeValue -ConfigElement $hstsElement -AttributeName "enabled" -AttributeValue $true
Set-IISConfigAttributeValue -ConfigElement $hstsElement -AttributeName "maxage" -AttributeValue 300
Set-IISConfigAttributeValue -ConfigElement $hstsElement -AttributeName "includeSubDomains" -AttributeValue $true
Stop-IISCommitDelay
Remove-Module IISAdministration
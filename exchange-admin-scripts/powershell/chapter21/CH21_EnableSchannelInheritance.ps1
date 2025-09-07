<#
.SYNOPSIS
Configuring .NET Framework 4.x to inherit its values from Schannel, which enables the system to use the latest versions of TLS supported by the OS (currently TLS 1.3).

.DESCRIPTION
This script enables .NET Framework 4.x Schannel inheritance.

.OUTPUT
.NET Framework 4.x inherits crypto values from Schannel.

.NOTES
Backup your registry before running this script. Run this script from an elevated PowerShell prompt. Restart the computer after running this script.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is excerpted from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll
#>

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319" -Name "SystemDefaultTlsVersions" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319" -Name "SchUseStrongCrypto" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319" -Name "SystemDefaultTlsVersions" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319" -Name "SchUseStrongCrypto" -Value 1 -Type DWord
<#
.SYNOPSIS
Disabling outdated ciphers and hashes.

.DESCRIPTION
This script explicitly disables all outdated ciphers and hashes on the system.

.OUTPUT
All outdated ciphers and hashes are disabled on the server.

.NOTES
Backup your registry before running this script. Run this script from an elevated PowerShell prompt. Restart the computer after running this script.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll (ISBN: 9798262871872)
#>

# Define base paths
$schannelPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL"
$ciphersPath = "$schannelPath\Ciphers"
$hashesPath  = "$schannelPath\Hashes"
# Lists of items to disable
$ciphers = @(  "DES 56/56",
  "NULL",
  "RC2 40/128",
  "RC2 56/128",
  "RC2 56/56",
  "RC4 40/128",
  "RC4 56/128",
  "RC4 64/128",
  "RC4 128/128",
  "Triple DES 168"
)
$hashes = @("MD5")

# Ensure parent keys exist
New-Item -Path $schannelPath -Name "Ciphers" -ErrorAction SilentlyContinue | Out-Null
New-Item -Path $schannelPath -Name "Hashes" -ErrorAction SilentlyContinue | Out-Null

# Create and disable ciphers
foreach ($cipher in $ciphers) {
  New-Item -Path $ciphersPath -Name $cipher -ErrorAction SilentlyContinue | Out-Null
  Set-ItemProperty -Path "$ciphersPath\$cipher" -Name "Enabled" -Value 0 -Type DWord
}

# Create and disable hashes
foreach ($hash in $hashes) {
  New-Item -Path $hashesPath -Name $hash -ErrorAction SilentlyContinue | Out-Null
  Set-ItemProperty -Path "$hashesPath\$hash" -Name "Enabled" -Value 0 -Type DWord
}
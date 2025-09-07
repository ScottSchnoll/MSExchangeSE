<#
.SYNOPSIS
This script is used in cross-forest mailbox moves.

.DESCRIPTION
This script configures the migration endpoint and then creates a cross-forest batch move using a .csv file.

.OUTPUT
A migration endpoint is created, along with a migration batch that uses a CSV file.

.NOTES
Replace the values below with those appropriate for your organization. The Timezone parameter indicates the time zone of the admin who submits the migration batch. If you omit this parameter, it will default to the time zone setting of the Exchange server from which the command is being run.

.AUTHOR
Scott Schnoll

.COPYRIGHT
# Copyright © 2025 Scott Schnoll. All Rights Reserved.
# This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.
#
# .SOURCE
This script is excerpted from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll
#>

# To view TimeZones
# $TimeZone = Get-ChildItem "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Time zones" | ForEach-Object { Get-ItemProperty $_.PSPath } | Sort-Object Display | Select-Object PSChildName,Display
# $TimeZone | FT -AutoSize

New-MigrationEndpoint -Name MoveLobster -ExchangeRemoteMove -Autodiscover -EmailAddress jeffday@msexchangese.com -Credentials (Get-Credential msexchangese\scott) 
$csvData=[System.IO.File]::ReadAllBytes("D:\Moves\Lobster.csv")
New-MigrationBatch -CSVData $csvData -TimeZone "Pacific Standard Time" -Name Lobsterfest -SourceEndpoint LobsterFans -TargetDeliveryDomain "nwnetworks.com"


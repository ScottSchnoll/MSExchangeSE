<#
.SYNOPSIS
Change control for Exchange Server by collecting current configuration data before making any configuration changes.

.DESCRIPTION
This script collects Transport and Mailbox Database configuration settings.

.OUTPUT
Transport configuration, including receive connectors and send connectors, and mailbox data is exported to CSV files.

.NOTES
Replace the values below with those appropriate for your organization.  Modify $OutputRoot and CSV file names as desired. Run this script in tandem with Health Checker (https://aka.ms/HeathChecker).

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll (ISBN: 9798262871872)
#>

function Export-ExchangeConfiguration {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$OutputRoot  # e.g. C:\ExchangeConfigExports
  )

  # Build the folder
  $timestamp = Get-Date -Format 'yyyyMMdd_HHmm'
  $outDir  = Join-Path -Path $OutputRoot -ChildPath "ConfigSnapshot_$timestamp"

  if (-not (Test-Path -Path $outDir)) {
    New-Item -Path $outDir -ItemType Directory | Out-Null
  }

  # Export TransportService settings
  Get-TransportService |
   Select-Object Name,
          ReceiveProtocolLogPath,
          SendProtocolLogPath,
          ReceiveProtocolLogMaxFileSize,
          SendProtocolLogMaxFileSize,
          ReceiveProtocolLogMaxAge,
          SendProtocolLogMaxAge |
   Export-CliXml -Path (Join-Path -Path $outDir -ChildPath 'TransportService.xml')

  # Export Receive connectors
  Get-ReceiveConnector -Server $env:COMPUTERNAME |
   Export-Csv -Path (Join-Path -Path $outDir -ChildPath 'ReceiveConnectors.csv') -NoTypeInformation

  # Export Send connectors
  Get-SendConnector |
   Export-Csv -Path (Join-Path -Path $outDir -ChildPath 'SendConnectors.csv') -NoTypeInformation

  # Export Mailbox Databases
  Get-MailboxDatabase |
   Export-CliXml -Path (Join-Path -Path $outDir -ChildPath 'MailboxDatabases.xml')

  Write-Host "Configuration exported to $outDir"
}
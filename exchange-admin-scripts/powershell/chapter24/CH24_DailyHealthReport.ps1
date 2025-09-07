<#
.SYNOPSIS
Monitoring Exchange Server health and performance.

.DESCRIPTION
This script creates a daily health summary report for Exchange.

.OUTPUT
A daily health report in CSV format is created.

.NOTES
Replace the values below with those appropriate for your organization. Modify $outfile and Identity as needed. Run this script on the Exchange server.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll (ISBN: 9798262871872)
#>

# Create the outfile path ahead of time
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$outfile = "C:\ExchangePerfLogs\DailyHealth_$timestamp.csv"

# HealthSets not in "Healthy" state
$health = Get-ServerHealth -Identity $env:COMPUTERNAME -HealthSet * | Where-Object { $_.AlertValue -ne 'Healthy' } | Select-Object Name, HealthSetName, AlertValue

# DB copy status
$dbCopies = Get-MailboxDatabaseCopyStatus -Server $env:COMPUTERNAME | Where-Object { $_.Status -ne 'Healthy' -or $_.CopyQueueLength -gt 10 -or $_.ReplayQueueLength -gt 10 } | Select-Object Name, Status, CopyQueueLength, ReplayQueueLength

# Queue depth summary
$queues = Get-Queue | Measure-Object -Property MessageCount -Sum
$totalMessages = $queues.Sum

# Disk space check
$drives = Get-PSDrive -PSProvider FileSystem | Select Name, @{n="FreeGB";e={"{0:N2}" -f ($_.Free / 1GB)}}

# Managed Availability recovery actions (past 24h)
$recentActions = Get-WinEvent -LogName 'Microsoft-Exchange-ManagedAvailability/RecoveryActionResults' -MaxEvents 20 | Where-Object { $_.TimeCreated -gt (Get-Date).AddDays(-1) } | Select TimeCreated, Message

# AD health status
$adHealth = Get-ServerHealth -Identity $env:COMPUTERNAME -HealthSet ADAccess | Select-Object Name, AlertValue

# Create summary object
$report = [pscustomobject]@{
  Timestamp = $timestamp
  ProblemHealthSets = ($health | ForEach-Object { "$($_.HealthSetName):$($_.AlertValue)" }) -join "; "
  DBIssues = ($dbCopies | ForEach-Object { "$($_.Name):$($_.Status) CQ:$($_.CopyQueueLength) RQ:$($_.ReplayQueueLength)" }) -join "; "
  TotalQueuedMessages = $totalMessages
  LDAP_SearchTimeMS = $ldap
  RecoveryActions_Last24h = ($recentActions | ForEach-Object { "$($_.TimeCreated): $($_.Message)" }) -join "`n"
  FreeDiskSpace = ($drives | ForEach-Object { "$($_.Name): $($_.FreeGB) GB" }) -join "; "
}
$report | Export-Csv -Path $outfile -NoTypeInformation
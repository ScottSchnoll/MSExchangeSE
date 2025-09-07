<#
.SYNOPSIS
Monitoring Exchange Server performance.

.DESCRIPTION
This script collects key Exchange performance data and exports it to a CSV file.

.OUTPUT
CSV file containing collected Exchange Server performance data.

.NOTES
Modify $outfile as needed.

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
$outfile = "C:\ExchangePerfLogs\CorePerf_$timestamp.csv"
$data = [pscustomobject]@{
  Timestamp = $timestamp
  CPU_Util = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples[0].CookedValue
  CPU_Interrupt = (Get-Counter '\Processor(_Total)\% Interrupt Time').CounterSamples[0].CookedValue
  Mem_AvailableMB = (Get-Counter '\Memory\Available MBytes').CounterSamples[0].CookedValue
  Mem_PagesPerSec = (Get-Counter '\Memory\Pages/sec').CounterSamples[0].CookedValue
  Store_WorkingSetMB = [math]::Round((Get-Process Microsoft.Exchange.Store.Worker).WorkingSet64 / 1MB, 2)
  Disk_ReadMS = (Get-Counter '\PhysicalDisk(_Total)\Avg. Disk sec/Read').CounterSamples[0].CookedValue
  Disk_WriteMS = (Get-Counter '\PhysicalDisk(_Total)\Avg. Disk sec/Write').CounterSamples[0].CookedValue
  Disk_QueueLength = (Get-Counter '\PhysicalDisk(_Total)\Current Disk Queue Length').CounterSamples[0].CookedValue
  DB_ReadLatencyMS = (Get-Counter '\MSExchange Database ==> Instances(*)\I/O Database Reads Average Latency').CounterSamples | Measure -Property CookedValue -Average | Select -ExpandProperty Average
  DB_WriteLatencyMS = (Get-Counter '\MSExchange Database ==> Instances(*)\I/O Log Writes Average Latency').CounterSamples | Measure -Property CookedValue -Average | Select -ExpandProperty Average
  DB_CacheMB = (Get-Counter '\MSExchange Database(*)\Database Cache Size (MB)').CounterSamples | Measure -Property CookedValue -Average | Select -ExpandProperty Average
}
$data | Export-Csv -Path $outfile -NoTypeInformation
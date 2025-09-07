<#
.SYNOPSIS
Monitoring Exchange Server performance.

.DESCRIPTION
This script collects lightweight queue metrics and exports it to a CSV file.

.OUTPUT
CSV file containing collected Exchange Server queue metrics.

.NOTES
Modify $outfile as needed.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is excerpted from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll
#>

# Create the outfile path ahead of time
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$outfile = "C:\ExchangePerfLogs\QueueMetrics_$timestamp.csv"
Get-Queue | Select Identity,DeliveryType,Status,MessageCount | Export-Csv -Path $outfile -NoTypeInformation
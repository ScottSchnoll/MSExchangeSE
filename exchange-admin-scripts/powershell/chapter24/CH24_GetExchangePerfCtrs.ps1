<#
.SYNOPSIS
Exporting available Exchange performance categories and counters to a CSV file.

.DESCRIPTION
This script exports all performance counter categories for Exchange to a CSV file.

.OUTPUT
CSV file containing Exchange Server performance counters.

.NOTES
Modify the Export-Csv path as needed.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll (ISBN: 9798262871872)
#>

$results = @()
$counterSets = Get-Counter -ListSet "*Exchange*"
foreach ($set in $counterSets) {
  $category = $set.CounterSetName
  foreach ($counter in $set.Counter) {
    $obj = New-Object PSObject
    $obj | Add-Member -MemberType NoteProperty -Name Category -Value $category
    $obj | Add-Member -MemberType NoteProperty -Name Counter -Value $counter
    $results += $obj
  }
}
$results | Export-Csv -Path "$env:USERPROFILE\Documents\ExchangePerfCounters.csv" -NoTypeInformation -Encoding UTF8
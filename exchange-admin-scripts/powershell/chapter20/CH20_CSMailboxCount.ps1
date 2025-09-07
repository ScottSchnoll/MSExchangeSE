<#
.SYNOPSIS
This script is helpful when you need to create a compliance search with 500 or fewer source mailboxes.

.DESCRIPTION
This script displays the number of source mailboxes that contain search results from the specified compliance search.

.OUTPUT
Total number of mailboxes that contain search results in the specified compliance search.

.NOTES
Replace the values below with those appropriate for your organization. Provide the name of your compliance search when prompted.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll (ISBN: 9798262871872)
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $true, Position = 1)]
  [string]$SearchName
)

# Retrieve the compliance search
$search = Get-ComplianceSearch $SearchName

if ($null -eq $search) {
Write-Output "A compliance search named '$SearchName' was not found."    return
}

if ($search.Status -ne 'Completed') {
  Write-Output "Search results are pending. Current status: $($search.Status)"
  return
}

$results = $search.SuccessResults
if (($search.Items -le 0) -or ([string]::IsNullOrWhiteSpace($results))) {
  Write-Output "The compliance search named '$SearchName' didn't return any results."
  return
}

$mailboxes = @()
$lines = $results -split '[\r\n]+'
foreach ($line in $lines) {
  if ($line -match 'Location: (\S+),.+Item count: (\d+)' -and [int]$matches[2] -gt 0) {
    $mailboxes += $matches[1]
  }
}

Write-Output "Number of mailboxes with search results: $($mailboxes.Count)"
$mailboxes
<#
.SYNOPSIS
Converting an estimate-onblt compliance search into a new compliance search.

.DESCRIPTION
This script creates a new compliance search based on the specified compliance search, but does not start it.  You can use Start-MailboxSearch -Identity <Name> to start it when desired.

.OUTPUT
A new compliance search is created but not started.

.NOTES
Replace the values below with those appropriate for your organization. When prompted, enter the name of your compliance search.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is excerpted from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll
#>

[CmdletBinding(DefaultParameterSetName = 'Create')]
param(
 [Parameter(Mandatory = $true, Position = 0)]
 [string]$SearchName,

 [Parameter(ParameterSetName = 'Original')]
 [switch]$Original,

 [Parameter(ParameterSetName = 'Restore')]
 [switch]$RestoreOriginal
)

# Retrieve the compliance search by simple name lookup
$search = Get-ComplianceSearch $SearchName
if (-not $search) {
 Write-Error "A compliance search named '$SearchName' was not found."
 return
}

if ($search.Status -ne 'Completed') {
 Write-Warning "Search '$SearchName' has not completed (Status=$($search.Status)). Re-run this script after it has finished."
 return
}

# Parse raw SuccessResults for mailboxes with hits
if ($search.Items -le 0 -or [string]::IsNullOrWhiteSpace($search.SuccessResults)) {
 Write-Warning "Search '$SearchName' has no results."
 return
}

$mailboxes = $search.SuccessResults -split '[\r\n]+' | ForEach-Object {
   if ($_ -match 'Location: (\S+),.+Item count: (\d+)') {
    [int]$count = [int]$matches[2]
    if ($count -gt 0) { $matches[1] }
   }
  }

if (-not $mailboxes) {
 Write-Warning "No mailboxes with results found for '$SearchName'."
 return
}
# Preload existing MailboxSearch names just once
$existingNames = Get-MailboxSearch -ResultSize unlimited | Select-Object -ExpandProperty Name

# Find next unique name
$prefix = "${SearchName}_"
$i = 1
do {
 $newName = "$prefix$i"
 $i++
} while ($existingNames -contains $newName)

# Build SearchQuery param (prefer KeywordQuery)
$q = if (-not [string]::IsNullOrWhiteSpace($search.KeywordQuery)) {
    $search.KeywordQuery
   } elseif (-not [string]::IsNullOrWhiteSpace($search.ContentMatchQuery)) {
    $search.ContentMatchQuery
   } else {
    $null
   }

# Splat for New-MailboxSearch
$params = @{
 Name = $newName
 SourceMailboxes = $mailboxes
 EstimateOnly = $true
}
if ($q) { $params.SearchQuery = $q }

# Create the mailbox search
try {
 New-MailboxSearch @params -ErrorAction Stop
 Write-Output "Created MailboxSearch '$newName' with $($mailboxes.Count) mailboxes."
}
catch {
 Write-Error "Failed to create MailboxSearch '$newName': $_"
}

# Optional -Original / -RestoreOriginal logic
# if ($Original) { … } elseif ($RestoreOriginal) { … }
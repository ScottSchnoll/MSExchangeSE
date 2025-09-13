<#
.SYNOPSIS
This script can be used to capture settings, and as part of moving a replicated database copy, as described in Chapter 18.

.DESCRIPTION
This script captures replay lag and truncation lag settings for all copies of replicated databases in a DAG.

.OUTPUT
Text file containing replay lag and truncation lag settings for all database copies.

.NOTES
Replace the values below with those appropriate for your organization.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll (ISBN: 9798262871872)
#>

# Output folder – change path if desired
$outputFolder = Join-Path -Path (Get-Location) -ChildPath "LagSettingsExport"

# Create output folder if it doesn't exist
if (-not (Test-Path $outputFolder)) {
  Write-Host "Creating output folder: $outputFolder"
  New-Item -ItemType Directory -Path $outputFolder | Out-Null
}

# Get all replicated mailbox databases
$replicatedDatabases = Get-MailboxDatabase | Where-Object {
  ($_.ReplicationType -eq 'Remote') -or
  ((Get-MailboxDatabaseCopyStatus -Identity $_.Name).Count -gt 1)
}
foreach ($db in $replicatedDatabases) {

  # Build a clean header
  $header = "==== $($db.Name) ===="

  # Gather the lag details, strip out extra blank lines
  $rawDetails = Get-MailboxDatabase $db.Name |
         FL *Lag* |
         Out-String -Stream
  $trimmedDetails = $rawDetails |
           Where-Object { $_.Trim().Length -gt 0 } |
           ForEach-Object { $_.TrimEnd() }

  # Combine header + one blank line + details + trailing blank line
  	$fileContent = $header + "`r`n" + "`r`n" +
          ($trimmedDetails -join "`r`n") + "`r`n"

  # Console output
  Write-Host $fileContent

  # Build timestamped filename
  $timestamp = Get-Date -Format "yyyyMMdd_HHmm"
  $fileName = "$($db.Name)_LagSettings_$timestamp.txt"
  $filePath = Join-Path -Path $outputFolder -ChildPath $fileName

  # Write to disk
  try {
    [System.IO.File]::WriteAllText($filePath, $fileContent)
    Write-Host "Saved: $fileName"
  }
  catch {
    Write-Warning "Failed to write '$fileName': $_"
  }

  # One blank line to separate results
  Write-Host ""
}
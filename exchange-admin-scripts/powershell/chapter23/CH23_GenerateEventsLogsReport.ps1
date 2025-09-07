<#
.SYNOPSIS


.DESCRIPTION
This script collects error and warning events from the key crimson channels for Exchange, as well as information in the cluster log file from the last 60 minutes, which is useful for correlation with event log entries. 

.OUTPUT
The script generates cluster logs, collects events, and produces an HTML report.

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

# === Parameters ===
$clusterLogPath = "C:\ClusterLogs"
$clusterTimeSpan = 60
$htmlPath = "$env:USERPROFILE\Desktop\DAG_Health_Report.html"

# === Patterns ===
$clusterErrorPatterns = "failover|MoveGroup|error|resource failure|Lost communication"
$clusterWarningPatterns = "quorum|heartbeat|network latency"
$exchangeErrorPatterns = "error|fail|resource|data loss|Lost communication|copy queue|replay queue"
$exchangeWarningPatterns = "quorum|latency|mount|slow|stall"

# === Begin Status ===
Write-Host "Starting DAG Health Report..." -ForegroundColor Cyan

# === Collect Cluster Logs ===
Write-Host "Collecting cluster logs from past $clusterTimeSpan minutes..." -ForegroundColor Cyan
$null = Get-ClusterLog -TimeSpan $clusterTimeSpan -Destination $clusterLogPath

# === Parse Cluster Logs ===
Write-Host "Parsing cluster logs..." -ForegroundColor Cyan
$clusterFindings = @{}
Get-ChildItem -Path $clusterLogPath -Filter "*.log" | ForEach-Object {
  $source = $_.Name
  $lines = Get-Content $_.FullName
  foreach ($line in $lines) {
    $timestamp = ""
    if ($line -match '\d{4}/\d{2}/\d{2}-\d{2}:\d{2}:\d{2}') {
      $timestamp = $matches[0]
    }
    $cleanMsg = ($line -replace '\d{4}/\d{2}/\d{2}-\d{2}:\d{2}:\d{2}\.\d+', '').Trim()
    $severity = ""
    if ($line -match $clusterErrorPatterns) { $severity = "Error" }
    elseif ($line -match $clusterWarningPatterns) { $severity = "Warning" }

    if ($severity) {
      if (-not $clusterFindings.ContainsKey($cleanMsg)) {
        $clusterFindings[$cleanMsg] = @{
          Count = 1; FirstSeen = $timestamp; LastSeen = $timestamp;
          Severity = $severity; Source = $source
        }
      } else {
        $entry = $clusterFindings[$cleanMsg]
        $entry.Count++
        $entry.LastSeen = $timestamp
      }
    }
  }
}

# === Scan Exchange Channels ===
Write-Host "Scanning Exchange channels..." -ForegroundColor Cyan
$channels = @(
  "Microsoft-Exchange-HighAvailability/Operational",
  "Microsoft-Exchange-HighAvailability/BlockReplication",
  "Microsoft-Exchange-HighAvailability/Seeding",
  "Microsoft-Exchange-HighAvailability/Monitoring",
  "Microsoft-Exchange-MailboxDatabaseFailureItems/Operational",
  "Microsoft-Exchange-ManagedAvailability/Monitoring",
  "Microsoft-Exchange-ManagedAvailability/RecoveryActionLogs",
  "Microsoft-Exchange-ESE/Operational",
  "Microsoft-Exchange-ActiveMonitoring/ProbeResult",
  "Microsoft-Exchange-ActiveMonitoring/MonitorResult",
  "Microsoft-Exchange-ActiveMonitoring/ResponderResult",
  "Microsoft-Exchange-ActiveMonitoring/MaintenanceResult",
  "Microsoft-Exchange-DxStoreHA/Server"
)

$exchangeFindings = @{}
foreach ($channel in $channels) {
  try {
    $events = Get-WinEvent -LogName $channel -MaxEvents 1000 | Where-Object {
      $_.LevelDisplayName -eq "Error" -or
      $_.Message -match ($exchangeErrorPatterns + "|" + $exchangeWarningPatterns)
    }

    foreach ($event in $events) {
      $msg = $event.Message -replace '\s+', ' '
      if ($msg.Length -gt 200) {
        $cleanMsg = $msg.Substring(0,200)
      } else {
        $cleanMsg = $msg
      }
      $timestamp = $event.TimeCreated
      $severity = ""
      if ($msg -match $exchangeErrorPatterns) { $severity = "Error" }
      elseif ($msg -match $exchangeWarningPatterns) { $severity = "Warning" }

      if ($severity) {
        if (-not $exchangeFindings.ContainsKey($cleanMsg)) {
          $exchangeFindings[$cleanMsg] = @{
            Count = 1; FirstSeen = $timestamp; LastSeen = $timestamp;
            Severity = $severity; Channel = $channel
          }
        } else {
          $entry = $exchangeFindings[$cleanMsg]
          $entry.Count++
          $entry.LastSeen = $timestamp
        }
      }
    }
  } catch {
    $exchangeFindings["[ERROR] Failed to access $channel"] = @{
      Count = 1; FirstSeen = ""; LastSeen = "";
      Severity = "Error"; Channel = $channel
    }
  }
}

# === Build HTML Report ===
Write-Host "Generating HTML report..." -ForegroundColor Cyan
$html = @"
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
  <title>DAG Cluster Health Summary</title>
<style>
  body {
    font-family: 'Segoe UI', sans-serif;
    background-color: #fcfcfc;
    padding: 20px;
  }
  h1 {
    color: #005a9e;
    margin-bottom: 20px;
  }
  .section {
    margin-bottom: 25px;
  }
  .error { color: red; }
  .warning { color: orange; }
  .ok { color: green; }
  summary {
    font-size: 1.1em;
    font-weight: bold;
    cursor: pointer;
    padding: 5px;
    background-color: #eee;
    border: 1px solid #ccc;
  }
  details summary::after {
    content: " \25BC"; /* ▼ */
    float: right;
    font-size: 0.9em;
    color: #555;
  }
  details[open] summary::after {
    content: " \25B2"; /* ▲ */
  }
  .entry {
    margin-left: 20px;
    margin-bottom: 8px;
  }
  ul {
    padding-left: 20px;
  }
</style>
</head>
<body>
  <h1>DAG and Cluster Health Summary</h1>

  <div class="section">
    <details>
      <summary>Scanned Exchange Channels</summary>
      <ul>
"@

foreach ($channel in $channels) {
  $html += "<li>$channel</li>"
}

$html += @"
      </ul>
    </details>
  </div>

  <div class="section">
    <details>
      <summary>Cluster Log Summary</summary>
"@

if ($clusterFindings.Count -eq 0) {
  $html += '<div class="ok">No cluster warnings or errors detected.</div>'
} else {
  foreach ($entry in $clusterFindings.GetEnumerator()) {
    if ($entry.Value.Severity -eq "Error") {
      $colorClass = "error"
    } else {
      $colorClass = "warning"
    }
    $html += "<div class='entry $colorClass'>[$($entry.Value.Source)]<br>
    $($entry.Key)<br>
    Occurrences: $($entry.Value.Count)<br>
    First: $($entry.Value.FirstSeen), Last: $($entry.Value.LastSeen)</div>"
  }
}

$html += @"
    </details>
  </div>

  <div class="section">
    <details>
      <summary>Exchange Event Summary</summary>
"@

if ($exchangeFindings.Count -eq 0) {
  $html += '<div class="ok">No Exchange errors or warnings found.</div>'
} else {
  foreach ($entry in $exchangeFindings.GetEnumerator()) {
    if ($entry.Value.Severity -eq "Error") {
      $colorClass = "error"
    } else {
      $colorClass = "warning"
    }
    $html += "<div class='entry $colorClass'>[$($entry.Value.Channel)]<br>
    $($entry.Key)<br>
    Occurrences: $($entry.Value.Count)<br>
    First: $($entry.Value.FirstSeen), Last: $($entry.Value.LastSeen)</div>"
  }
}

$html += @"
    </details>
  </div>
</body>
</html>
"@

# === Write to File ===
$html | Out-File -FilePath $htmlPath -Encoding UTF8
Write-Host "DAG summary report generated at: $htmlPath" -ForegroundColor Green
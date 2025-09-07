<#
.SYNOPSIS
Monitoring a DAG using Test-ReplicationHealth.

.DESCRIPTION
This script runs health checks across all members of a DAG, parses results, and sends alerts if any component fails.

.OUTPUT
Alerts are generated if any DAG member of component is found to be unhealthy or failed.

.NOTES
Replace the values below with those appropriate for your organization. You can also modify the script to log these results to a file, or schedule the script with Task Scheduler to run regularly.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is excerpted from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll
#>

# Configure email settings
$smtpServer = "mail.msexchangese.com"
$from = "DAGMonitor@msexchangese.com"
$to = "scott@msexchangese.com"
$subject = "DAG Health Check Alert"
$body = ""
$failedServers = @()

# Run health check on each DAG member
Get-DatabaseAvailabilityGroup | ForEach-Object {
  $dag = $_
  $dag.Servers | ForEach-Object {
    $server = $_.Name
    $results = Test-ReplicationHealth -Identity $server
    $failedChecks = $results | Where-Object { $_.Result -eq "Failed" }

    if ($failedChecks.Count -gt 0) {
      $failedServers += $server
      $body += "`n${server}:`n"
      $failedChecks | ForEach-Object {
        $body += " - $($_.Check) failed: $($_.Reason)`n"
      }
    }
  }
}

# Send alert if any failures are found
if ($failedServers.Count -gt 0) {
  Send-MailMessage -From $from -To $to -Subject $subject -Body $body -SmtpServer $smtpServer
} else {
  Write-Output "All DAG members passed health checks."
}
<#
.SYNOPSIS
This is an example script that illustrates how a command can also be turned into a script with comments, logging, and error handling.

.DESCRIPTION
This script enables mailbox auditing for the user "Ross Day" and configures auditing for the delegate actions "SendAs" and "SendOnBehalf". It logs the start, success, or failure of the operation to a specified log file using a custom function.

.OUTPUT
The output file is C:\Logs\MailboxAuditLog.txt.

.NOTES
Modify the output file and Identity for your environment.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is excerpted from the book "Microsoft Exchange Server Subscription Edition for Admins" by Scott Schnoll
#>

# Define the log file path
$LogFile = "C:\Logs\MailboxAuditLog.txt"

# Function to log messages
function Write-Log {
    param (
        [string]$Message
    )
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$TimeStamp - $Message" | Out-File -Append -FilePath $LogFile
}

# Define mailbox parameters using splatting
$MailboxParams = @{
    Identity      = "Ross Day"
    AuditDelegate = "SendAs", "SendOnBehalf"
    AuditEnabled  = $true
}

# Try to execute the command with error handling
try {
    Write-Log "Starting audit configuration for $($MailboxParams.Identity)"
    Set-Mailbox @MailboxParams -ErrorAction Stop
    Write-Log "Successfully updated mailbox audit settings for $($MailboxParams.Identity)"
} catch {
    Write-Log "ERROR: Failed to update mailbox audit settings for $($MailboxParams.Identity) - $_"
    Write-Error "Failed to update mailbox audit settings: $_"
}

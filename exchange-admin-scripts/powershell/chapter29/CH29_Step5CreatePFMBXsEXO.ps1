<#
.SYNOPSIS
Validating environment readiness for Exchange hybrid migration.

.DESCRIPTION
This script creates public folder mailboxes in Exchange Online for each public folder mailbox listed in PFMigrationmap.csv.

.OUTPUT
Public folder mailboxes are created in Exchange Online.

.NOTES
Run this script in Exchange Online PowerShell. HoldforMigration is set to True to for the primary mailbox to signal that you're migrating data into it and IsExcludedFromServingHierarchy is set to False to ensure the mailboxes participate in hierarchy replication.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll (ISBN: 9798262871872)
#>

# Import the migration mapping file
$mappings = Import-Csv PFMigrationmap.csv

# Identify the primary hierarchy mailbox
$primaryMailboxName = ($mappings | Where-Object FolderPath -eq "\" ).TargetMailbox

# Create the primary hierarchy mailbox
New-Mailbox -PublicFolder -Name $primaryMailboxName -HoldForMigration:$true -IsExcludedFromServingHierarchy:$false

# Create all other public folder mailboxes
($mappings | Where-Object TargetMailbox -ne $primaryMailboxName).TargetMailbox |
  Sort-Object -Unique |
  ForEach-Object {
    New-Mailbox -PublicFolder -Name $_ -IsExcludedFromServingHierarchy:$false
  }
<#
.SYNOPSIS
This script is used in cross-forest mailbox moves.

.DESCRIPTION
This script retrieves local and remote forest credentials (when there is forest trust between the remote forest and local forest) and then provisions a linked mail user in the local forest.

.OUTPUT
The user GregSmith@msexchangese.com will be added as a linked mail user in the nwnetworks.com forest.

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

$LocalCredentials = Get-Credential
$RemoteCredentials = Get-Credential
Prepare-MoveRequest.ps1 -Identity GregSmith@msexchangese.com -RemoteForestDomainController ad1.msexchangese.com -RemoteForestCredential $RemoteCredentials -LocalForestDomainController ad1.nwnetworks.com -LocalForestCredential $LocalCredentials -LinkedMailUser
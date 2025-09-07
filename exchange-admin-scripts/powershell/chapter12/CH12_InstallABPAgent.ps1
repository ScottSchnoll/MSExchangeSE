<#
.SYNOPSIS
Installing the ABP Routing Agent to use ABPs.

.DESCRIPTION
This script installs and enables the ABP routing agent that is needed when using Address Book Policies.

.OUTPUT
The ABP routing agent is installed on every Mailbox server and enabled in the organization.

.NOTES
Run this on every Mailbox server in the organization, except for the last command.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll (ISBN: 9798262871872)
#>

# Install the ABP routing agent
Install-TransportAgent -Name "ABP Routing Agent" -TransportAgentFactory "Microsoft.Exchange.Transport.Agent.AddressBookPolicyRoutingAgent.AddressBookPolicyRoutingAgentFactory" -AssemblyPath $env:ExchangeInstallPath\TransportRoles\agents\AddressBookPolicyRoutingAgent\Microsoft.Exchange.Transport.Agent.AddressBookPolicyRoutingAgent.dll

# Enable the ABP routing agent
Enable-TransportAgent "ABP Routing Agent"

# Restart the Microsoft Exchange Transport service
Restart-Service MSExchangeTransport

# Enable global ABP routing globally by running this ONCE on ANY Mailbox server
Set-TransportConfig -AddressBookPolicyRoutingEnabled $true
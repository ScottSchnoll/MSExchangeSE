<#
.SYNOPSIS
This script is used when deploying modern authentication using AD FS.

.DESCRIPTION
This script creates a Web API application for each URI (client namespace and Autodiscover).

.OUTPUT
Two applications are created; one for Autodiscover and one for the client namespace.

.NOTES
Replace URIs with your Exchange service FQDNs.

.AUTHOR
Scott Schnoll

.COPYRIGHT
# Copyright © 2025 Scott Schnoll. All Rights Reserved.
# This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.
#
# .SOURCE
This script is excerpted from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll
#>

# Set Exchange URIs
$exchangeServerServiceFqdns = @(
  "https://autodiscover.msexchangese.com/",
  "https://mail.msexchangese.com/"
)

# Issuance Transform Rules — Well-formatted as a multiline string
$issuanceTransformRules = @"
@RuleName = "ActiveDirectoryUserSID"
c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/primarysid"]
 => issue(claim = c);

@RuleName = "ActiveDirectoryUPN"
c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn"]
 => issue(claim = c);

@RuleName = "AppIDACR"
 => issue(Type = "appidacr", Value = "2");

@RuleName = "SCP - Impersonation"
 => issue(Type = "scp", Value = "user_impersonation");

@RuleName = "SCP - EAS"
 => issue(Type = "scp", Value = "EAS.AccessAsUser.All");

@RuleName = "SCP - EWS"
 => issue(Type = "scp", Value = "EWS.AccessAsUser.All");

@RuleName = "SCP - Offline Access"
 => issue(Type = "scp", Value = "offline_access");
"@

# Loop to register each Web API application
foreach ($fqdn in $exchangeServerServiceFqdns) { $guid = (New-Guid).ToString("N")
Add-AdfsWebApiApplication -Name "Outlook - Web API ($guid)" -ApplicationGroupIdentifier "Outlook" -Identifier $fqdn -IssuanceTransformRules $issuanceTransformRules -AccessControlPolicyName "Permit Everyone"
}

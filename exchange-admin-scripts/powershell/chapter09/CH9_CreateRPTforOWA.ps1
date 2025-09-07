<#
.SYNOPSIS
This script is used when deploying modern authentication using AD FS.

.DESCRIPTION
This script creates a relying party trust for OWA.

.OUTPUT
A relying part trust for OWA is created in AD FS.

.NOTES
Replace the Identifier and WSFedEndpoint with your organization's values.

.AUTHOR
Scott Schnoll

.COPYRIGHT
# Copyright © 2025 Scott Schnoll. All Rights Reserved.
# This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.
#
# .SOURCE
This script is excerpted from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll
#>

Add-AdfsRelyingPartyTrust -Name "OWA" -Notes "Trust for OWA virdir" -Identifier "https://mail.msexchangese.com/owa/" -WSFedEndpoint "https://mail.msexchangese.com/owa/" -IssuanceAuthorizationRules '@RuleTemplate = "AllowAllAuthzRule" => issue(Type = "http://schemas.microsoft.com/authorization/claims/permit", Value = "true");' -IssueOAuthRefreshTokensTo NoDevice
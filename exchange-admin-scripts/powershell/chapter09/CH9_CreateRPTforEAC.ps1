<#
.SYNOPSIS
This script is used when deploying modern authentication using AD FS.

.DESCRIPTION
This script creates a relying party trust for EAC.

.OUTPUT
A relying part trust for EAC is created in AD FS.

.NOTES
Replace the Identifier and WSFedEndpoint with your organization's values.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll (ISBN: 9798262871872)
#>

Add-AdfsRelyingPartyTrust -Name "EAC" -Notes "Trust for ECP virdir" -Identifier "https://mail.msexchangese.com/ecp/" -WSFedEndpoint "https://mail.msexchangese.com/ecp/" -IssuanceAuthorizationRules '@RuleTemplate = "AllowAllAuthzRule" => issue(Type = "http://schemas.microsoft.com/authorization/claims/permit", Value = "true");' -IssueOAuthRefreshTokensTo NoDevice
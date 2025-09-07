<#
.SYNOPSIS
This script is used when deploying modern authentication using AD FS.

.DESCRIPTION
This script grants AD FS application permissions to the Application Group named Outlook.

.OUTPUT
The Application Group named Outlook is assigned the appropriate application permissions in AD FS.

.NOTES
Change ApplicationGroupIdentifier to match your environment.

.AUTHOR
Scott Schnoll

.COPYRIGHT
# Copyright © 2025 Scott Schnoll. All Rights Reserved.
# This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.
#
# .SOURCE
This script is excerpted from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll
#>


$clientRoleIdentifier = @("f8d98a96-0999-43f5-8af3-69971c7bb423","d3590ed6-52b3-4102-aeff-aad2292ab01c")
(Get-AdfsWebApiApplication -ApplicationGroupIdentifier "Outlook") | ForEach-Object {
[string]$serverRoleIdentifier = $_.Identifier
foreach ($id in $clientRoleIdentifier) {
  Grant-AdfsApplicationPermission -ClientRoleIdentifier $id -
ServerRoleIdentifier $serverRoleIdentifier -ScopeNames 
"winhello_cert","email","profile","vpn_cert","logon_cert","user_impersonatio n","allatclaims","offline_access","EAS.AccessAsUser.All","EWS.AccessAsUser.A ll","openid","aza"
  }
}

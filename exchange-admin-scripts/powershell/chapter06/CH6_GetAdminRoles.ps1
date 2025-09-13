<#
.SYNOPSIS
Get the list of admin roles, their permissions, and available cmdlets and parameters.

.DESCRIPTION
This script creates a CSV file that contains all built-in admin roles, the role assignments for each role, and the cmdlets and parameters assigned to each role.

.OUTPUT
CSV file with admin roles and role assignments, as well as assigned cmdlets and parameters.

.NOTES
Provide an output path for CSVFilenameandPath.

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2025 Scott Schnoll. All Rights Reserved.
This script is provided for educational purposes and may be used or modified with attribution. If you use or adapt this script, please credit the original source.

.SOURCE
This script is from the book "The Admin's Guide to Microsoft Exchange Server Subscription Edition" by Scott Schnoll (ISBN: 9798262871872)
#>

# Provide an output path for the CSV file
$csvPath = <CSVFilenameandPath>

# Get all role groups
$roleGroups = Get-RoleGroup

# Build results
$results = foreach ($group in $roleGroups) {
  $groupName = $group.Name

  # Get admin roles assigned to each group
  $adminRoles = $group.Roles | Where-Object { $_ -notlike "My*" }
  foreach ($role in $adminRoles) {

    # Get cmdlets and parameters for each role
    Get-ManagementRole -Identity $role | Get-ManagementRoleEntry | ForEach-Object {
      [pscustomobject]@{
        RoleGroup = $groupName
        RoleAssignment = "$($groupName)\$($role)"
        RoleName = $role
        Cmdlet = $_.Name
        Parameters = if ($_.Parameters) { $_.Parameters -join "," } else { "" }
      }
    }
  }
}

# Export to CSV
$results | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
Write-Host "Admin roles export complete: $csvPath"

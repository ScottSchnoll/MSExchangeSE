<#
.SYNOPSIS
This script gathers server and mailbox licensing information as reported by Exchange Server.

.DESCRIPTION
This script uses CalCalculationV2.ps1 to collect all licensing data and then produces an HTML report from that data.

.OUTPUT
HTML report in the same folder from which the script is run.

.NOTES
Optionally modify the path to CalCalculationV2.ps1

.AUTHOR
Scott Schnoll

.COPYRIGHT
Copyright © 2026 Scott Schnoll. All Rights Reserved. If you use or adapt this script, please credit the original source.

.SOURCE
Companion script to the article "Tracking Exchange Server licenses in your organization" ().
#>

# Suppress verbose/debug globally (CalCalculation is very chatty)
$VerbosePreference = 'SilentlyContinue'
$DebugPreference   = 'SilentlyContinue'
$WarningPreference = 'SilentlyContinue'

# Path to CalCalculationV2.ps1
$calScript = ".\CalCalculationV2.ps1"

function Invoke-CalScript {
    param([string]$AccessLicenseType)

    # Suppress warnings/verbose/debug from CalCalculationV2.ps1
    $( & $calScript -AccessLicenseType $AccessLicenseType -ErrorAction SilentlyContinue -WarningAction SilentlyContinue) 2>$null 3>$null 4>$null 5>$null 6>$null
}

# Run CAL script for Summary
$calSummary = Invoke-CalScript -AccessLicenseType Summary -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
$TotalMailboxes      = $calSummary[0]
$TotalStandardCALs   = $calSummary[1]
$TotalEnterpriseCALs = $calSummary[2]
$JournalingUserCount = $calSummary[3]

# Run CAL script for mailbox lists
$standardMailboxes   = Invoke-CalScript -AccessLicenseType Standard -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
$enterpriseMailboxes = Invoke-CalScript -AccessLicenseType Enterprise -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

# Convert mailbox objects into hash sets
$standardSet   = $standardMailboxes.PrimarySmtpAddress
$enterpriseSet = $enterpriseMailboxes.PrimarySmtpAddress

function Get-PremiumFeatureFlags {
    param([string]$Mailbox)

    $mbx = Get-Mailbox -Identity $Mailbox -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    if (-not $mbx) {
        return [PSCustomObject]@{
            ManagedCustomFolder = $false
            PersonalArchive     = $false
            RetentionPolicy     = $false
            LegalHold           = $false
            ActiveSyncAdvanced  = $false
            Journaling          = $false
        }
    }

    # Managed Custom Folder
    $managed = $false
    if ($mbx.ManagedFolderMailboxPolicy) {
        $policy = Get-ManagedFolderMailboxPolicy $mbx.ManagedFolderMailboxPolicy -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        foreach ($folderId in $policy.ManagedFolderLinks) {
            $folder = Get-ManagedFolder $folderId -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if ($folder.FolderType -eq "ManagedCustomFolder") {
                $managed = $true
                break
            }
        }
    }

    # Personal Archive
    $archive = ($mbx.ArchiveState -eq "Local")

    # Retention Policy
    $retention = $false
    if ($mbx.RetentionPolicy) {
        $policy = Get-RetentionPolicy $mbx.RetentionPolicy -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        foreach ($tagId in $policy.RetentionPolicyTagLinks) {
            $tag = Get-RetentionPolicyTag $tagId -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if ($tag.Type -eq "Personal" -and $tag.RetentionAction -ne "MoveToArchive") {
                $retention = $true
                break
            }
        }
    }

    # Legal Hold
    $legal = $mbx.LitigationHoldEnabled

    # ActiveSync Advanced
    $activeSync = $false
    $cas = Get-CASMailbox -Identity $Mailbox -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    if ($cas -and $cas.ActiveSyncMailboxPolicy) {
        $policy = Get-MobileDeviceMailboxPolicy $cas.ActiveSyncMailboxPolicy -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        if (
            ($policy.AllowDesktopSync -eq $False) -or
            ($policy.AllowStorageCard -eq $False) -or
            ($policy.AllowCamera -eq $False) -or
            ($policy.AllowTextMessaging -eq $False) -or
            ($policy.AllowWiFi -eq $False) -or
            ($policy.AllowBluetooth -ne "Allow") -or
            ($policy.AllowIrDA -eq $False) -or
            ($policy.AllowInternetSharing -eq $False) -or
            ($policy.AllowRemoteDesktop -eq $False) -or
            ($policy.AllowPOPIMAPEmail -eq $False) -or
            ($policy.AllowConsumerEmail -eq $False) -or
            ($policy.AllowBrowser -eq $False) -or
            ($policy.AllowUnsignedApplications -eq $False) -or
            ($policy.AllowUnsignedInstallationPackages -eq $False) -or
            ($policy.ApprovedApplicationList -ne $null) -or
            ($policy.UnapprovedInROMApplicationList -ne $null)
        ) {
            $activeSync = $true
        }
    }

    # Journaling
    $journaling = $enterpriseSet -contains $Mailbox -and $JournalingUserCount -gt 0

    return [PSCustomObject]@{
        ManagedCustomFolder = $managed
        PersonalArchive     = $archive
        RetentionPolicy     = $retention
        LegalHold           = $legal
        ActiveSyncAdvanced  = $activeSync
        Journaling          = $journaling
    }
}

# Collect license assignment data (queries use real LicenseName)
$userReport = Get-ExchangeServerAccessLicense -WarningAction SilentlyContinue | ForEach-Object {
    $license = $_.LicenseName

    Get-ExchangeServerAccessLicenseUser -WarningAction SilentlyContinue -LicenseName $license |
    Select-Object @{
        Name = 'License Name'
        Expression = { $license }
    }, Name
}

# Assigned mailboxes
$assignedUsers = $userReport |
    Where-Object { $_.'License Name' -match 'Enterprise CAL|Standard CAL' } |
    Sort-Object 'License Name', Name

# Servers with product keys
$assignedServers = $userReport |
    Where-Object { $_.'License Name' -match 'Enterprise Edition|Standard Edition' } |
    Sort-Object 'License Name', Name

# Summary report
$report = Get-ExchangeServerAccessLicense -WarningAction SilentlyContinue | ForEach-Object {
    $license = $_.LicenseName
    $count   = @(Get-ExchangeServerAccessLicenseUser -WarningAction SilentlyContinue -LicenseName $license).Count

    [PSCustomObject]@{
        'License Name'  = $license
        'License Count' = $count
    }
}

# Build enriched mailbox licensing dataset
$enrichedUsers = foreach ($u in $assignedUsers) {
    $mbx   = $u.Name
    $flags = Get-PremiumFeatureFlags -Mailbox $mbx

    $bold = { param($v) if ($v) { "<b>True</b>" } else { "False" } }
    $isEnterprise = ($enterpriseSet -contains $mbx)

    [PSCustomObject]@{
        'License Name'          = $u.'License Name'
        'Mailbox'               = $mbx
        'Enterprise CAL'        = (& $bold $isEnterprise)
        'Managed Custom Folder' = & $bold $flags.ManagedCustomFolder
        'Personal Archive'      = & $bold $flags.PersonalArchive
        'Retention Policy'      = & $bold $flags.RetentionPolicy
        'Legal Hold'            = & $bold $flags.LegalHold
        'ActiveSync Advanced'   = & $bold $flags.ActiveSyncAdvanced
        'Journaling'            = & $bold $flags.Journaling
    }
}

function Export-LicenseReportHtml {
    param(
        [array]$Summary,
        [array]$Users,
        [array]$Servers,
        [string]$Path = ".\ExchangeServerLicenseReport.html"
    )

    $style = @"
<style>
body { font-family: Segoe UI, Arial; margin: 20px; background-color: #f5f5f5; }
h1, h2 { color: #2F5597; }
table { border-collapse: collapse; width: 95%; background-color: white; margin-bottom: 30px; }
th { background-color: #2F5597; color: white; padding: 8px; text-align: left; }
td { border: 1px solid #ddd; padding: 8px; }
tr:nth-child(even) { background-color: #f2f2f2; }
tr:hover { background-color: #e8f1fb; }
.enterprise-row { background-color: #fff8b3 !important; }
</style>
"@

    # Strip "2016" only in HTML
    $usersForHtml = $Users | ForEach-Object {
        [PSCustomObject]@{
            'License Name'          = ($_. 'License Name' -replace '2016','').Trim()
            'Mailbox'               = $_.Mailbox
            'Enterprise CAL'        = $_.'Enterprise CAL'
            'Managed Custom Folder' = $_.'Managed Custom Folder'
            'Personal Archive'      = $_.'Personal Archive'
            'Retention Policy'      = $_.'Retention Policy'
            'Legal Hold'            = $_.'Legal Hold'
            'ActiveSync Policy'     = $_.'ActiveSync Advanced'
            'Journaling'            = $_.'Journaling'
        }
    }

    $usersHtml = @()
    $usersHtml += "<h2>Mailbox License Assignment (with Premium Feature Flags)</h2>"
    $usersHtml += "<table><tr>"

    # License Name is now first column
    foreach ($col in $usersForHtml[0].psobject.Properties.Name) {
        $usersHtml += "<th>$col</th>"
    }
    $usersHtml += "</tr>"

    foreach ($row in $usersForHtml) {
        $isEnterprise = ($row.'Enterprise CAL' -like '*True*')
        $class = if ($isEnterprise) { "class='enterprise-row'" } else { "" }

        $usersHtml += "<tr $class>"
        foreach ($col in $row.psobject.Properties.Name) {
            $usersHtml += "<td>$($row.$col)</td>"
        }
        $usersHtml += "</tr>"
    }

    $usersHtml += "</table>"

    $summaryHtml = ($Summary | ForEach-Object {
        [PSCustomObject]@{
            'License Name'  = ($_. 'License Name' -replace '2016','').Trim()
            'License Count' = $_.'License Count'
        }
    }) | ConvertTo-Html -Fragment -PreContent "<h2>License Count Summary</h2>"

    $serversHtml = ($Servers | ForEach-Object {
        [PSCustomObject]@{
            'License Name' = ($_. 'License Name' -replace '2016','').Trim()
            'Name'         = $_.Name
        }
    }) | ConvertTo-Html -Fragment -PreContent "<h2>Servers with Product Keys</h2>"

    ConvertTo-Html `
        -Title "Exchange Server License Report" `
        -Head $style `
        -Body @(
            "<h1>Exchange Server License Report</h1>"
            "<p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>"
            $summaryHtml
            $usersHtml
            $serversHtml
        ) |
        Out-File -FilePath $Path -Encoding UTF8

    Write-Host ""
    Write-Host "Report successfully generated:" -ForegroundColor Green
    Write-Host "$Path" -ForegroundColor Yellow
}

Export-LicenseReportHtml `
    -Summary $report `
    -Users $enrichedUsers `
    -Servers $assignedServers

# Modified version of CalCalculation.ps1 that ships in the Bin folder on Mailbox servers.
# Only modification is suppression of warning messages about a deprecated cmdlet
# Modified by Scott Schnoll - July 7, 2026
# Required companion script for ExLicenseHTMLReport.ps1.

########################
##  Input parameters  ##
########################
[CmdletBinding(SupportsShouldProcess = $false, ConfirmImpact = "None", DefaultParameterSetName="Default")]
param
(
    [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
    [ValidateSet(15)]
    [int]
    $VersionMajor = 15,

    [Parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $true)]
    [ValidateSet("Summary", "Standard", "Enterprise")]
    [string]
    $AccessLicenseType = "Summary",

    [Parameter(Position = 2, Mandatory = $false, ValueFromPipeline = $true)]
    [ValidateSet("All", "Journaling", "ActiveSync", "UM","ManagedFolder", "RetentionPolicy", "PersonalArchive", "LegalHold", "DLP")]
    [string[]]
    $DebugCategory = "All",

    [Parameter(Position = 3, Mandatory = $false, ValueFromPipeline = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $DebugMailbox = $null
)

############################
## Script level variables ##
############################
$Script:TotalMailboxes = 0
$Script:TotalEnterpriseCALs = 0
$Script:OrgWideJournalingEnabled = $False
$Script:AllMailboxIDs = @{}
$Script:AllVersionMailboxIDs = @{}
$Script:EnterpriseCALMailboxIDs = @{}
$Script:JournalingUserCount = 0
$Script:JournalingMailboxIDs = @{}
$Script:JournalingDGMailboxMemberIDs = @{}
$Script:TotalStandardCALs = 0
$Script:VisitedGroups = @{}
$Script:DGStack = new-object System.Collections.Stack
$Script:UserMailboxFilter = "(RecipientTypeDetails -eq 'UserMailbox') -or (RecipientTypeDetails -eq 'SharedMailbox') -or (RecipientTypeDetails -eq 'LinkedMailbox')"

$Script:ManagedFolderMailboxPolicyWithCustomedFolder = @{}
$Script:RetentionPolicyWithPersonalTag = @{}
$Script:RetentionPolicyWithPersonalTagNonArchive = @{}
$Script:ActiveSyncMailboxPolicyWithECALFeature = @{}
$Script:DebugMailboxGuid = $null
$Script:bacupErrorActionPreference = "Continue"

#######################
## Exception handler ##
#######################
# Error handling in this script:
# 1. If any error happend, let's just stop the rest since all the data will be marked as failed if one error happened. So $ErrorActionPreference is set to 'Stop'
# 2. If -ErrorAction SilentlyContinue is specified, which means any errors during that cmdlet ared not considered as error, but $error still records them, so make sure
#    $error.Clear() is called after cmdlet with -ErrorAction SilentlyContinue

# Trap block
trap
{
    Restore-EnvironmentVariable
    exit
}

####################
## Log functions  ##
####################
# Log when verbose is on
function Log-Info([string] $info)
{
    Write-Verbose (FormatEntry $info)
}

# Log when debug is on
function Log-Debug([string] $info)
{
    Write-Debug (FormatEntry $info)
}

# Log enter when verbose is on
function Log-Enter([string] $name)
{
    Log-Info "$name : Beginning processing"
}

# Log exit when verbose in on
function Log-Exit([string] $name)
{
    Log-Info "$name : Ending processing"
}

# Format log entry
function FormatEntry([string] $info)
{
    return "[{0} UTC] {1}" -F $(get-date).ToUniversalTime().ToString("HH:mm:ss.4d"), $info
}

######################
## Output functions ##
######################
# Output objects to caller
function Output-Report
{
    if ($Script:AccessLicenseType -eq "Summary")
    {
        write-output $Script:TotalMailboxes
        write-output $Script:TotalStandardCALs
        write-output $Script:TotalEnterpriseCALs
        Write-output $Script:JournalingUserCount
    }
    elseif ($Script:AccessLicenseType -eq "Standard")
    {
        $Script:AllMailboxIDs.Values | foreach {
            Write-output $_
        }
    }
    elseif ($Script:AccessLicenseType -eq "Enterprise")
    {
        $Script:EnterpriseCALMailboxIDs.Values | foreach {
            Write-output $_
        }
    }
    else
    {
        Throw "AccessLicenseType: $Script:AccessLicenseType is not supported."
    }
}

####################################
## Helper functions for Debugging ##
####################################
# Function that checks if we should process for this category
function Process-Category([string] $category)
{
    if (($Script:DebugCategory -contains "All") -or ($Script:DebugCategory -contains $category))
    {
        Log-Info "Will process category $category"

        return $true
    }
    else
    {
        Log-Info "Will Ignore category $category"

        return $false
    }
}

# Set debug mailbox guid by its address
function Set-DebugMailboxGuid
{
    if (($Script:DebugMailbox -eq $null) -or ($Script:DebugMailbox -eq ""))
    {
        $Script:DebugMailboxGuid = $null
    }
    elseif ($Script:DebugMailbox -ieq "All")
    {
        $Script:DebugMailboxGuid = "All"

        Log-Debug "DebugMailbox is set for all mailboxes. DebugMailbox info will only show with -Verbose on."
    }
    else
    {
        $mailbox = Get-Mailbox -Identity $Script:DebugMailbox
        if ($mailbox -eq $null)
        {
            Throw "The mailbox $Script:DebugMailbox does not exist."
        }

        $Script:DebugMailboxGuid = $mailbox.Guid

        Log-Debug "The Guid of DebugMailbox ($Script:DebugMailbox) is $Script:DebugMailboxGuid"
    }
}

# Determine if we should set and log this mailbox info or not.
function Process-Mailbox([string] $guid, [string] $varName)
{
    if ($Script:DebugMailboxGuid -eq $null)
    {
        # Not debugging. Don't log.
        return $true
    }
    elseif ($Script:DebugMailboxGuid -ieq "All")
    {
        # Debug all. Log all using verbose.
        Log-Info "DebugMailbox All (current: $guid) is in $varName"
        return $true
    }
    else
    {
        if ($guid -ieq $Script:DebugMailboxGuid)
        {
            # Debug one. Log when matched using debug
            Log-Debug "DebugMailbox ($guid) is in $varName"
            return $true
        }
        else
        {
            # Debug one. No match, so ignore it.
            Log-Info "DebugMailbox ($Script:DebugMailboxGuid) $guid is Ignored for $varName"
            return $false
        }
    }
}

######################
## Helper functions ##
######################
# Function that merges two hashtables
function Merge-Hashtables
{
    $Table1 = $args[0]
    $Table2 = $args[1]
    $Result = @{}
    
    if ($null -ne $Table1)
    {
        $Result += $Table1
    }

    if ($null -ne $Table2)
    {
        foreach ($entry in $Table2.GetEnumerator())
        {
            $Result[$entry.Key] = $entry.Value
        }
    }

    $Result
}

# Function that returns the value for output
function Get-MailboxOutputValue($mailbox)
{
    return $mailbox | Select PrimarySmtpAddress
}

# Help function for function Get-JournalingGroupMailboxMember to traverse members of a DG/DDG/group 
function Traverse-GroupMember
{
    $GroupMember = $args[0]
    
    if( $GroupMember -eq $null )
    {
        return
    }

    # Note!!! 
    # Only user, shared and linked mailboxes are counted. 
    # Resource mailboxes and legacy mailboxes are NOT counted.
    if ( ($GroupMember.RecipientTypeDetails -eq 'UserMailbox') -or
          ($GroupMember.RecipientTypeDetails -eq 'SharedMailbox') -or
          ($GroupMember.RecipientTypeDetails -eq 'LinkedMailbox') ) {
        # Journal one mailbox
        if (Process-Mailbox $GroupMember.Guid "JournalingMailboxIDs")
        {
            $Script:JournalingMailboxIDs[$GroupMember.Guid] = $null
        }
    } elseif ( ($GroupMember.RecipientType -eq "Group") -or ($GroupMember.RecipientType -like "Dynamic*Group") -or ($GroupMember.RecipientType -like "Mail*Group") ) {
        Log-Info "Push this DG/DDG/group into the stack. ($GroupMember.Guid)"
        $Script:DGStack.Push(@($GroupMember.Guid, $GroupMember.RecipientType))
    }
}

# Function that returns all mailbox members including duplicates recursively from a DG/DDG
function Get-JournalingGroupMailboxMember
{
    # Skip this DG/DDG if it was already enumerated.
    if ( $Script:VisitedGroups.ContainsKey($args[0]) ) {
        return
    }
    
    $Script:DGStack.Push(@($args[0],$args[1]))
    while ( $Script:DGStack.Count -ne 0 ) {
        $StackElement = $DGStack.Pop()
        
        $GroupGuid = $StackElement[0]
        $GroupRecipientType = $StackElement[1]

        if ( $Script:VisitedGroups.ContainsKey($GroupGuid) ) {
            # Skip this this DG/DDG if it was already enumerated.
            continue
        }
        
        Log-Info "Check the members of the current DG/DDG/group in the stack. ($GroupGuid)"
        if ( ($GroupRecipientType -like "Mail*Group") -or ($GroupRecipientType -eq "Group" ) ) {
            $varGroup = Get-Group $GroupGuid.ToString() -ErrorAction SilentlyContinue
            $error.Clear()
            if ( $varGroup -eq $Null )
            {
                return
            }
            
            $varGroup.members | foreach {    
                # Count users and groups which could be mailboxes.
                $varGroupMember = Get-User $_ -ErrorAction SilentlyContinue 
                if ( $varGroupMember -eq $Null ) {
                    $varGroupMember = Get-Group $_ -ErrorAction SilentlyContinue                  
                }
                $error.Clear()

                if ( $varGroupMember -ne $Null ) {
                    Traverse-GroupMember $varGroupMember
                }
            }
        } else {
            Log-Info "The current stack element is a DDG. ($GroupGuid)"
            $varGroup = Get-DynamicDistributionGroup $GroupGuid.ToString() -ErrorAction SilentlyContinue
            $error.Clear()

            if ( $varGroup -eq $Null )
            {
                return
            }

            Get-Recipient -RecipientPreviewFilter $varGroup.LdapRecipientFilter -OrganizationalUnit $varGroup.RecipientContainer -ResultSize 'Unlimited' -PropertySet 'Minimum' | foreach {
                Traverse-GroupMember $_
            }
        } 

        # Mark this DG/DDG as visited as it's enumerated.
        $Script:VisitedGroups[$GroupGuid] = $null
    }    
}

# Backup and set powershell environment variable
function BackupSet-EnvironmentVariable
{
    $Script:bacupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Stop"
}

# Restore powershell environment variable
function Restore-EnvironmentVariable
{
    $ErrorActionPreference = $Script:bacupErrorActionPreference
}

########################################
## Calculate Standard CAL functions   ##
########################################
#
# Calc total # of mailboxes
#
function Calc-AllMaiboxes
{
    Log-Enter $MyInvocation.MyCommand

    Log-Info "Calc-AllMaiboxes: Only user, shared and linked mailboxes are counted. Resource mailboxes, legacy mailboxes and team mailboxes are NOT counted."
    Log-Info "UserMailboxFilter : $UserMailboxFilter"
    Get-Recipient -ResultSize 'Unlimited' -Filter $UserMailboxFilter -PropertySet 'Minimum' | foreach {
        $Mailbox = $_
        if ($Mailbox.ExchangeVersion.ExchangeBuild.Major -eq $Script:VersionMajor) {
            if (Process-Mailbox $Mailbox.Guid "AllMailboxIDs")
            {
                $Script:AllMailboxIDs[$Mailbox.Guid] = Get-MailboxOutputValue $Mailbox
                $Script:TotalMailboxes++
            }
        }

        if (Process-Mailbox $Mailbox.Guid "AllVersionMailboxIDs")
        {
            $Script:AllVersionMailboxIDs[$Mailbox.Guid] = Get-MailboxOutputValue $Mailbox
        }
    }
    Log-Debug "AllVersionMailboxIDs count is: $($AllVersionMailboxIDs.Count)"
    Log-Debug "Calc TotalMailboxs is: $Script:TotalMailboxes"
    Log-Exit $MyInvocation.MyCommand
}

####################################################
## Cache functions for Enterprise CAL Calculation ##
####################################################
#
# Cache for ManagedFolder
#
function Cache-ForManagedFolder
{
    Log-Enter $MyInvocation.MyCommand

	try
	{
		if (Process-Category "ManagedFolder")
		{
			# Setup cache for MRM to reduce task call times.
			Get-ManagedFolderMailboxPolicy | foreach {
				foreach ($FolderId in $_.ManagedFolderLinks)
				{
					$ManagedFolder = Get-ManagedFolder $FolderId
					if ($ManagedFolder.FolderType -eq "ManagedCustomFolder")
					{
						if (Process-Mailbox $_.Guid "ManagedFolderMailboxPolicyWithCustomedFolder")
						{
							$Script:ManagedFolderMailboxPolicyWithCustomedFolder[$_.Guid] = $null
							break
						}
					}
				}
			}

			Log-Debug "Cached ManagedFolderMailboxPolicyWithCustomedFolder count is: $($Script:ManagedFolderMailboxPolicyWithCustomedFolder.Count)"
		}
	}
	catch
	{
        Log-Debug "Cached ManagedFolderMailboxPolicyWithCustomedFolder failed"
	}

    Log-Exit $MyInvocation.MyCommand
}

#
# Cache for RetentionPolicy
#
function Cache-ForRetentionPolicy
{
    Log-Enter $MyInvocation.MyCommand

    if (Process-Category "RetentionPolicy")
    {
        $retentionPolicies = Get-RetentionPolicy
        $retentionPolicies | foreach {
            foreach ($PolicyTagID in $_.RetentionPolicyTagLinks) {
                $RetentionPolicyTag = Get-RetentionPolicyTag $PolicyTagID
                if ($RetentionPolicyTag.Type -eq "Personal")
                {
                    if (Process-Mailbox $_.Guid "RetentionPolicyWithPersonalTag")
                    {
                        $Script:RetentionPolicyWithPersonalTag[$_.Guid] = $null
                    }

                    if ($RetentionPolicyTag.RetentionAction -ne "MoveToArchive")
                    {
                        if (Process-Mailbox $_.Guid "RetentionPolicyWithPersonalTagNonArchive")
                        {
                            $Script:RetentionPolicyWithPersonalTagNonArchive[$_.Guid] = $null
                        }
                        break;
                    }
                }
            }
        }

        Log-Debug "Cached RetentionPolicyWithPersonalTag count is: $($Script:RetentionPolicyWithPersonalTag.Count)"
        Log-Debug "Cached RetentionPolicyWithPersonalTagNonArchive count is: $($Script:ActiveSyncMailboxPolicyWithECALFeature.Count)"
    }

    Log-Exit $MyInvocation.MyCommand
}

#
# Cache for ActiveSync
#
function Cache-ForActiveSync
{
    Log-Enter $MyInvocation.MyCommand

    if (Process-Category "ActiveSync")
    {
        # Setup cache to reduce Get-ActiveSyncMailboxPolicy.
        Get-ActiveSyncMailboxPolicy -WarningAction SilentlyContinue | foreach {
            $ASPolicy = $_
            if (($ASPolicy.AllowDesktopSync -eq $False) -or 
                    ($ASPolicy.AllowStorageCard -eq $False) -or
                    ($ASPolicy.AllowCamera -eq $False) -or
                    ($ASPolicy.AllowTextMessaging -eq $False) -or
                    ($ASPolicy.AllowWiFi -eq $False) -or
                    ($ASPolicy.AllowBluetooth -ne "Allow") -or
                    ($ASPolicy.AllowIrDA -eq $False) -or
                    ($ASPolicy.AllowInternetSharing -eq $False) -or
                    ($ASPolicy.AllowRemoteDesktop -eq $False) -or
                    ($ASPolicy.AllowPOPIMAPEmail -eq $False) -or
                    ($ASPolicy.AllowConsumerEmail -eq $False) -or
                    ($ASPolicy.AllowBrowser -eq $False) -or
                    ($ASPolicy.AllowUnsignedApplications -eq $False) -or
                    ($ASPolicy.AllowUnsignedInstallationPackages -eq $False) -or
                    ($ASPolicy.ApprovedApplicationList -ne $null) -or
                    ($ASPolicy.UnapprovedInROMApplicationList -ne $null))
                    {
                        if (Process-Mailbox $ASPolicy.Guid "ActiveSyncMailboxPolicyWithECALFeature")
                        {
                            $Script:ActiveSyncMailboxPolicyWithECALFeature[$ASPolicy.Guid] = $null
                        }
                    }
        }

        Log-Debug "Cached ActiveSyncMailboxPolicyWithECALFeature count is: $($Script:ActiveSyncMailboxPolicyWithECALFeature.Count)"
    }

    Log-Exit $MyInvocation.MyCommand
}

###############################################
## Calculate Enterprise CAL (ECAL) functions ##
###############################################
#
# Per-org Enterprise CALs
#
function Calc-ECALForOrg
{
    Log-Enter $MyInvocation.MyCommand

    $ret = $false

    # Consider this belongs to DLP
    if (Process-Category "DLP")
    {
        # If any RMS transport rule is defined, all mailboxes in the org are counted as Enterprise CALs.
        foreach($rule in Get-TransportRule)
        {
            if ($rule.ApplyRightsProtectionTemplate -ne $null) {
                $Script:TotalEnterpriseCALs = $Script:TotalMailboxes
                $Script:EnterpriseCALMailboxIDs = $Script:AllMailboxIDs

                # All mailboxes are counted as Enterprise CALs
                $ret = $true
                break;
            }
        }

        Log-Debug "Calc DLP count is: $Script:TotalEnterpriseCALs"
    }

    Log-Exit $MyInvocation.MyCommand

    return $ret
}

#
# Calculate Enterprise CAL users for UM, MRM Managed Custom Folder, and advanced ActiveSync policy and Legal Hold
# AVOID call task directly in the loop which can task consuming with large organization.
#
function Calc-ECALForMultiple
{
    Log-Enter $MyInvocation.MyCommand

    if ((Process-Category "UM") -or
        (Process-Category "PersonalArchive") -or
        (Process-Category "RetentionPolicy") -or
        (Process-Category "ManagedFolder") -or
        (Process-Category "LegalHold"))
    {
        $UMCount = 0
        $PersonalArchiveCount = 0
        $RetentionPolicyCount = 0
        $ManagedFolderCount = 0
        $LegalHoldCount = 0

        # AVOID call task directly in the loop which can task consuming with large organization.
        Get-Recipient -ResultSize 'Unlimited' -Filter $UserMailboxFilter -PropertySet 'ConsoleLargeSet' | foreach {  
            $Mailbox = $_
            if ($Mailbox.ExchangeVersion.ExchangeBuild.Major -eq $Script:VersionMajor)
            {
                # UM usage classifies the user as an Enterprise CAL   
                if ((Process-Category "UM") -and $Mailbox.UMEnabled)
                {
                    if (Process-Mailbox $Mailbox.Guid "UMEnabled")
                    {
                        $UMCount++
                        $Script:EnterpriseCALMailboxIDs[$Mailbox.Guid] = Get-MailboxOutputValue $Mailbox
                        return
                    }
                }

                # LOCAL Archive Mailbox classifies the user as an Enterprise CAL
                if ((Process-Category "PersonalArchive") -and ($Mailbox.ArchiveState -eq "Local"))
                {
                    if (Process-Mailbox $Mailbox.Guid "PersonalArchive")
                    {
                        $PersonalArchiveCount++
                        $Script:EnterpriseCALMailboxIDs[$Mailbox.Guid] = Get-MailboxOutputValue $Mailbox
                        return
                    }
                }
        
                # Retention Policy classifies the user as an Enterprise CAL
                if ((Process-Category "RetentionPolicy") -and
                    ($Mailbox.RetentionPolicy -ne $null) -and
                    $Script:RetentionPolicyWithPersonalTag.Contains($Mailbox.RetentionPolicy.ObjectGuid))
                {
                    # For online archive, we will not consider it as ECAL if it's caused by MoveToAchiveTag
                    if (($Mailbox.ArchiveState -eq "HostedProvisioned") -or ($Mailbox.ArchiveState -eq "HostedPending"))
                    {
                        if ($Script:RetentionPolicyWithPersonalTagNonArchive.Contains($Mailbox.RetentionPolicy.ObjectGuid))
                        {
                            if (Process-Mailbox $Mailbox.Guid "RetentionPolicy")
                            {
                                $RetentionPolicyCount++
                                $Script:EnterpriseCALMailboxIDs[$Mailbox.Guid] = Get-MailboxOutputValue $Mailbox
                                return
                            }
                        }
                    }
                    else
                    {
                        if (Process-Mailbox $Mailbox.Guid "RetentionPolicy")
                        {
                            $RetentionPolicyCount++
                            $Script:EnterpriseCALMailboxIDs[$Mailbox.Guid] = Get-MailboxOutputValue $Mailbox
                            return
                        }
                    }
                }

                # MRM Managed Custom Folder usage classifies the user as an Enterprise CAL
                if ((Process-Category "ManagedFolder") -and
                    ($Mailbox.ManagedFolderMailboxPolicy -ne $null) -and           
                    ($Script:ManagedFolderMailboxPolicyWithCustomedFolder.Contains($Mailbox.ManagedFolderMailboxPolicy.ObjectGuid)))
                {
                    if (Process-Mailbox $Mailbox.Guid "ManagedFolderMailboxPolicy")
                    {
                        $ManagedFolderCount++
                        $Script:EnterpriseCALMailboxIDs[$Mailbox.Guid] = Get-MailboxOutputValue $Mailbox
                        return						
                    }
                }

                # LitigationHoldEnabled Mailbox classifies the user as an Enterprise CAL
                if ((Process-Category "LegalHold") -and $Mailbox.LitigationHoldEnabled)
                {
                    if (Process-Mailbox $Mailbox.Guid "LitigationHoldEnabled")
                    {
                        $LegalHoldCount++
                        $Script:EnterpriseCALMailboxIDs[$Mailbox.Guid] = Get-MailboxOutputValue $Mailbox
                        return
                    }
                }
            }
        }

        Log-Debug "Calc UM count is: $UMCount"
        Log-Debug "Calc PersonalArchive count is: $PersonalArchiveCount"
        Log-Debug "Calc RetentionPolicy coutn is: $RetentionPolicyCount"
        Log-Debug "Calc ManagedFolder count is: $ManagedFolderCount"
        Log-Debug "Calc LegalHold count is: $LegalHoldCount"
    }

    Log-Exit $MyInvocation.MyCommand
}

#
# Calculate Enterprise CAL users for ActiveSync
#
function Calc-ECALForActiveSync
{
    Log-Enter $MyInvocation.MyCommand

    if (Process-Category "ActiveSync")
    {
        $ActiveSyncCount = 0

        Get-CASMailbox -ResultSize 'Unlimited' -Filter 'ActiveSyncEnabled -eq $true' | foreach {
            $CASMailbox = $_
            if (($CASMailbox.ActiveSyncMailboxPolicy -ne $null) -and $Script:ActiveSyncMailboxPolicyWithECALFeature.Contains($CASMailbox.ActiveSyncMailboxPolicy.ObjectGuid))
            {
                if ($Script:AllMailboxIDs.Contains($CASMailbox.Guid))
                {
                    if (Process-Mailbox $CASMailbox.Guid "ActiveSync")
                    {
                        $ActiveSyncCount++
                        $Script:EnterpriseCALMailboxIDs[$CASMailbox.Guid] = Get-MailboxOutputValue $CASMailbox
                    }
                }
            }
        }

        Log-Debug "Calc ActiveSyn count is: $ActiveSyncCount"
    }

    Log-Exit $MyInvocation.MyCommand
}


#
# Calculate Enterprise CAL users for Journaling
#
function Calc-ECALForJournaling
{
    Log-Enter $MyInvocation.MyCommand

    if (Process-Category "Journaling")
    {
        # Check all journaling mailboxes(include all version) for all journaling rules, and count current version mailbox as Enterprise CALs.
        foreach ($JournalRule in Get-JournalRule){
            # There are journal rules in the org.

            if ( $JournalRule.Recipient -eq $Null ) {
                Log-Debug "One journaling rule journals the whole org (all mailboxes require ECALs)"

                $Script:OrgWideJournalingEnabled = $True
                $Script:JournalingUserCount = $Script:AllVersionMailboxIDs.Count
                $Script:TotalEnterpriseCALs = $Script:TotalMailboxes

                break
            } else {
                $RecipientFilter = "((PrimarySmtpAddress -eq '" + $JournalRule.Recipient + "'))"
                Log-Info "RecipientFilter: $RecipientFilter"

                $JournalRecipient = Get-Recipient -Filter ($RecipientFilter)

                if ( $JournalRecipient -ne $Null ) {
                    # Note!!!
                    # Remote mailbox is NOT count here since it's totally different story.
                    if (($JournalRecipient.RecipientTypeDetails -eq 'UserMailbox') -or
                        ($JournalRecipient.RecipientTypeDetails -eq 'SharedMailbox') -or
                        ($JournalRecipient.RecipientTypeDetails -eq 'LinkedMailbox') -or
                        ($JournalRecipient.RecipientTypeDetails -eq 'MailContact') -or
                        ($JournalRecipient.RecipientTypeDetails -eq 'PublicFolder') -or
                        ($JournalRecipient.RecipientTypeDetails -eq 'LegacyMailbox') -or
                        ($JournalRecipient.RecipientTypeDetails -eq 'RoomMailbox') -or
                        ($JournalRecipient.RecipientTypeDetails -eq 'EquipmentMailbox') -or
                        ($JournalRecipient.RecipientTypeDetails -eq 'MailForestContact') -or
                        ($JournalRecipient.RecipientTypeDetails -eq 'MailUser')) {

                        # Journal a mailbox
                        if (Process-Mailbox $_.Guid "JournalingMailboxIDs")
                        {
                            $Script:JournalingMailboxIDs[$JournalRecipient.Guid] = $null
                        }
                    } elseif ( ($JournalRecipient.RecipientType -like "Mail*Group") -or ($JournalRecipient.RecipientType -like "Dynamic*Group") ) {
                        # Journal a DG or DDG.
                        # Get all mailbox members for the current journal DG/DDG and add to JournalingDGMailboxMemberIDs.
                        Get-JournalingGroupMailboxMember $JournalRecipient.Guid $JournalRecipient.RecipientType
                    }
                }
            }
        }

        if ( !$Script:OrgWideJournalingEnabled ) {
            # No journaling rules journaling the entire org.
            # Get all journaling mailboxes
            $Script:JournalingMailboxIDs = Merge-Hashtables $Script:JournalingDGMailboxMemberIDs $Script:JournalingMailboxIDs
            $Script:JournalingUserCount = $Script:JournalingMailboxIDs.Count

            # Calculate Enterprise CALs as not all mailboxes are Enterprise CALs
            foreach ($journalingMailboxID in $Script:JournalingMailboxIDs.Keys) {
                if ($Script:AllMailboxIDs.Contains($journalingMailboxID)) {
                    if (Process-Mailbox $journalingMailboxID "Journaling")
                    {
                        $Script:EnterpriseCALMailboxIDs[$journalingMailboxID] = $AllMailboxIDs[$journalingMailboxID].PrimarySmtpAddress
                    }
                }
            }
        }

        Log-Debug "Cacl Journaling count is: $($Script:JournalingUserCount)"
    }

    Log-Exit $MyInvocation.MyCommand
}

########################
## Script starts here ##
########################
Log-Info "The script will only query for the info and not change any settings."
Log-Debug "The script will run with `"-VersionMajor $Script:VersionMajor -AccessLicenseType $Script:AccessLicenseType -DebugCategory $Script:DebugCategory -DebugMailbox $Script:DebugMailbox`""

Set-DebugMailboxGuid

BackupSet-EnvironmentVariable

Set-ADServerSettings -ViewEntireForest $true

Calc-AllMaiboxes
if ($TotalMailboxes -eq 0)
{
    Log-Debug "No mailboxes in the org."
}
else
{
    # All users are counted as Standard CALs
    $Script:TotalStandardCALs = $Script:TotalMailboxes

    if ($Script:AccessLicenseType -ieq "Standard")
    {
        Log-Debug "Standard CALs were already calculated. All mailboxes require ECALs."
    }
    else
    {
        Log-Info "Calculating ECALs."

        if (Calc-ECALForOrg)
        {
            Log-Debug "ECALs per org were already calculated. All mailboxes require ECALs."
        }
        else
        {
            Log-Info "Calculating ECALs per mailbox."

            Cache-ForManagedFolder
            Cache-ForRetentionPolicy
            Cache-ForActiveSync

            Calc-ECALForMultiple
            Calc-ECALForActiveSync
            Calc-ECALForJournaling
        }
    }
}

$Script:TotalEnterpriseCALs = $Script:EnterpriseCALMailboxIDs.Count
Restore-EnvironmentVariable

Log-Info "Writing output objects"
Output-Report
# SIG # Begin signature block
# MIInbgYJKoZIhvcNAQcCoIInXzCCJ1sCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCVUhwWnBF/zBrU
# eOFWX78Grupj7iiF4p+s1QFuR2aAgKCCDMkwggYEMIID7KADAgECAhMzAAACHPrN
# xZvoL37EAAAAAAIcMA0GCSqGSIb3DQEBCwUAMFcxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBD
# b2RlIFNpZ25pbmcgUENBIDIwMjQwHhcNMjYwNDE2MTg1OTQxWhcNMjcwNDE1MTg1
# OTQxWjB0MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYD
# VQQDExVNaWNyb3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IB
# DwAwggEKAoIBAQDVsZfgOKmM31HPfoWOoNEiw0SlCiIxUMC0I9NMWbucKOw/e9lP
# oAoehQVu6SG65V4EPzrYsnBnFPNoi4/HoOdjhz1qkrEt4I6tEcxXU6oOeY9zGveC
# /3iBeuhLYxM3M/PkcUoebF+Nednm8OkdSPoDu8imViHPQq/8CQUu0WRR4rE+dMRf
# rpVqfmNi2qWCX94T4MsepijGVkwE//tJg0ryAiYdHT34LSnlG/RSBZmQRGWZ5g8j
# qnKjRParSqMft1gvjuUTVgtWNZfgcLFSK5Wa0myrq8OPcgTGGsRgun+tnSS+IxDT
# xVsAPH1OzvPjwomguByhUe/OcvUN0D5Wmp7xAgMBAAGjggGqMIIBpjAOBgNVHQ8B
# Af8EBAMCB4AwHwYDVR0lBBgwFgYKKwYBBAGCN0wIAQYIKwYBBQUHAwMwHQYDVR0O
# BBYEFNoH7a2YDjOSwpkp6DHcmUS7J+0yMFQGA1UdEQRNMEukSTBHMS0wKwYDVQQL
# EyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxFjAUBgNVBAUT
# DTIzMDAxMis1MDc1NjkwHwYDVR0jBBgwFoAUf1k/VCHarU/vBeXmo9ctBpQSCDEw
# YAYDVR0fBFkwVzBVoFOgUYZPaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9w
# cy9jcmwvTWljcm9zb2Z0JTIwQ29kZSUyMFNpZ25pbmclMjBQQ0ElMjAyMDI0LmNy
# bDBtBggrBgEFBQcBAQRhMF8wXQYIKwYBBQUHMAKGUWh0dHA6Ly93d3cubWljcm9z
# b2Z0LmNvbS9wa2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwQ29kZSUyMFNpZ25pbmcl
# MjBQQ0ElMjAyMDI0LmNydDAMBgNVHRMBAf8EAjAAMA0GCSqGSIb3DQEBCwUAA4IC
# AQAUnEqhaRXe0T3hIJjvdQErEkrA/7bByjn6t5IArODkkRjzkYwtKMc2yYj2quaN
# rLutWw2YZcngKPy1b71YyDJQTy4NDRwaSh9Tw5thrk3NmcPrAHia5vtcBJ1CgtKK
# 7mQbIcQ22d/N3813ayCDDFewu1+jsZmX+r/aTEqaOM4TVxVtRSkuCy8nAXKuChOK
# Li/zA4XuH8iEYqIsj2YoNaeSxVmeGiERXpKdo3dDmYi0kO5w2D8VS4c3+9h6gElY
# BaAAg/dYErBg27qT3vv0zRDJhJufvCNylA8S7/+8H5E/PV5cng6na9VV/w9OV3qu
# uND6zdGa2EX38Glp50F9AIQk3p2xXmcvorDeM4XJ7UlWYBi6g80J1SSOQnInCYFE
# msfUNn3+1AaTJKSJL83quKArTac2pKhu0Yzzzrzo6HrsRiQKzpnRBb1/dMa6P3hz
# 75XbMRBctNsFhZC07WCmjExdLg2eHW5uV0TY8D5+6wozJf7vF3+WHkYPO85Z+BC6
# U4FkNbYNycZ9cE4j1tXRdyDCfml6c0HWPHjNVDObrv9lKt3qUqFpX38VCqVCyNOO
# 1UcXfQiVjJw32U2WUKZjt/neJKHEBsm9kFsLuWzkQ53+qcaSaytmsCnk2gOglrlD
# 5d3kKyvvAw+rzm0lT8K38P6PLxfZQHhu4W8dV7Av8N2ZmDCCBr0wggSloAMCAQIC
# EzMAAAA5O7Y3Gb8GHWcAAAAAADkwDQYJKoZIhvcNAQEMBQAwgYgxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBS
# b290IENlcnRpZmljYXRlIEF1dGhvcml0eSAyMDExMB4XDTI0MDgwODIwNTQxOFoX
# DTM2MDMyMjIyMTMwNFowVzELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29m
# dCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9zb2Z0IENvZGUgU2lnbmluZyBQ
# Q0EgMjAyNDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBANgBnB7jOMeq
# lRYHNa265v4IY9fH8TKhemHfPINe1gpLaV3dhg324WwH06LcHbpnsBukCDNitryo
# 0dtS/EW6I/yEL/bLSY8hKpbfQuWusBPr9qazYcDxCW/qnjb5JsI1s8bNOg3bVATv
# QVL4tcf03aTycsz8QeCdM0l/yHRObJ9QqazM1r6VPEOJ7LL+uEEb73w6QCuhs89a
# 1uv1zerOYMnsneRRwCbpyW11IcggU0cRKDDq1pjVJzIbIF6+oiXXbReOsgeI8zu1
# FyQfK0fVkaya8SmVHQ/tOf23mZ4W9k0Ri22QW9p3UgSC5OUDktKxxcCmGL6tXLfO
# GSWHIIV4YrTJTT6PNty5REojHJuZHArkF9VnHTERWoTjAzfI3kP+5b4alUdhgAZ7
# ttOu1bVnXfHaqPYl2rPs20ji03LOVWsh/radgE17es5hL+t6lV0eVHrVhsssROWJ
# uz2MXMCt7iw7lFPG9LXKGjsmonn2gotGdHIuEg5JnJMJVmixd5LRlkmgYRZKzhxS
# CwyoGIq0PhaA7Y+VPct5pCHkijcIIDm0nlkK+0KyepolcqGm0T/GYQRMhHJlGOOm
# VQop36wUVUYklUy++vDWeEgEo4s7hxN6mIbf2MSIQ/iIfMZgJxC69oukMUXCrOC3
# SkE/xIkgpfl22MM1itkZ35nNXkMolU1lAgMBAAGjggFOMIIBSjAOBgNVHQ8BAf8E
# BAMCAYYwEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0OBBYEFH9ZP1Qh2q1P7wXl5qPX
# LQaUEggxMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMA8GA1UdEwEB/wQFMAMB
# Af8wHwYDVR0jBBgwFoAUci06AjGQQ7kUBU7h6qfHMdEjiTQwWgYDVR0fBFMwUTBP
# oE2gS4ZJaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMv
# TWljUm9vQ2VyQXV0MjAxMV8yMDExXzAzXzIyLmNybDBeBggrBgEFBQcBAQRSMFAw
# TgYIKwYBBQUHMAKGQmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMv
# TWljUm9vQ2VyQXV0MjAxMV8yMDExXzAzXzIyLmNydDANBgkqhkiG9w0BAQwFAAOC
# AgEAFJQfOChP7onn6fLIMKrSlN1WYKwDFgAddymOUO3FrM8d7B/W/iQ6DxXsDn7D
# 5W4wMwYeLystcEqfkjz4NURRgazyMu5yRzQh4LqjA4tStTcJh1opExo7nn5PuPBY
# nbu0+THSuVHTe0VTTPVhily/piFrDo3axQ9P4C+Ol5yet+2gTfekICS5xS+cYfSI
# vgn0JksVBVMYVI5QFu/qhnLhsEFEUzG8fvv0hjgkO+lkpV9ty6GkN4vdnd7ya6Q6
# aR9y34aiM1qmxaxBi6OUnyNl6fkuun/diTFnYDLTppOkr/mg5WSfCiDVMNCxtj4w
# PKC5OmHm1DQIt/MNokbbH3UGsFP1QbzsLocuSqLCvH09Io3fDPTmscR9Y75G4qX7
# RTX8AdBPo0I6OEojf39zuFZt0qOHm65YWQE69cZM2ueE1MB05dNNgHK9gTE7zKvK
# /fg8B2qjW88MT/WF5V5uvZGtqa9FSL2RazArA+rDPuf6JGYz4HpgMZHB4S6szWSK
# YBv0VisCzfxgeU+dquXW9bd0auYlOB58DPcOYKdc3Se94g+xL4pcEhbB54JOgAkw
# YTu/9dLeH2pDqeJZAABVDWRQCaXfO5LgyKwKCLYXpigrZYCjUSBcr+Ve8PFWMhVT
# Ql0v4q8J/AUmQN5W4n101cY2L4A7GTQG1h32HHAvfQESWP0xghn7MIIZ9wIBATBu
# MFcxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# KDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMjQCEzMAAAIc
# +s3Fm+gvfsQAAAAAAhwwDQYJYIZIAWUDBAIBBQCgga4wGQYJKoZIhvcNAQkDMQwG
# CisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZI
# hvcNAQkEMSIEIMC8ZAS4ZcjfZCQ8ueMuzupY8jqrgFYm+dmNJ8EDEGxCMEIGCisG
# AQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBhodHRwOi8vd3d3
# Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEBBQAEggEAhKkv8l6o9+Tt1st1oZ16
# k6hr7Y/p5qjaQTngvyK8XytKu7EZZJ0Io+0/7gkowpU/UnUs8JrvwiVQHFaX8oSh
# Cp1ynwvD5fcsX2Xhq+3eXEGMiJoFaYiqVFY/xh/lc/oRyABCfVKvfmY5XrRW7cgg
# i/XtzRbHqOOfEiIhA25Xoa8jD/zhIENYoEEU2cs7dO2YOsj8RA9s2jB5j8e55PKb
# ACPPuiYQCItyeMll59fjBNyEF6Oh6rFmWNZsBRVq/7ZCueVNbhhRs3kOGIEbBC4x
# ZxCjsMVOfaSg5Y4y3hwWvnpBq9FplJKthdH01demcox5/NQvI9rlUxnSdfL7muXA
# IKGCF60wghepBgorBgEEAYI3AwMBMYIXmTCCF5UGCSqGSIb3DQEHAqCCF4YwgheC
# AgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFaBgsqhkiG9w0BCRABBKCCAUkEggFFMIIB
# QQIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFlAwQCAQUABCCPEyk9WARP5MPpm6Ov
# bgvMkFB2v1cQTpxWybCfnDOTuAIGaetOUTPnGBMyMDI2MDUxNDA1MjIwMS4wMTNa
# MASAAgH0oIHZpIHWMIHTMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3Rv
# bjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVyYXRpb25zIExpbWl0
# ZWQxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjo2QjA1LTA1RTAtRDk0NzElMCMG
# A1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaCCEfswggcoMIIFEKAD
# AgECAhMzAAACEUUYOZtDz/xsAAEAAAIRMA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29m
# dCBUaW1lLVN0YW1wIFBDQSAyMDEwMB4XDTI1MDgxNDE4NDgxM1oXDTI2MTExMzE4
# NDgxM1owgdMxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTAr
# BgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEnMCUG
# A1UECxMeblNoaWVsZCBUU1MgRVNOOjZCMDUtMDVFMC1EOTQ3MSUwIwYDVQQDExxN
# aWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIICIjANBgkqhkiG9w0BAQEFAAOC
# Ag8AMIICCgKCAgEAz7m7MxAdL5Vayrk7jsMo3GnhN85ktHCZEvEcj4BIccHKd/NK
# C7uPvpX5dhO63W6VM5iCxklG8qQeVVrPaKvj8dYYJC7DNt4NN3XlVdC/voveJuPP
# hTJ/u7X+pYmV2qehTVPOOB1/hpmt51SzgxZczMdnFl+X2e1PgutSA5CAh9/Xz5NW
# 0CxnYVz8g0Vpxg+Bq32amktRXr8m3BSEgUs8jgWRPVzPHEczpbhloGGEfHaROmHh
# VKIqN+JhMweEjU2NXM2W6hm32j/QH/I/KWqNNfYchHaG0xJljVTYoUKPpcQDuhH9
# dQKEgvGxj2U5/3Fq1em4dO6Ih04m6R+ttxr6Y8oRJH9ZhZ3sciFBIvZh7E2YFXOj
# P4MGybSylQTPDEFAtHHgpkskeEUhsPDR9VvWWhekhQx3qXaAKh+AkLmz/hpE3e0y
# +RIKO2AREjULJAKgf+R9QnNvqMeMkz9PGrjsijqWGzB2k2JNyaUYKlbmQweOabsC
# ioiY2fJbimjVyFAGk5AeYddUFxvJGgRVCH7BeBPKAq7MMOmSCTOMZ0Sw6zyNx4Uh
# h5Y0uJ0ZOoTKnB3KfdN/ba/eKHFeEhi3WqAfzTxiy0rMvhsfsXZK7zoclqaRvVl8
# Q48J174+eyriypY9HhU+ohgiYi4uQGDDVdTDeKDtoC/hD2Cn+ARzwE1rFfECAwEA
# AaOCAUkwggFFMB0GA1UdDgQWBBRifUUDwOnqIcvfb53+yV0EZn7OcDAfBgNVHSME
# GDAWgBSfpxVdAF5iXYP05dJlpxtTNRnpcjBfBgNVHR8EWDBWMFSgUqBQhk5odHRw
# Oi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NybC9NaWNyb3NvZnQlMjBUaW1l
# LVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcmwwbAYIKwYBBQUHAQEEYDBeMFwGCCsG
# AQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01p
# Y3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNydDAMBgNVHRMB
# Af8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMA4GA1UdDwEB/wQEAwIHgDAN
# BgkqhkiG9w0BAQsFAAOCAgEApEKdnMeIIUiU6PatZ/qbrwiDzYUMKRczC4Bp/XY1
# S9NmHI+2c3dcpwH2SOmDfdvIIqt7mRrgvBPYOvJ9CtZS5eeIrsObC0b0ggKTv2wr
# TgWG+qktqNFEhQeipdURNLN68uHAm5edwBytd1kwy5r6B93klxDsldOmVWtw/ngj
# 7knN09muCmwr17JnsMFcoIN/H59s+1RYN7Vid4+7nj8FcvYy9rbZOMndBzsTiosF
# 1M+aMIJX2k3EVFVsuDL7/R5ppI9Tg7eWQOWKMZHPdsA3ZqWzDuhJqTzoFSQShnZe
# nC+xq/z9BhHPFFbUtfjAoG6EDPjSQJYXmogja8OEa19xwnh3wVufeP+ck+/0gxNi
# 7g+kO6WaOm052F4siD8xi6Uv75L7798lHvPThcxHHsgXqMY592d1wUof3tL/eDaQ
# 0UhnYCU8yGkU2XJnctONnBKAvURAvf2qiIWDj4Lpcm0zA7VuofuJR1Tpuyc5p1ja
# 52bNZBBVqAOwyDhAmqWsJXAjYXnssC/fJkee314Fh+GIyMgvAPRScgqRZqV16dTB
# Yvoe+w1n/wWs/ySTUsxDw4T/AITcu5PAsLnCVpArDrFLRTFyut+eHUoG6UYZfj8/
# RsuQ42INse1pb/cPm7G2lcLJtkIKT80xvB1LiaNvPTBVEcmNSvFUM0xrXZXcYcxV
# XiYwggdxMIIFWaADAgECAhMzAAAAFcXna54Cm0mZAAAAAAAVMA0GCSqGSIb3DQEB
# CwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYD
# VQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAxMDAe
# Fw0yMTA5MzAxODIyMjVaFw0zMDA5MzAxODMyMjVaMHwxCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0
# YW1wIFBDQSAyMDEwMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA5OGm
# TOe0ciELeaLL1yR5vQ7VgtP97pwHB9KpbE51yMo1V/YBf2xK4OK9uT4XYDP/XE/H
# ZveVU3Fa4n5KWv64NmeFRiMMtY0Tz3cywBAY6GB9alKDRLemjkZrBxTzxXb1hlDc
# wUTIcVxRMTegCjhuje3XD9gmU3w5YQJ6xKr9cmmvHaus9ja+NSZk2pg7uhp7M62A
# W36MEBydUv626GIl3GoPz130/o5Tz9bshVZN7928jaTjkY+yOSxRnOlwaQ3KNi1w
# jjHINSi947SHJMPgyY9+tVSP3PoFVZhtaDuaRr3tpK56KTesy+uDRedGbsoy1cCG
# MFxPLOJiss254o2I5JasAUq7vnGpF1tnYN74kpEeHT39IM9zfUGaRnXNxF803RKJ
# 1v2lIH1+/NmeRd+2ci/bfV+AutuqfjbsNkz2K26oElHovwUDo9Fzpk03dJQcNIIP
# 8BDyt0cY7afomXw/TNuvXsLz1dhzPUNOwTM5TI4CvEJoLhDqhFFG4tG9ahhaYQFz
# ymeiXtcodgLiMxhy16cg8ML6EgrXY28MyTZki1ugpoMhXV8wdJGUlNi5UPkLiWHz
# NgY1GIRH29wb0f2y1BzFa/ZcUlFdEtsluq9QBXpsxREdcu+N+VLEhReTwDwV2xo3
# xwgVGD94q0W29R6HXtqPnhZyacaue7e3PmriLq0CAwEAAaOCAd0wggHZMBIGCSsG
# AQQBgjcVAQQFAgMBAAEwIwYJKwYBBAGCNxUCBBYEFCqnUv5kxJq+gpE8RjUpzxD/
# LwTuMB0GA1UdDgQWBBSfpxVdAF5iXYP05dJlpxtTNRnpcjBcBgNVHSAEVTBTMFEG
# DCsGAQQBgjdMg30BATBBMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wEwYDVR0lBAwwCgYIKwYB
# BQUHAwgwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGGMA8G
# A1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAU1fZWy4/oolxiaNE9lJBb186aGMQw
# VgYDVR0fBE8wTTBLoEmgR4ZFaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9j
# cmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3JsMFoGCCsGAQUF
# BwEBBE4wTDBKBggrBgEFBQcwAoY+aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3Br
# aS9jZXJ0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0yMy5jcnQwDQYJKoZIhvcNAQEL
# BQADggIBAJ1VffwqreEsH2cBMSRb4Z5yS/ypb+pcFLY+TkdkeLEGk5c9MTO1OdfC
# cTY/2mRsfNB1OW27DzHkwo/7bNGhlBgi7ulmZzpTTd2YurYeeNg2LpypglYAA7AF
# vonoaeC6Ce5732pvvinLbtg/SHUB2RjebYIM9W0jVOR4U3UkV7ndn/OOPcbzaN9l
# 9qRWqveVtihVJ9AkvUCgvxm2EhIRXT0n4ECWOKz3+SmJw7wXsFSFQrP8DJ6LGYnn
# 8AtqgcKBGUIZUnWKNsIdw2FzLixre24/LAl4FOmRsqlb30mjdAy87JGA0j3mSj5m
# O0+7hvoyGtmW9I/2kQH2zsZ0/fZMcm8Qq3UwxTSwethQ/gpY3UA8x1RtnWN0SCyx
# TkctwRQEcb9k+SS+c23Kjgm9swFXSVRk2XPXfx5bRAGOWhmRaw2fpCjcZxkoJLo4
# S5pu+yFUa2pFEUep8beuyOiJXk+d0tBMdrVXVAmxaQFEfnyhYWxz/gq77EFmPWn9
# y8FBSX5+k77L+DvktxW/tM4+pTFRhLy/AsGConsXHRWJjXD+57XQKBqJC4822rpM
# +Zv/Cuk0+CQ1ZyvgDbjmjJnW4SLq8CdCPSWU5nR0W2rRnj7tfqAxM328y+l7vzhw
# RNGQ8cirOoo6CGJ/2XBjU02N7oJtpQUQwXEGahC0HVUzWLOhcGbyoYIDVjCCAj4C
# AQEwggEBoYHZpIHWMIHTMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3Rv
# bjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVyYXRpb25zIExpbWl0
# ZWQxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjo2QjA1LTA1RTAtRDk0NzElMCMG
# A1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaIjCgEBMAcGBSsOAwIa
# AxUAKyp8q2VdgAq1VGkzd7PZwV6zNc2ggYMwgYCkfjB8MQswCQYDVQQGEwJVUzET
# MBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMV
# TWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1T
# dGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQsFAAIFAO2vgKowIhgPMjAyNjA1MTMy
# MjU4NTBaGA8yMDI2MDUxNDIyNTg1MFowdDA6BgorBgEEAYRZCgQBMSwwKjAKAgUA
# 7a+AqgIBADAHAgEAAgIkazAHAgEAAgISczAKAgUA7bDSKgIBADA2BgorBgEEAYRZ
# CgQCMSgwJjAMBgorBgEEAYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0G
# CSqGSIb3DQEBCwUAA4IBAQCMxkYJPNSFYq/IOmyiPDmwvq6CHM0ThBsiWVGKBcMM
# 8hnRdF2+bPKZPIKuUjwcKw2OFGRT2eY2gnFhcjQZnkeexXIGESAG8Vp2DPcLTDtC
# L56ZBbdfsPSRmNvTejhpKIkQOQ3wooIlYDHyoxT7Gnm4mWKcBqYtUAf5CaV+to2k
# kHJTzCfdparD43BzfKuNAcmU+TRTkd0lcu4Xw7BmXwaCFjCQ/0okSwIC/V1hHcQf
# OsYykdGY58SgY8smDiblJVn5FX1ZuU/g4m/2VPVTqcq1lUKiaoMP/w0XmokVCWoC
# dTv/sXwN5TiUpuu3xoO08KyXnBHqzZ9OCBGwqMAsE6rNMYIEDTCCBAkCAQEwgZMw
# fDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
# ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMd
# TWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAIRRRg5m0PP/GwAAQAA
# AhEwDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRAB
# BDAvBgkqhkiG9w0BCQQxIgQg19m1yaYmFnaqkc4j/uTSF4CxTCFXF5UYlzNc2MXT
# d6MwgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCAsrTOpmu+HTq1aXFwvlhjF
# 8p2nUCNNCEX/OWLHNDMmtzCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBD
# QSAyMDEwAhMzAAACEUUYOZtDz/xsAAEAAAIRMCIEIAS1RI55IXtu4Zf5KbfPB/zF
# J3wA7LhCapu1yT0xxveMMA0GCSqGSIb3DQEBCwUABIICAJ2UxYpVZl5gX3zgR+Sz
# uRH11j92eSgRmKZ4SwHQNhsDdZkTlc1Tr2ZlsatEfskS+yIFYXKdvNz1YdguRIbg
# 3ia8VRGCV9ExxvLfEzSlL7vExmJtSPnHZtOLByLNmUgtdjoFu7D3vAr1s7qfatNo
# FvyuFEnR6WZ2RSMeneb01wP+meAk6JAMngDOKfVHRLqhFcZSpXBqUvqaHJHbp43q
# b1HKF5AOZLGoS7mXabPYsU6rDnRD0FdZCsmI50adVNzQsKvwpPHbmyG0kcornCbf
# qI2k32b9++HVFtKZgJoXqGBZpk6qj303Ofmwf2kyndXyqbNVTREgR5rbHPDbYWZ5
# 26aE42LnEEHDn4t0+IaPPuVLLnw/JCMqjdbQYVdB+ZPx0Pm5VTe3ABUjOVUYwiqs
# 64PTlohilTDUaG9iZOgrIbUf5ldJ/Bcl6LMKC/Ribe1NeHGtKVzD6JK7bM3swzvZ
# i2moY/RtslVzjOXIuf0SFOujHWjnJxP6Ci7NXMbaPOGX51hmn3XnWKZXWHtq3ahY
# ynRAjUcPfIk3M7nhE8vIoeQyH/F9ANN+LafhEDV5I5YmfgncoA2XwCRMaW+grmbW
# 5gPsUqpnhD8N460iiIn2D0KYcBkFTROW/HTkzwwhd8PPhpbinfsA3SIlYF/TykpW
# oymNyAEwxUIcA8Go32UnMIEs
# SIG # End signature block
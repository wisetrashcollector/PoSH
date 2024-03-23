# DISCLAIMER: 
# Use This script at your own risk. The author is not liable for any damages or losses arising from it's use.
# By running/executing this script, you accept full responsibility for the results.
#
# If you have questions or suggestions, feel free to send me an email: todd@t15n.com 
# This is a complete rewrite of a script I ran at a previous employer (with improvements!) and might make your AD Admins happier.
# Though I'm not compensated to mention it, I recommend having Netwrix or similar software if you need sophisticated AD auditing.
#
# WHAT THIS SCRIPT DOES:
# AD ChangeTracker runs on an Active Directory server and removes all groups (except Domain Users, which is required) from users in 
# a specified OU and disables them. Live log lasts 60 days before archiving and can be stored where you want. A file is created for
# each modified user which contains their removed memberships. I find it's a fast way to answer questions when management asks why or
# when or what a previous user had access to in AD.
#
# SCRIPT REQUIREMENTS:
# Must be run with appropriate permissions on a local Active Directory server. You'll probably want to set it up using Task Scheduler.
#
# ENVIRONMENTAL VARIABLES
# OU path for users to be processed. Yours will be different, i.e.- Contoso.com would be DC=Contoso,DC=com
$OUTargetPath = "OU=disabledsubfoldername,OU=oufoldername,DC=mydomain,DC=com"
# Activity Logging & Output paths.
$OutputPath = "C:\Scripts\DisabledUserTracker\Users"
$ActivityLogDir = "C:\Scripts\DisabledUserTracker\ActivityLog"
# Log file name. After 60 days, the log will be saved as "old_activity_yyyymmddHHmmss.log".
$ActivityLogPath = "$ActivityLogDir\activity.log"


###### DO NOT MAKE CHANGES BELOW THIS LINE UNLESS YOU'RE SURE OF WHAT YOU'll BREAK. SCROLL TO END FOR MAIN SCRIPT. ######
###### UNCOMMENTING LINE 82 ADDS LOG ENTRIES FOR ACCOUNTS WITH NO EXISTING MEMBERSHIPS - NOT RECOMMENDED FOR MOST. ######

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
}

if (-not (Test-Path $ActivityLogDir)) {
    New-Item -ItemType Directory -Path $ActivityLogDir | Out-Null
}

# Check if the activity log is older than 60 days and archive if true.
if (Test-Path $ActivityLogPath) {
    $logAgeDays = (Get-Date).Subtract((Get-Item $ActivityLogPath).LastWriteTime).Days
    if ($logAgeDays -gt 60) {
        Rename-Item $ActivityLogPath -NewName "$ActivityLogDir\old_activity_$(Get-Date -Format 'yyyyMMddHHmmss').log"
    }
}

# Timestamp the activity log entry.
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"Script run at $date" | Out-File $ActivityLogPath -Append

# FUNCTIONS
Function Process-UserMemberships {
    Param (
        [string]$OUTargetPath,
        [string]$OutputPath,
        [string]$ActivityLogPath
    )

    # Get all users from $OUTargetPath
    $users = Get-ADUser -Filter * -SearchBase $OUTargetPath -Properties Enabled

    foreach ($user in $users) {
        $userName = $user.SamAccountName
        $dateStamp = Get-Date -Format "yyyyMMddHHmmss"
        $filePath = "$OutputPath\$userName-$dateStamp.csv"

        # Get group memberships excluding "Domain Users" and export to csv.
        $userGroups = Get-ADPrincipalGroupMembership $user | Where-Object { $_.Name -ne "Domain Users" }

        if ($userGroups) {
            $userGroups | Select-Object -Property Name | Export-Csv -Path $filePath -NoTypeInformation
            "${dateStamp}: Memberships for $userName exported to $filePath" | Out-File $ActivityLogPath -Append

            # Remove memberships except "Domain Users".
            foreach ($group in $userGroups) {
                Remove-ADGroupMember -Identity $group -Members $userName -Confirm:$false
                "${dateStamp}: Removed $userName from $group" | Out-File $ActivityLogPath -Append
            }
        }
        else {
            # Uncomment the next line if you want to blow up your logfile with explicit entries informing you of nonexistent group memberships.
            # "${dateStamp}: No memberships (excluding 'Domain Users') found for $userName" | Out-File $ActivityLogPath -Append
        }

        # Check if the user account is enabled before disabling
        if ($user.Enabled -eq $true) {
            Set-ADUser -Identity $userName -Enabled $false
            "${dateStamp}: Disabled account for $userName" | Out-File $ActivityLogPath -Append
        }
    }
}


###### MAIN SCRIPT ######
Process-UserMemberships -OUTargetPath $OUTargetPath -OutputPath $OutputPath -ActivityLogPath $ActivityLogPath







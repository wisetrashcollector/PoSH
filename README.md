DISCLAIMER:
Use This script at your own risk. The author is not liable for any damages or losses arising from it's use. By running/executing this script, you accept full responsibility for the results.

If you have questions or suggestions, feel free to send me an email: todd@t15n.com 

This is a complete rewrite of similar work I did at a prior employer, and it saved our AD admins a lot of time. 

WHAT THIS SCRIPT DOES:
This script leverages .csv formatted profile files to add Users or Computers to groups in Active Directory.

SCRIPT REQUIREMENTS:
 - Must be run with appropriate permissions on a local Active Directory server.
 - Separate .csv files are required for each profile; all profiles will be stored in the $ADProfilesPath folder.
 - When modifying users, specify the SAMAccountName (often the first part of someone's email address before the @ symbol).
 - Computer names must must have a $ at the end of the name or the Add-ADObjects cmdlet will fail the action.

PROFILE NAMING, FORMAT & LOCATION:
The list of profile choices is built on the fly and based on the file name listed in the profile directory. 
"UserProfile_Assistants.csv" is a User Profile.
"ComputerProfile_Default.csv" is a Computer Profile.

When modifying a computer, only files named 'ComputerProfile_' will be displayed.
When modifying a user, only files named 'UserProfile_' will be displayed.

Each Group name in your profile files should be on a separate line. No headers - just the name. Spaces inside a Group name are acceptable if they're part of the name, but don't have additional spaces at the beginning or end of a group name.

For an example, please see this readme at the top of the code...

<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2015 v4.2.86
	 Created on:   	7/17/2015 3:29 PM
	 Created by:   	DouglasFrancis
	 Organization: 	SnarkySysAdmin.com
	 Filename:     	90DayCleanup_V_0_2
	===========================================================================
	.DESCRIPTION
		Searches though all AD OU's except for Service accounts, Mail Global Groups, External Accounts, Exchange, Cisco, and Built in OUs.
		Looks for any account that has not been signed into in greater than 90 days excluding accounts created within the previous two weeks.
		These accounts are excluded so new hires do not get caught in the cleanup.
		Any accounts found that match the critera are disabled and moved to the Term30 OU.
#>

# Powershell transcription setup
# Create a filename based on a time stamp.
$Filename = ((Get-date).Month).ToString() + "-" +`
((Get-date).Day).ToString() + "-" +`
((Get-date).Year).ToString() + "-" +`
((Get-date).Hour).ToString() + "-" +`
((Get-date).Minute).ToString() + "-" +`
((Get-date).Second).ToString() + "-90DayCleanup" + ".txt"
# Set the storage path.
$Path = "C:\Scripts\PS Transcripts"
# Turn on PowerShell transcripting. 
Start-Transcript -Path "$Path\$Filename"

#Importing AD module
Import-Module ActiveDirectory

# Getting Users accounts that are not in the specific OU's and their last logon date
$Users = Get-ADUser -Properties LastLogonDate, created -Filter * | where { $_.distinguishedName -notmatch "OU=Service Accounts,OU=Accounts,OU=Corporate,DC=domain,DC=net" -and $_.distinguishedname -notmatch "OU=Mail Global Groups,OU=Groups,DC=domain,DC=net" -and $_.distinguishedname -notmatch "OU=External Accounts,DC=domain,DC=net" -and $_.distinguishedname -notmatch "CN=Microsoft Exchange System Objects,DC=domain,DC=net" -and $_.distinguishedname -notmatch "OU=Exchange Accounts,OU=Accounts,OU=Corporate,DC=domain,DC=net" -and $_.distinguishedname -notmatch "OU=Inst1,OU=Production,OU=Cisco_ICM,OU=Cisco,DC=domain,DC=net" -and $_.distinguishedname -notmatch "OU=Recipients,OU=ADCNoMigrate,DC=domain,DC=net" -and $_.distinguishedname -notmatch "OU=Term30,OU=Termed Accounts,DC=domain,DC=net" -and $_.distinguishedname -notmatch "CN=Users,DC=domain,DC=net" -and $_.distinguishedname -notmatch "CN=Builtin,DC=domain,DC=net" } #| Export-Csv C:\Scripts\Script_Results\90daysearchtest.csv

# Getting users that have not logged in greater than 90 days
$InactiveUsers = $Users | Where { $_.LastLogonDate -le $(Get-Date).AddDays(-90) -and $_.Created -le $(Get-Date).AddDays(-14)}

# Exporting the list of inactive users to CSV
$InactiveUsers | select name, LastLogonDate, created, distinguishedname | Export-Csv C:\Scripts\Script_Results\90users.csv -NoTypeInformation

# email that CSV file to helpdesk, security and server.
Send-MailMessage -From "InactiveUsersScript <InactiveUserScript@domain.com>" -To "domainitsupport@domain.com" -Cc "serverteam@domain.com", "infosec@domain.com", "ITSCSCTech@domain.com", "ITSCSCIDs@domain.com" -Subject "Users inactive- 90 days" -Body "Please see attatched CSV file" -Attachments "C:\Scripts\Script_Results\90users.csv" -SmtpServer "smtp.domain.net"


# Disabling each inactive AD account and moving it to the term30 OU


foreach ($user in $InactiveUsers)
{
	Disable-ADAccount -Identity $user -Confirm:$false 
	Get-ADUser $user | Move-ADObject -TargetPath "OU=Term30,OU=Termed Accounts,DC=domain,DC=net"
	
}
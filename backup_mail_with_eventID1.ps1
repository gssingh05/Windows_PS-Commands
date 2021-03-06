
<#
.SYNOPSIS
Script to log information about the most recent Windows Backup job.
.DESCRIPTION
Script will report via email or log file the following info about each item in the most recent backup job:
	Name
	Status
	Size
.EXAMPLE
To automate this script, setup two scheduled tasks.
	1)	Name: Backup Success Email Task
		Description: Notifies backup admin of scheduled backup successful completion
		Run whether user is logged on or not
		Trigger > On event > Log=Microsoft-Windows-Backup/Operational > Source=Backup > Event ID(s)=4
		Action: Start a Program
			Program: Powershell
			Arguments: -Command "C:\Scripts\WBJobReport.ps1" -ExecutionPolicy Bypass [-email and/or -log] -success
	2)	Name: Backup Failure Email Task
		Description: Notifies backup admin of scheduled backup failure
		Run whether user is logged on or not
		Trigger > On event > Log=Microsoft-Windows-Backup/Operational > Source=Backup > Event ID(s)= 5,8,9,17,22,49,50,52,100,517,518,521,527,528,544,545,546,561,564,612
		Action: Start a Program
			Program: Powershell
			Arguments: -Command "C:\Scripts\WBJobReport.ps1" -ExecutionPolicy Bypass [-email and/or -log]
	Task setup adapted from: http://www.bluecompute.co.uk/blogposts/configure-email-notification-for-windows-server-backup/
.PARAMETER success
	If you do not specify the success parameter, then script assumes the job failed. If calling from a scheduled task, then this would be if event ID 4 triggered the script.
.PARAMETER email
	If you leave out this parameter, then you will not get an email.
.PARAMETER log
	If you leave out this parameter, then no HTML log file will be saved to disk. Specify the folder in which you want the file saved.
.PARAMETER to
	You can specify a default address for the script below, but at times you may want to bypass that and send to a different address. If you don't use this parameter, then the default address configured below is used.
.PARAMETER from
	The address to send from. Same usage as TO parameter.
.PARAMETER SMTPServer
	Default configured below is used if nothing is specified.
#>
Param(
	[switch]$success, #If you do not use this flag, then script assumes backup failed.
	[switch]$email, #send email to 'to' address.
	[string]$log = '', #UNC or local path to save HTML report.
	[string]$to = "IT Department <you@domain.com>", #Default value goes here. Other value can be specified when calling script.
	[string]$from = "BackupAdmin <you@domain.com>", #Default value goes here. Other value can be specified when calling script.
	[string]$SMTPServer = "server.domain.com" #Default value goes here. Other value can be specified when calling script.
)

#== Switch bytes to most appropriate unit (rounded to 2 decimal points) ==
Function FormatBytes
{
	Param
	(
		[System.Int64]$Bytes
	)
	[string]$BigBytes = ""
	#Convert to TB
	If ($Bytes -ge 1TB) {$BigBytes = [math]::round($Bytes / 1TB, 2); $BigBytes += " TB"}
	#Convert to GB
	ElseIf ($Bytes -ge 1GB) {$BigBytes = [math]::round($Bytes / 1GB, 2); $BigBytes += " GB"}
	#Convert to MB
	ElseIf ($Bytes -ge 1MB) {$BigBytes = [math]::round($Bytes / 1MB, 2); $BigBytes += " MB"}
	#Convert to KB
	ElseIf ($Bytes -ge 1KB) {$BigBytes = [math]::round($Bytes / 1KB, 2); $BigBytes += " KB"}
	#If smaller than 1KB, leave at bytes.
	Else {$BigBytes = $Bytes; $BigBytes += " Bytes"}
	Return $BigBytes
}

#== Document only the information we care about ==
Function Log-BackupItems
{
    Param
    (
        [System.String]$Name,
        [System.String]$Status,
        [System.Int64]$Bytes
    )

    $Item = New-Object System.Object;
    $Item | Add-Member -Type NoteProperty -Name "Name" -Value $Name;
    $Item | Add-Member -Type NoteProperty -Name "Status" -Value $Status;
    $Item | Add-Member -Type NoteProperty -Name "Size" -Value (FormatBytes -Bytes $Bytes);

    Return $Item;
}

#== Get Backup Items ==
cls
Add-PSSnapin Windows.ServerBackup -ErrorAction SilentlyContinue
$results=@()
$jobs = Get-WBJob -Previous 1
$jobs | % {
	$_.JobItems | % {
		$BackupItem = $null
		If ($_.Name -eq 'VolumeList') {
			$_ | % {$_.SubItemList | % {
				$BackupItem = Log-BackupItems -Name $_.Name -Status $_.State -Bytes $_.TotalBytes
				$results += $BackupItem
			}}
		} 
		Else {
			$_ | % {
				$BackupItem = Log-BackupItems -Name $_.Name -Status $_.State -Bytes $_.TotalBytes
				$results += $BackupItem
			}
		}
	}
}

#== Create Report ==
$body = $(
		"<span>$($env:computername) backup completed <b>$(if($success){'successfully'} else {'with errors'})</b>!</span><br><hr>"
		"Start time: $($jobs.StartTime)<br>"
		"End time: $($jobs.EndTime)<br>"
		"Duration: $((New-TimeSpan -Start (Get-WBJob -Previous 1).StartTime -End (Get-WBJob -Previous 1).EndTime))<br><br>"
		$(
			$html = $results | ConvertTo-HTML -Fragment
			$xml=[xml]$html
			$attr=$xml.CreateAttribute('id')
			$attr.Value='BackupItems'
			$xml.table.Attributes.Append($attr) | out-null
			$html=$xml.OuterXml | out-string
			$html
		)
	)
$style = @"
	<style>
	Body
	{
	font-family:"Trebuchet MS", Arial, Helvetica, sans-serif;
	font-size:100%;
	}
	#BackupItems
	{
	font-family:"Trebuchet MS", Arial, Helvetica, sans-serif;
	border-collapse:collapse;
	}
	#BackupItems td, #BackupItems th 
	{
	border:1px solid $(if($success){'#98bf21'} else {'#821515'});
	padding:3px 7px 2px 7px;
	}
	#BackupItems th 
	{
	text-align:left;
	padding-top:5px;
	padding-bottom:4px;
	background-color:$(if($success){'#98bf21'} else {'#821515'});
	color:#fff;
	}
	span
	{
	font-size:110%;
	font-weight:bold;
	}
	</style>
"@
$body = ConvertTo-HTML -head $style -body $body -Title "Disk Usage Report" | Out-String

#== Save Report to file ==
if ($log) {
	$logpath = "$log\$env:computername$((get-date).toString('MMddyyyyHHmmss')).html"
	$altlogpath = "$env:systemdrive\$env:computername$((get-date).toString('MMddyyyyHHmmss')).html" #In case network trouble (or invalid path) prevents saving at primary path.
	$body | out-file "$logpath"
	if (Test-Path $logpath) {
		$body += "<br><small>Log saved from $($env:computername) at $logpath.</small>"
		write-host "Log Saved to $logpath"
	}
	else {
		$body | out-file "$altlogpath"
		if (Test-Path $logpath) {
			$body += "<br><small>Log saved from $($env:computername) at $altlogpath.</small>"
			write-host "Log Saved to $altlogpath"
		}
		else {
			$body += "<br><small>Could not save log.</small>"
			write-host "Could not save log."
		}
	}
}

#== Email Report ==
if ($email) {
	$subject = "Backup $(if($success){'Success'} else {'Failure'}): $($env:computername)"
	Send-MailMessage -To $to -From $from -Subject $subject -Body $body -BodyAsHTML -SmtpServer $SMTPServer
	write-host "Email Sent"
}

# If you're sending via Gmail, then use the below if-statement instead of the one above. 
# if ($email) {
	# $pwd = ConvertTo-SecureString ‘P@ssw0rd’ -AsPlainText -Force
	# $cred = New-Object System.Management.Automation.PSCredential 'you@gmail.com',$pwd
	# $param = @{
		# SmtpServer = 'smtp.gmail.com'
		# Port = 587
		# UseSsl = $true
		# Credential  = $cred
		# From = $from
		# To = $to
		# Subject = "Backup $(if($success){'Success'} else {'Failure'}): $($env:computername)"
		# Body = $body
	# }
	# Send-MailMessage @param -BodyAsHTML
	# write-host "Email Sent"
# }
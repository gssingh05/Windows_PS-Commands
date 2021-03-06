#—————————————–Start script—————————————————-

function SendEmail($To, $From, $Subject, $Body, $attachment, $smtpServer) 
{ 
        Send-MailMessage -To $To -Subject $Subject -From $From -Body $Body -Attachment $attachment -SmtpServer $smtpServer 
} 
$emailto=”email@address.com” 
$emailfrom=”email@address.com” 
$day=(get-date -f dd-MM-yyyy)
$hname="HOSTNAME"
$backuplocation="\\BACKUP-SERVER\SHARE\$hname\$day\" 
$backuplog="$backuplocation"+(get-date -f dd-MM-yyyy)+"-backup-$hname.log" 
$emailserver="EMAIL-SERVER" 

function Out-FileForce {
PARAM($backuplocation)
PROCESS
{
    if(Test-Path $backuplocation)
    {
        Out-File -inputObject $_ -append -filepath $backuplocation
    }
    else
    {
        new-item -force -path $backuplocation -value $_ -type file
    }
}
}

Write-Output ("———————– Backup started on – $(Get-Date –f o) ————————-") | Out-FileForce "$backuplog" 
$Error.Clear() 
wbadmin start backup -backupTarget:$backuplocation -include:c: -systemstate -allcritical -vsscopy -quiet | Out-FileForce "$backuplog" 
if(!$?) 
    { 
        Write-Output ("———————– An error has occurred! Check it please!. – $(Get-Date –f o) ————————-") | Out-File "$backuplog" -Append 
        SendEmail -To "$emailto" -From "$emailfrom" -Subject "backup failed" -Body "The backup has failed! Please check attached log." -attachment "$backuplog" -smtpServer "$emailserver" 
        break 
        
    }

Write-Output ("———————– Everything is OK! – $(Get-Date –f o) ————————-") | Out-File "$backuplog" -Append 
SendEmail -To "$emailto" -From "$emailfrom" -Subject "backup $hname ok" -Body "The backup has succeeded!" -attachment "$backuplog" -smtpServer "$emailserver" .
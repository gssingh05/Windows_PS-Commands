$Name = Hostname
$EmailFrom = "Domain Controller DC2 <gurvinder.singh@geminisolutions.in>"
$EmailTo = "Backup Admin <gurvinder.singh@geminisolutions.in>" 
$Subject = "Backup on $date on server $Name"
$Body = "The backup operation has been successfully done! Date: $date on server $Name"
$SMTPServer = "smtp.gmail.com" 
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587) 
$SMTPClient.EnableSsl = $true 
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential("gurvinder.singh@geminisolutions.in", "Huda#123"); 
$SMTPClient.Send($EmailFrom, $EmailTo, $Subject, $Body)
$Servers=Get-Content c:\a.txt # List of the servers stored in 
$output = 'c:\ListOfAdministratorsGroup.csv'
$results = @()
$final =@()

$objSID = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
$objgroup = $objSID.Translate( [System.Security.Principal.NTAccount])
$objgroupname = ($objgroup.Value).Split("\")[1]

foreach($server in $Servers)
{
$admins = @()
$group =[ADSI]"WinNT://$server/$objgroupname" 
$members = @($group.psbase.Invoke("Members"))
$members | foreach {
$obj = new-object psobject -Property @{
Server = $Server
AdminUsers = $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)

 }
$final= write-host $obj.Server, $obj.AdminUsers 
  $admins += $obj
} 
$results += $admins
}
$results| Export-csv $Output -NoTypeInformation

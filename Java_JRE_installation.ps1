$JDK_VER="7u75"
$JDK_FULL_VER="7u75-b13"
$JDK_PATH="1.7.0_75"
#$source86 = "http://download.oracle.com/otn-pub/java/jdk/$JDK_FULL_VER/jdk-$JDK_VER-windows-i586.exe"
$exefile1 = "jre-8u141-windows-i586.exe"
$exefile2 = "jre-8u141-windows-x64.exe"
$exeloc = "C:\A_Java\"                 #"we can change this as share location for exe files"
$source86 = "$exeloc" +"$exefile1"; 
#$source86 = "C:\A_Java\jre-8u141-windows-i586.exe"
#$source64 = "http://download.oracle.com/otn-pub/java/jdk/$JDK_FULL_VER/jdk-$JDK_VER-windows-x64.exe"
$source64 = "$exeloc" +"$exefile2";               
#$source64 = "C:\A_Java\jre-8u141-windows-x64.exe"
$dloc = "C:\B_Java\"
$destination86 = "$dloc" + "$exefile1"
$destination64 = "$dloc" + "$exefile2"
#$client = new-object System.Net.WebClient
#$cookie = "oraclelicense=accept-securebackup-cookie"
#$client.Headers.Add([System.Net.HttpRequestHeader]::Cookie, $cookie)
 
Write-Host 'Checking if Java is already installed'
if ((Test-Path "c:\Program Files (x86)\Java") -Or (Test-Path "c:\Program Files\Java")) {
    Write-Host 'No need to Install Java'
    Exit
}

function Install()
{
 if (!(Test-Path $destination64))
 {
 if (!(Test-Path $dloc))
 {
    Write-Output  "create $dloc";
    mkdir -Force $dloc
    }
    write-output "copy $source64 to $dloc";
    cp -Force $source64 $dloc;
  }
  }  
#Write-Host 'Downloading x86 to $destination86'
 
#$client.downloadFile($source86, $destination86)
#if (!(Test-Path $destination86)) {
 #   Write-Host "Downloading $destination86 failed"
  #  Exit
#}
#Write-Host 'Downloading x64 to $destination64'
 
#$client.downloadFile($source64, $destination64)
#if (!(Test-Path $destination64)) {
 #   Write-Host "Downloading $destination64 failed"
  #  Exit
#}
 
 
try {
    Write-Host 'Installing JDK-x64'
    $proc1 = Start-Process -FilePath "$destination64" -ArgumentList "/s REBOOT=ReallySuppress" -Wait -PassThru
    $proc1.waitForExit()
    Write-Host 'Installation Done.'
 
    Write-Host 'Installing JDK-x86'
    $proc2 = Start-Process -FilePath "$destination86" -ArgumentList "/s REBOOT=ReallySuppress" -Wait -PassThru
    $proc2.waitForExit()
    Write-Host 'Installtion Done.'
} catch [exception] {
    write-host '$_ is' $_
    write-host '$_.GetType().FullName is' $_.GetType().FullName
    write-host '$_.Exception is' $_.Exception
    write-host '$_.Exception.GetType().FullName is' $_.Exception.GetType().FullName
    write-host '$_.Exception.Message is' $_.Exception.Message
}
 
if ((Test-Path "c:\Program Files (x86)\Java") -Or (Test-Path "c:\Program Files\Java")) {
    Write-Host 'Java installed successfully.'
}
Write-Host 'Setting up Path variables.'
[System.Environment]::SetEnvironmentVariable("JAVA_HOME", "c:\Program Files (x86)\Java\jdk$JDK_PATH", "Machine")
[System.Environment]::SetEnvironmentVariable("PATH", $Env:Path + ";c:\Program Files (x86)\Java\jdk$JDK_PATH\bin", "Machine")
Write-Host 'Done. Goodbye.'
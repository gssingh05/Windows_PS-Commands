$arguments = @(
    '/s',
    "/v/qn `"INSTALL_SILENT=1 STATIC=0 AUTO_UPDATE=0 WEB_JAVA=1 WEB_JAVA_SECURITY_LEVEL=H WEB_ANALYTICS=0 EULA=0 REBOOT=0 NOSTARTMENU=0 SPONSORS=0 /L \`"c:\temp\java_install.log\`"`""
)

$proc = Start-Process "\\srv\netlogon\java\jre-8u45-windows-i586.exe" -ArgumentList $arguments -Wait -PassThru
if($proc.ExitCode -ne 0) {
    Throw "ERROR"
}





powershell start-process -filepath jre-8u25-windows-x64.exe -passthru -wait -argumentlist "/s,INSTALLDIR=c:\progra~1\jre,/L,install64.log"
Start-Process -FilePath jre -PassThru -Wait -ArgumentList
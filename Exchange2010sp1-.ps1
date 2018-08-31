# Globals 
$setupRegistryPath = Get-ItemProperty -path 'HKLM:SOFTWARE\Microsoft\ExchangeServer\v14\Setup' 
$exchangeInstallPath = $setupRegistryPath.MsiInstallPath 
$ComputerName = [string]$Env:computername 
 
$OabPath = "Default Web Site/OAB" 
 
# Initialize IIS metabase management object 
$InitWebAdmin = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration")  
$Iis = new-object Microsoft.Web.Administration.ServerManager  
 
# Creates OAB app pool based on DefaultAppPool, running as LocalSystem 
function CreateOabAppPool 
{ 
    # Get existing OAB authentication values to set later 
    $config = $Iis.GetApplicationHostConfiguration(); 
    $basicAuthenticationSectionEnabled = $config.GetSection("system.webServer/security/authentication/basicAuthentication", "Default Web Site/OAB")["enabled"]; 
    $windowsAuthenticationSectionEnabled = $config.GetSection("system.webServer/security/authentication/windowsAuthentication", "Default Web Site/OAB")["enabled"]; 
 
    $apppool = $Iis.ApplicationPools["MSExchangeOabAppPool"] 
    if ($apppool) 
    { 
        # Delete existing app pool 
        $apppool.Delete()        
        # Flush 
        $Iis.CommitChanges() 
    } 
 
    # Create new app pool, then bind to it 
    $a=$Iis.applicationPools.Add("MSExchangeOabAppPool") 
    $apppool = $Iis.ApplicationPools["MSExchangeOabAppPool"] 
     
    # Now make sure it runs as LocalSystem, and prevent unnecessary app pool restarts 
    $apppool.ProcessModel.IdentityType = [Microsoft.Web.Administration.ProcessModelIdentityType]"LocalSystem" 
    $apppool.ProcessModel.idleTimeout = "0.00:00:00" 
    $apppool.Recycling.PeriodicRestart.time = "0.00:00:00" 
 
    # Create /OAB application 
    $OabApplication = $Iis.Sites["Default Web Site"].Applications["/OAB"] 
    if ($OabApplication) 
    { 
        # Delete it 
        $OabApplication.Delete() 
        # Flush 
        $Iis.CommitChanges() 
    } 
 
    $oabvdir=$Iis.Sites["Default Web Site"].Applications["/"].VirtualDirectories["/OAB"] 
    if ($oabvdir) 
    { 
        # Clean up vdir 
        $oabvdir.Delete() 
        $Iis.CommitChanges() 
    } 
         
    $addSite=$Iis.Sites["Default Web Site"].Applications.Add("/OAB", $ExchangeInstallPath + "ClientAccess\OAB") 
    $OabApplication = $Iis.Sites["Default Web Site"].Applications["/OAB"] 
    if ($OabApplication -eq $Null) 
    { 
        # Error creating OAB vdir.  Need to fix existing one and rest 
        Write-Warning "Error updating Default Web Site/OAB to support the OABAuth component." 
        Write-Output "Please use IIS Manager to remove the Default Web Site/OAB virtual directory, then the following commands to recreate the OAB virtual directory:" 
        Write-Output "Get-OabVirtualDirectory -server $ComputerName | Remove-OabVirtualDirectory" 
        Write-Output "New-OabVirtualDirectory -server $ComputerName" 
        break 
    } 
 
    #Set app pool 
    $OabApplication.ApplicationPoolName = "MSExchangeOabAppPool" 
 
    #Restore previous auth settings and enabled anonymous 
    # Reload applicationHost.config 
    $config = $Iis.GetApplicationHostConfiguration(); 
     
    # Check null (inherited from root of web server), otherwise set to previous value 
    if ($basicAuthenticationSectionEnabled) 
    { 
        $basicAuthenticationSection = $config.GetSection("system.webServer/security/authentication/basicAuthentication", "Default Web Site/OAB") 
        $basicAuthenticationSection["enabled"]=$basicAuthenticationSectionEnabled 
    } 
     
    # Check null (inherited from root of web server), otherwise set to previous value 
    if ($windowsAuthenticationSectionEnabled) 
    { 
        $windowsAuthenticationSection = $config.GetSection("system.webServer/security/authentication/windowsAuthentication", "Default Web Site/OAB") 
        $windowsAuthenticationSection["enabled"] = $windowsAuthenticationSectionEnabled 
    } 
 
    $Iis.CommitChanges() 
} 
 
# Loads OAB auth module by creating or overwriting web.config for OAB vdir 
function UpdateOabWebConfig() 
{ 
    $webConfigPath = $ExchangeInstallPath + "ClientAccess\OAB\web.config" 
    $webConfigOriginal = @" 
<?xml version="1.0" encoding="utf-8"?> 
<configuration> 
  <system.webServer> 
    <modules> 
      <add name="Microsoft.Exchange.OABAuth" type="Microsoft.Exchange.OABAuth.OABAuthModule" /> 
    </modules> 
  </system.webServer> 
  <system.web> 
    <compilation defaultLanguage="c#" debug="false"> 
      <assemblies> 
        <add assembly="Microsoft.Exchange.Net, Version=14.0.0.0, Culture=neutral, publicKeyToken=31bf3856ad364e35"/> 
        <add assembly="Microsoft.Exchange.Diagnostics, Version=14.0.0.0, Culture=neutral, publicKeyToken=31bf3856ad364e35"/> 
        <add assembly="Microsoft.Exchange.OabAuthModule, Version=14.0.0.0, Culture=neutral, publicKeyToken=31bf3856ad364e35"/> 
      </assemblies> 
    </compilation> 
  </system.web> 
  <runtime> 
    <assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1"> 
      <dependentAssembly> 
        <assemblyIdentity name="Microsoft.Exchange.OABAuthModule" publicKeyToken="31bf3856ad364e35" culture="neutral" /> 
        <codeBase version="14.0.0.0" href="file:///{0}bin\Microsoft.Exchange.OABAuthModule.dll"/> 
      </dependentAssembly> 
      <dependentAssembly> 
        <assemblyIdentity name="Microsoft.Exchange.Net" publicKeyToken="31bf3856ad364e35" culture="neutral" /> 
        <codeBase version="14.0.0.0" href="file:///{0}bin\Microsoft.Exchange.Net.dll"/> 
      </dependentAssembly> 
      <dependentAssembly> 
        <assemblyIdentity name="Microsoft.Exchange.Rpc" publicKeyToken="31bf3856ad364e35" culture="neutral" /> 
        <codeBase version="14.0.0.0" href="file:///{0}bin\Microsoft.Exchange.Rpc.dll"/> 
      </dependentAssembly> 
      <dependentAssembly> 
        <assemblyIdentity name="Microsoft.Exchange.Diagnostics" publicKeyToken="31bf3856ad364e35" culture="neutral" /> 
        <codeBase version="14.0.0.0" href="file:///{0}bin\Microsoft.Exchange.Diagnostics.dll"/> 
      </dependentAssembly> 
    </assemblyBinding> 
  </runtime> 
</configuration> 
"@ 
    # Swap in Exchange installation path 
    $webConfigData = [string]::Format($webConfigOriginal, $ExchangeInstallPath) 
 
    # Check for existing web.config 
    if (Test-Path $webConfigPath) 
    { 
        # Make a backup copy of current web.config 
        $backupPath = $webConfigPath + " Backup " + [string](get-date -Format "yyyy-MM-dd HHmmss") 
        Write-Output "Backing up existing web.config to ""$backupPath""" 
        Copy-Item $webConfigPath $backupPath 
    } 
    Out-File -FilePath $webConfigPath -InputObject $webConfigData -Encoding "UTF8" 
    Write-Output "Created $webConfigPath." 
} 
 
 
# Main 
Write-Output "Converting OAB virtual directory on $ComputerName to an application..." "" 
 
# Get IIS config to create OAB-specific app pool, then add web.config for OABAuth module 
UpdateOabWebConfig 
CreateOabAppPool 
 
Write-Output "Done!  OAB virtual directory has been converted to an application on $ComputerName." 
$a=$Iis.Dispose()
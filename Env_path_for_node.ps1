[System.Environment]::SetEnvironmentVariable("NODE_HOME", "C:\Tool\node64\node_modules", "Machine")
[System.Environment]::SetEnvironmentVariable("PATH",  $Env:Path + ";C:\Tool\node64\node_modules", "Machine")
Write-Host 'environment varibale set for Node 64 Bit.'
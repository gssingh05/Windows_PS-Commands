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
PS C:\> $Policy = Get-WBPolicy
PS C:\> $VirtualMachines = Get-WBVirtualMachine
PS C:\> Add-WBVirtualMachine -Policy $Policy -VirtualMachine $VirtualMachines
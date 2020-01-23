$volume="\\?\Volume{f0bb3284-6c4f-42b4-a88e-749e709b0d9e}\"









$kernel32 = Add-Type -MemberDefinition '
[DllImport("kernel32.dll")] public static extern IntPtr CreateFile(String lpFileName, UInt32 dwDesiredAccess, UInt32 dwShareMode, IntPtr SecurityAttributes,UInt32 dwCreationDisposition, UInt32 dwFlagsAndAttributes, IntPtr hTemplateFile);
[DllImport("kernel32.dll")] public static extern bool DeviceIoControl(IntPtr hDevice, uint dwIoControlCode, IntPtr lpInBuffer, uint nInBufferSize, IntPtr lpOutBuffer, uint nOutBufferSize, out uint lpBytesReturned, IntPtr lpOverlapped);
[DllImport("kernel32.dll")] public static extern Int32 GetLastError();' -Name 'kernel32' -Namespace 'Win32' -PassThru




[System.IntPtr]$mountmanagerHandle=$kernel32::CreateFile("\\.\MountPointManager", 0, 3, [System.IntPtr]::Zero, 3, [System.UInt32]0x80,  0xffffffffffffffff)


[System.UInt32]$dwIoControlCode=[System.UInt32]0x6d0034 # IOCTL_MOUNTMGR_QUERY_DOS_VOLUME_PATHS   

[System.IntPtr]$lpInBuffer = [System.Runtime.InteropServices.Marshal]::StringToHGlobalUni($volume)
[System.UInt32]$inInBufferSize=520#[System.Text.Encoding]::Unicode.GetByteCount($volume)
[System.IntPtr]$lpOutBuffer = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(4)
[System.UInt32]$inOutBufferSize=[System.Runtime.InteropServices.Marshal]::SizeOf($lpOutBuffer)
[System.UInt32]$lpBytesReturned=0
[System.IntPtr]$lpOverlapped = [System.IntPtr]::Zero

$kernel32::DeviceIoControl($mountmanagerHandle,$dwIoControlCode,$lpInBuffer,$inInBufferSize,$lpOutBuffer,$inOutBufferSize,[ref]$lpBytesReturned,$lpOverlapped)
$kernel32::GetLastError()


$lpBytesReturned
[System.Runtime.InteropServices.Marshal]::PtrToStringUni($lpOutBuffer)

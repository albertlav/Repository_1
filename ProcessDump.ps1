#create usermode dump of process by PID
#4th arg _MINIDUMP_TYPE=MiniDumpWithFullMemory | MiniDumpWithFullMemoryInfo | MiniDumpWithHandleData | MiniDumpWithProcessThreadData| MiniDumpWithThreadInfo | MiniDumpWithUnloadedModules
#modify for your needs using https://docs.microsoft.com/en-us/windows/win32/api/minidumpapiset/ne-minidumpapiset-minidump_type
#result will go to %temp% with timestamp

$pidToDump=26452 #give here processid to dump
$process=$(Get-Process -Id $pidToDump)
$file=$(New-Item -ItemType File -Path $env:TEMP\$pidTodump-$($(get-date).ToFileTimeUtc()).dmp -Force).OpenWrite()
$dbghelp=Add-Type -MemberDefinition '[DllImport("dbghelp.dll")] public static extern bool MiniDumpWriteDump(IntPtr hProcess, UInt32 ProcessId, IntPtr hFile, UInt32 DumpType, IntPtr ExceptionParam, IntPtr UserStreamParam, IntPtr CallbackParam);' -Name 'dbghelp' -PassThru
$dbghelp::MiniDumpWriteDump($process.Handle, $process.Id, $file.Handle, 0x00000002 -bor 0x00000100 -bor 0x00001000 -bor 0x00000800 -bor 0x00000004 -bor 0x00000020, [System.IntPtr]::Zero, [System.IntPtr]::Zero, [System.IntPtr]::Zero)
$file.Close()

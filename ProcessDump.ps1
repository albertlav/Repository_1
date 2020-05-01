#create usermode dump of process by PID
#_MINIDUMP_TYPE=MiniDumpWithFullMemory (0x2)
#result will go to %temp% with timestamp

$pidToDump=26452 #give here processid to dump
$process=$(Get-Process -Id $pidToDump)
$file=$(New-Item -ItemType File -Path $env:TEMP\$pidTodump-$($(get-date).ToFileTimeUtc()).dmp -Force).OpenWrite()
$dbghelp=Add-Type -MemberDefinition '[DllImport("dbghelp.dll")] public static extern bool MiniDumpWriteDump(IntPtr hProcess, UInt32 ProcessId, IntPtr hFile, UInt32 DumpType, IntPtr ExceptionParam, IntPtr UserStreamParam, IntPtr CallbackParam);' -Name 'dbghelp' -PassThru
$dbghelp::MiniDumpWriteDump($process.Handle, $process.Id, $file.Handle, 2, [System.IntPtr]::Zero, [System.IntPtr]::Zero, [System.IntPtr]::Zero)
$file.Close()

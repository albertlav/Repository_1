
$source = @"
using System;
using System.Runtime.InteropServices;

namespace Script
{
    public static class PS3
    {
        [StructLayout(LayoutKind.Sequential, Pack = 1)] public struct PTOKEN_PRIVILEGES {public int PrivilegeCount;public long Luid;public int Attributes;}
        [DllImport("kernel32", SetLastError = true, CharSet = CharSet.Unicode)] public static extern bool GetSystemFileCacheSize(ref IntPtr lpMinimumFileCacheSize,ref IntPtr lpMaximumFileCacheSize,ref IntPtr lpFlags);
        [DllImport("kernel32", SetLastError = true, CharSet = CharSet.Unicode)] public static extern bool SetSystemFileCacheSize(IntPtr MinimumFileCacheSize,IntPtr MaximumFileCacheSize,Int32 Flags);
        [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true, CharSet = CharSet.Unicode)] public static extern bool OpenProcessToken(IntPtr ProcessHandle, int DesiredAccess, ref IntPtr TokenHandle);
        [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true, CharSet = CharSet.Unicode)] public static extern bool LookupPrivilegeValueW(string lpSystemName, string lpName, ref long lpLuid);
        [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true, CharSet = CharSet.Unicode)] public static extern bool AdjustTokenPrivileges(IntPtr TokenHandle, bool DisableAllPrivileges,ref PTOKEN_PRIVILEGES NewState, int BufferLength, IntPtr PreviousState, IntPtr ReturnLength);
    }
}
"@

Add-Type -TypeDefinition $source -Language CSharp -PassThru


#активируем SeIncreaseQuotaPrivilege для текущего процесса используя AdjustTokenPrivileges, как требуется для SetSystemFileCacheSize
$TOKEN_ALL_ACCESS = 0x000F01FF
$SE_PRIVILEGE_ENABLED = 0x00000002;
$priv="SeIncreaseQuotaPrivilege"
$TokenHandle=0
$lpLuid=0

$ProcessHandle=$(Get-Process -pid $pid).Handle #получаем хэндл процесса 
       
"Результат advapi32!OpenProcessToken : "       + [Script.PS3]::OpenProcessToken($ProcessHandle, $TOKEN_ALL_ACCESS, [ref] $TokenHandle) #получаем токен процесса
"Результат advapi32!LookupPrivilegeValueW : "  + [Script.PS3]::LookupPrivilegeValueW($null, $priv , [ref] $lpLuid) #получаем  locally unique identifier (LUID) https://docs.microsoft.com/en-us/windows/win32/api/winnt/ns-winnt-luid_and_attributes

$tp=New-Object Script.PS3+PTOKEN_PRIVILEGES
$tp.PrivilegeCount = 1
$tp.Luid = $lpLuid
$tp.Attributes = $SE_PRIVILEGE_ENABLED


"Результат advapi32!AdjustTokenPrivileges : "  + [Script.PS3]::AdjustTokenPrivileges($TokenHandle,$false,[ref]$tp,0,[IntPtr]::Zero,[IntPtr]::Zero) #https://docs.microsoft.com/en-us/windows/win32/api/securitybaseapi/nf-securitybaseapi-adjusttokenprivileges, https://docs.microsoft.com/en-us/windows/win32/secauthz/enabling-and-disabling-privileges-in-c--


#получим текущие значения 
$MinimumFileCacheSize = 0
$MaximumFileCacheSize = 0
$Flags = 0
"Результат kernel32!GetSystemFileCacheSize : " + [Script.PS3]::GetSystemFileCacheSize([ref]$MinimumFileCacheSize,[ref]$MaximumFileCacheSize,[ref]$Flags) #https://docs.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-getsystemfilecachesize
$MinimumFileCacheSize=[int64]$MinimumFileCacheSize
$MaximumFileCacheSize=[int64]$MaximumFileCacheSize

"MaximumFileCacheSize: " + $MaximumFileCacheSize
"Flags: " + $Flags

#установим MaximumFileCacheSize и флаг FILE_CACHE_MAX_HARD_ENABLE 
$FILE_CACHE_MAX_HARD_ENABLE=0x1
"Результат kernel32!SetSystemFileCacheSize : " + [Script.PS3]::SetSystemFileCacheSize($MinimumFileCacheSize,16Gb,$FILE_CACHE_MAX_HARD_ENABLE);

"Результат kernel32!GetSystemFileCacheSize : " + [Script.PS3]::GetSystemFileCacheSize([ref]$MinimumFileCacheSize,[ref]$MaximumFileCacheSize,[ref]$Flags)
"MaximumFileCacheSize после изменения: " + $MaximumFileCacheSize
"Flags после изменения: " + $Flags



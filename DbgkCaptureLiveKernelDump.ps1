<#
Creates Kernel Dump of live running Windows system without blue screen stop
Basically it tries to reproduce behavior of Sysinternals LiveKd.exe with -ml param

1: kd> kv4
 # Child-SP          RetAddr           : Args to Child                                                           : Call Site
00 ffffb283`4bb07868 fffff801`57128532 : ffffb283`4bb078d0 fffff801`5748feaa fffff801`5707abe0 7fff980e`59e8cf00 : nt!IoCaptureLiveDump
01 ffffb283`4bb07870 fffff801`577bffde : ffff980e`00000020 ffffffff`800023b4 ffff980e`593d4d60 ffff980e`59e8ce80 : nt!DbgkCaptureLiveKernelDump+0x2ca
02 ffffb283`4bb07900 fffff801`57078e15 : 00000000`00000025 000000d1`b7cfddd0 00000000`00000040 00000000`00000000 : nt!NtSystemDebugControl+0x3de
03 ffffb283`4bb07a10 00007fff`c711f794 : 00007ff6`e7e489c2 00007ff6`e7ea6400 000000d1`b7cfeb10 00000000`00000000 : nt!KiSystemServiceCopyEnd+0x25 (TrapFrame @ ffffb283`4bb07a80)

00000000`00000025 
000000d1`b7cfddd0 <-
00000000`00000040  
00000000`00000000

1: kd> dd 000000d1`b7cfddd0 000000d1`b7cfddd0+0x40
000000d1`b7cfddd0  00000001 00000000 00000000 00000000
000000d1`b7cfdde0  00000000 00000000 00000000 00000000
000000d1`b7cfddf0  00000000 00000000 00000214 00000000
000000d1`b7cfde00  00000044 00000000 00000000 00000000
000000d1`b7cfde10  00000000                                        .


1: kd> !handle 214

PROCESS ffff980e551b1080
    SessionId: 1  Cid: 2268    Peb: d1b7b6c000  ParentCid: 14b0
    DirBase: 53f4d000  ObjectTable: ffff858744e46d40  HandleCount: 126.
    Image: livekd64.exe

Handle table at ffff858744e46d40 with 126 entries in use

0214: Object: ffff980e59e8ce80  GrantedAccess: 0012019f (Protected) (Audit) Entry: ffff8587439ff850
Object: ffff980e59e8ce80  Type: (ffff980e502fad20) File
    ObjectHeader: ffff980e59e8ce50 (new version)
        HandleCount: 2  PointerCount: 65537
        Directory Object: 00000000  Name: \livekd.dmp {HarddiskVolume2}


use with caution, lot of unknown params..
#>

$ntdll=Add-Type -MemberDefinition @"
[StructLayout(LayoutKind.Sequential)]  
public struct ObjectForNtSystemDebugControlSize64 {
    public UInt32 Val0;              //??
    public UInt32 Val1;              //used as bugcheck code(?)
    public UInt64 Val2;              //Val2 - Val5 used as bugcheck params(?)
    public UInt64 Val3;
    public UInt64 Val4;
    public UInt64 Val5;
    public IntPtr FileHandle;        //handle to file
    public IntPtr Val7;              //??
    public UInt32 Val8;              //??
    public UInt32 Val9;              //??
};
[DllImport("ntdll.dll")]
public static extern UInt32 NtSystemDebugControl(UInt32 arg0, IntPtr arg1, UInt32 arg2, IntPtr arg3, UInt32 arg4, IntPtr arg5);
"@ -Name 'ntdll' -Namespace 'api'

$file=$(New-Item -ItemType File -Path "$env:TEMP\kernel-$($(get-date).ToFileTimeUtc()).dmp" -Force).OpenWrite()
$o=New-Object -TypeName api.ntdll+ObjectForNtSystemDebugControlSize64
$o.FileHandle=$file.Handle
[IntPtr]$ptr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(0x40)
[System.Runtime.InteropServices.Marshal]::StructureToPtr($o,$ptr,$false)
[api.ntdll]::NtSystemDebugControl(0x25,$ptr,0x40,[System.IntPtr]::Zero,0,[System.IntPtr]::Zero)
$file.Close()

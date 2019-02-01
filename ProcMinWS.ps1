
#BOOL GetProcessWorkingSetSizeEx(
#  HANDLE  hProcess,
#  PSIZE_T lpMinimumWorkingSetSize,
#  PSIZE_T lpMaximumWorkingSetSize,
#  PDWORD  Flags
#);

#QUOTA_LIMITS_HARDWS_MIN_DISABLE 0010
#QUOTA_LIMITS_HARDWS_MIN_ENABLE  0001
#QUOTA_LIMITS_HARDWS_MAX_DISABLE 1000
#QUOTA_LIMITS_HARDWS_MAX_ENABLE  0100



$result= New-Object System.Collections.ArrayList

$MethodDefinition = @'
[DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
public static extern void GetProcessWorkingSetSizeEx(IntPtr hProcess, ref IntPtr lpMinimumWorkingSetSize, ref IntPtr lpMaximumWorkingSetSize, ref IntPtr Flags);
'@
$Kernel32 = Add-Type -MemberDefinition $MethodDefinition -Name 'Kernel32' -Namespace 'Win32' -PassThru 


Get-Process |%{
$handle = $_.handle
$lpMinimumWorkingSetSize=0
$lpMaximumWorkingSetSize=0
$Flags=0
$void=$Kernel32::GetProcessWorkingSetSizeEx($handle, [ref]$lpMinimumWorkingSetSize, [ref]$lpMaximumWorkingSetSize,[ref] $Flags)
$temp = "" | select "ID","Name", "MinWS","MaxWS","Flags"

$temp.ID=$_.Id
$temp.Name=$_.Name
$temp.MinWS=$lpMinimumWorkingSetSize/1024
$temp.MaxWS=$lpMaximumWorkingSetSize/1024
$temp.Flags=[convert]::ToString($Flags.ToInt32(),2)
$result.Add($temp)
}

$result|ogv
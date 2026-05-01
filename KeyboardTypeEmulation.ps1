$stt=@'
Keyboard input emulation for windows powershell

use:
paste whatever you need to type here, replacing this text
run
get focus to the window where you need to type it in 5 seconds

tune CR/LF handling for your needs by (un)commenting or changing char 10/13 handling
tune delay between keypresses to your needs. 
50 ms works fine generally for typing something complex (hugeoneliners, multiline code/script, base64 encoded binary data, etc) to BMC console or remote screensharing

'@
$ws=new-object -comobject wscript.shell;$sks=("{","}","+","^","%","~","(",")","[","]");sleep -seconds 5;foreach($c in $stt.tochararray()){if([byte]$c -eq 13<#10#>){<#continue#>}foreach($cc in $sks.tochararray()){$s=$($c.tostring().replace("$cc","{$cc}"));if($s -ne $c){break}}sleep -milliseconds 50;$ws.sendkeys($s)}

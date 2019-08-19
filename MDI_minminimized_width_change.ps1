
$definition = @"
using System;
using System.Collections.Generic;
using System.Text;
using System.Runtime.InteropServices;
using System.Net;
namespace controlMINIMIZEDMETRICS
{

    [StructLayout(LayoutKind.Sequential)]
    public  struct MINIMIZEDMETRICS 
    {
        public uint cbSize;
        public int iWidth;
        public int iHorzGap;
        public int iVertGap;
        public int iArrange;
    }


    public static class PS
    {
        [DllImport("user32", CharSet=CharSet.Auto)]
        public static extern int SystemParametersInfo(int uAction, int uParam, out MINIMIZEDMETRICS lpvParam, int fuWinIni);
    }
}
"@


Add-Type -TypeDefinition $definition -PassThru


$minMetricsStruct = New-Object controlMINIMIZEDMETRICS.MINIMIZEDMETRICS
$minMetricsStruct.cbSize = [system.runtime.interopservices.Marshal]::SizeOf($(New-Object controlMINIMIZEDMETRICS.MINIMIZEDMETRICS))
$size= [system.runtime.interopservices.Marshal]::SizeOf($minMetricsStruct)

#SPI_GETMINIMIZEDMETRICS
#0x002B
#Retrieves the metrics associated with minimized windows. The pvParam parameter must point to a MINIMIZEDMETRICS structure that receives the information. Set the cbSize member of this structure and the uiParam parameter to sizeof(MINIMIZEDMETRICS).

[controlMINIMIZEDMETRICS.PS]::SystemParametersInfo(0x002B,$size,[ref]$minMetricsStruct,0) #получим текущие значения в объект $minMetricsStruct
$minMetricsStruct #вывести полученные значения

#SPI_SETMINIMIZEDMETRICS
#0x002C
#Sets the metrics associated with minimized windows. The pvParam parameter must point to a MINIMIZEDMETRICS structure that contains the new parameters. Set the cbSize member of this structure and the uiParam parameter to sizeof(MINIMIZEDMETRICS).

$minMetricsStruct.iWidth=500 #задать новое значение ширины
[controlMINIMIZEDMETRICS.PS]::SystemParametersInfo(0x002C,$size,[ref]$minMetricsStruct,0) #изменим значения 

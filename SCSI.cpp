#define _NTSCSI_USER_MODE_
#define ULONG_PTR ULONG
#include <devioctl.h>
#include <intsafe.h>
#include <iostream>
#include <ntdddisk.h>
#include <ntddscsi.h> //from SDK
#include <scsi.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <strsafe.h>
#include <windows.h>
#include <winioctl.h>
#include "Header.h"

using namespace std;

VOID
PrintDataBuffer(_In_reads_(BufferLength) PUCHAR DataBuffer, _In_ ULONG BufferLength)
{
	ULONG Cnt;

	printf("      00  01  02  03  04  05  06  07   08  09  0A  0B  0C  0D  0E  0F\n");
	printf("      ---------------------------------------------------------------\n");
	for (Cnt = 0; Cnt < BufferLength; Cnt++) {
		if ((Cnt) % 16 == 0) {
			printf(" %03X  ", Cnt);
		}
		printf("%02X  ", DataBuffer[Cnt]);
		if ((Cnt + 1) % 8 == 0) {
			printf(" ");
		}
		if ((Cnt + 1) % 16 == 0) {
			printf("\n");
		}
	}
	printf("\n\n");
}
#define wszDrive L"\\\\.\\PhysicalDrive0"

int main()
{
	HANDLE hDisk;
	SCSI_PASS_THROUGH_DIRECT_WITH_BUFFER sptdwb;
	ULONG length = 0;
	DWORD bytesReturn;
	BYTE bufDataRead[64 * 1024 + 10];
	int iRet;


	hDisk = CreateFile(wszDrive, GENERIC_WRITE | GENERIC_READ,
		FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL
	);
	if (hDisk == INVALID_HANDLE_VALUE) {
		return 0;
	}
	ZeroMemory(&sptdwb, sizeof(SCSI_PASS_THROUGH_DIRECT_WITH_BUFFER));
	sptdwb.sptd.Length = sizeof(SCSI_PASS_THROUGH_DIRECT);
	sptdwb.sptd.CdbLength = 6;
	sptdwb.sptd.DataIn = SCSI_IOCTL_DATA_IN;
	sptdwb.sptd.SenseInfoLength = 24;
	sptdwb.sptd.DataTransferLength = 8;
	sptdwb.sptd.TimeOutValue = 2;
	sptdwb.sptd.DataBuffer = bufDataRead;
	sptdwb.sptd.SenseInfoOffset = offsetof(SCSI_PASS_THROUGH_DIRECT_WITH_BUFFER, ucSenseBuf);
	sptdwb.sptd.Cdb[0] = 0x12; //SCSI Inqury
	sptdwb.sptd.Cdb[1] = 0x01; //evpd bit set
	sptdwb.sptd.Cdb[2] = 0xB2; //page B2 
	sptdwb.sptd.Cdb[3] = 0x00;
	sptdwb.sptd.Cdb[4] = 0xFF;
	sptdwb.sptd.Cdb[5] = 0x00;
	
	length = sizeof(SCSI_PASS_THROUGH_DIRECT_WITH_BUFFER);
	iRet = DeviceIoControl(hDisk,
		IOCTL_SCSI_PASS_THROUGH_DIRECT, //https://docs.microsoft.com/en-us/windows-hardware/drivers/ddi/content/ntddscsi/ni-ntddscsi-ioctl_scsi_pass_through_direct
		&sptdwb,
		length,
		&sptdwb,
		length,
		&bytesReturn,
		NULL);
	if (0 == iRet) {
		printf("inquiry fail");
		return 0;
	}
	else {
		PrintDataBuffer((PUCHAR)(sptdwb.sptd.DataBuffer), 8);
	}
	return 0;
}

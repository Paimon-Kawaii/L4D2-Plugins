#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public void OnPluginStart()
{
	char hostname[256];
	BuildPath(Path_SM, hostname, 256, "configs/hostname/l4d2_hostname.txt");
	Handle file = OpenFile(hostname, "rb");
	if (file)
	{
		char readData[256];
		while (!IsEndOfFile(file))
			ReadFileLine(file, readData, 256);

		FindConVar("hostname").SetString(readData);

		CloseHandle(file);
	}
}
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define MAXSIZE 33
#define VERSION "1.4.7"

Handle
	file;

char
	sPath[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name = "Offlinebanner",
	author = "我是派蒙啊",
	description = "Ban player offline by their steamid",
	version = VERSION,
	url = "http://github.com/PaimonQwQ/L4D2-Plugins/offlinebanner"
};

public void OnPluginStart()
{
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/player_banned.txt");
	CheckFile();
}

public void OnClientPutInServer(int client)
{
	char reason[512];
	if(TryFindBanner(client, reason))
	{
		char[] rejectmsg = "You were banned by Admin. Reason: %s";
		PrintToChatAll("%N has been banned because of \"%s\"", client, reason);
		KickClient(client, rejectmsg, reason);
	}
	CloseHandle(file);
}

bool TryFindBanner(int client, char[] buffer)
{
	CheckFile();
	char steamId[32];
	char bannedSteamIds[8196];
	GetClientAuthId(client, AuthId_Steam2, steamId, 32, true);

	while(!IsEndOfFile(file))
	{
		ReadFileLine(file, bannedSteamIds, 8196);
		int index = StrContains(bannedSteamIds, steamId);
		GetReason(bannedSteamIds, index + 19, buffer);
		if(index != -1) return true;
	}

	return false;
}

void CheckFile()
{
	if(!FileExists(sPath))
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);
	if((file = OpenFile(sPath, "r")) == INVALID_HANDLE)
		SetFailState("\n==========\nOpen file: \"%s\" failed.\n==========", sPath);
}

void GetReason(char[] buffers, int index, char[] reason)
{
	for (int i = index, v = 0; i < strlen(buffers); i++, v++)
	{
		if((buffers[i] == '<' && buffers[i + 1] == '<') || v >= 512)
			break;
		reason[v] = buffers[i];
	}
}
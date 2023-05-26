#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sourcemod>
#include <left4dhooks>

#define PLUGIN_VERSION "2022.3.29"

public Plugin myinfo = 
{
	name = "No Medkits",
	author = "我是派蒙啊",
	description = "Removes Medkits",
	version = PLUGIN_VERSION,
	url = "https://github.com/Attano/L4D2-Competitive-Framework"
};

public void OnPluginStart()
{
	char game[64];
	GetGameFolderName(game, sizeof(game));
	if (!StrEqual(game, "left4dead2", false))
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public void Event_RoundStart(Event hEvent, const char[] name, bool dontBroadcast)
{
	DeleteMedkits();
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	DeleteMedkits();
}

void DeleteMedkits()
{
	char EdictClassName[128];
	for (int i = 0; i <= GetEntityCount(); i++)
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName));
			if (StrContains(EdictClassName, "weapon_first_aid_kit", false) != -1) 
				AcceptEntityInput(i, "Kill");
		}
}

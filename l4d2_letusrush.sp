#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sourcemod>
#include <left4dhooks>

#define VERSION "1.8.3"

int firstdoor = -1;

public Plugin myinfo =
{
	name = "Dooooooooor!!!!!!!!",
	author = "我是派蒙啊",
	description = "Let's RUSH! RUSH!! RUSH!! >_<!!!!!!",
	version = VERSION,
	url = "http://github.com/PaimonQwQ/L4D2-Plugins/l4d2_letsrush.sp",
};

public void OnPluginStart()
{
	HookEvent("player_use", Event_PlayerUse);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	if(IsValidEntity(firstdoor))
	{
		AcceptEntityInput(firstdoor, "Kill");
		firstdoor = -1;
	}
}

public void Event_RoundStart(Event hEvent, const char[] eName, bool dontBroadcast)
{
	int EntityCount = GetEntityCount();
	char EdictClassName[128];
	for (int i = 0; i <= EntityCount; i++)
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, 128);
			if (StrContains(EdictClassName, "prop_door_rotating_checkpoint", false) != -1 
					&& GetEntProp(i, Prop_Send, "m_bLocked", 4) == 1)
				firstdoor = i;
		}
}

public void Event_PlayerUse(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int entity = GetEventInt(event, "targetid");

	if(!IsValidEntity(entity) || entity == firstdoor) return;

	char entName[128];
	GetEdictClassname(entity, entName, sizeof(entName));
	if(StrContains(entName, "prop_door_rotating_checkpoint", false) == -1)
		return;

	AcceptEntityInput(entity, "Open");
	AcceptEntityInput(entity, "Lock");
	SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", 1);

	if(L4D2_IsTankInPlay() || HasSIBotAlive())
		PrintHintTextToAll("你现在不能进屋，附近有特感在游荡(ノдヽ)");
	else if(SurvivorOutsideClient() != client && SurvivorOutsideClient() != -1)
		PrintHintTextToAll("等等(救救)队友吧求求你了(▼皿▼#)");
	else if(!L4D_IsInLastCheckpoint(client))
		PrintHintTextToAll("你只能在屋内关门(≧∀≦)♪");
	else
	{
		SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", 0);
		AcceptEntityInput(entity, "Unlock");
		AcceptEntityInput(entity, "Close");
		AcceptEntityInput(entity, "ForceClosed");
	}
}

bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}

bool HasSIBotAlive()
{
	for(int client = 1; client <= MaxClients; client++)
		if(IsValidClient(client) && IsFakeClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
			return true;
	return false;
}

int SurvivorOutsideClient()
{
	for(int client = 1; client <= MaxClients; client++)
		if(IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 && !L4D_IsInLastCheckpoint(client))
			return client;
	return -1;
}
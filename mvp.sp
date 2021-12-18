#pragma semicolon 1

#include <sdktools>
#include <sourcemod>
#include <left4dhooks>

#define MAXSIZE 33

new TotalDamage[MAXSIZE];
new KillZombies[MAXSIZE];
new KillSpecial[MAXSIZE];
new FriendDamage[MAXSIZE];
new DamageFriend[MAXSIZE];

public void OnPluginStart()
{
	RegConsoleCmd("sm_mvp", MVPinfo, "MVP Msg");
	RegConsoleCmd("sm_kills", MVPinfo, "MVP Msg");
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("finale_win", Event_RoundEnd);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("map_transition", Event_RoundEnd);
	HookEvent("player_death", Event_InfectedDeath);
	HookEvent("infected_death", Event_ZombiesDeath);
}

public Action L4D_OnFirstSurvivorLeftSafeArea()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		KillZombies[i] = 0;
		KillSpecial[i] = 0;
		FriendDamage[i] = 0;
		DamageFriend[i] = 0;
		TotalDamage[i] = 0;
	}
	return Plugin_Continue;
}

public Action MVPinfo(int client, any args)
{
	PrintToChatAll("\x03[MVP统计]");
	ShowMVPMsg();
	return Plugin_Continue;
}

public Action Event_RoundEnd(Handle event, char[] name, bool dontBroadcast)
{
	PrintToChatAll("\x03[MVP统计]");
	ShowMVPMsg();
	return Plugin_Continue;
}

public Action Event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		KillZombies[i] = 0;
		KillSpecial[i] = 0;
		FriendDamage[i] = 0;
		DamageFriend[i] = 0;
		TotalDamage[i] = 0;
	}
	return Plugin_Continue;
}

public Action Event_PlayerHurt(Handle event, char[] name, bool dontBroadcast)
{
	int victimId = GetEventInt(event, "userid", 0);
	int victim = GetClientOfUserId(victimId);
	int attackerId = GetEventInt(event, "attacker", 0);
	int attacker = GetClientOfUserId(attackerId);
	int damageDone = GetEventInt(event, "dmg_health", 0);
	if (IsValidClient(victim) && IsValidClient(attacker) && GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 2 && GetEntProp(victim, PropType:0, "m_isIncapacitated", 4, 0) < 1)
	{
		FriendDamage[attacker] += damageDone;
		DamageFriend[victim] += damageDone;
	}
	if (victimId && attackerId && IsValidClient(victim) && IsValidClient(attacker))
	{
		if (GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 3)
		{
			int zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass", 4, 0);
			if (zombieClass >= 1 && zombieClass < 7)
			{
				if (zombieClass == 1 && damageDone > 250)
					damageDone = 250;
				if (zombieClass == 3 && damageDone > 250)
					damageDone = 250;
				if (zombieClass == 2 && damageDone > 50)
					damageDone = 50;
				if (zombieClass == 6 && damageDone > 600)
					damageDone = 600;
				if (zombieClass == 4 && damageDone > 100)
					damageDone = 100;
				if (zombieClass == 5 && damageDone > 325)
					damageDone = 325;
				TotalDamage[attacker] += damageDone;
			}
		}
	}
	return Plugin_Continue;
}

public Action Event_InfectedDeath(Handle event, char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker", 0));
	int client = GetClientOfUserId(GetEventInt(event, "userid", 0));
	if (IsValidClient(attacker) && IsValidClient(client))
		if (GetClientTeam(attacker) == 2 && GetClientTeam(client) == 3)
			KillSpecial[attacker] += 1;
	return Plugin_Continue;
}

public Action Event_ZombiesDeath(Handle event, char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker", 0));
	if (IsValidClient(attacker) && GetClientTeam(attacker) == 2)
		KillZombies[attacker] += 1;
	return Plugin_Continue;
}

bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

void ShowMVPMsg()
{
	int players = 0;
	int players_clients[MAXSIZE];
	for (int client = 1; client <= MaxClients; client++)
		if (IsClientInGame(client) && GetClientTeam(client) == 2)
		{
			players++;
			players_clients[players] = client;
		}
	SortCustom1D(players_clients, MAXSIZE, SortByDamageDesc);
	for (int i = 0; i <= MaxClients; i++)
	{
		int client = players_clients[i];
		if (IsValidClient(client) && GetClientTeam(client) == 2)
			PrintToChatAll("\x03特感\x04%2d \x03丧尸\x04%3d \x03黑/被黑\x04%2d/%2d \x03伤害\x04%4d \x05%N", KillSpecial[client], KillZombies[client], FriendDamage[client], DamageFriend[client], TotalDamage[client], client);
	}
}

int SortByDamageDesc(int elem1, int elem2, int[] array, Handle hndl)
{
	if (TotalDamage[elem2] < TotalDamage[elem1])
		return -1;
	if (TotalDamage[elem1] < TotalDamage[elem2])
		return 1;
	if (elem1 > elem2)
		return -1;
	if (elem2 > elem1)
		return 1;
	return 0;
}
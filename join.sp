#pragma semicolon 1

#include <sourcemod>

public OnPluginStart()
{
	RegConsoleCmd("sm_away", Cmd_AFKTurnClientToSpe, "Turn player to spectator");
	RegConsoleCmd("sm_join", Cmd_AFKTurnClientToSurvivor, "Turn player to survivor");
}

//玩家加入生还指令
public Action Cmd_AFKTurnClientToSurvivor(int client, any args)
{
	if (!IsValidClient(client)) return;
	
	if (!IsSuivivorTeamFull())
		ChangePlayerSurvivor(client);
}

//设置玩家为生还
void ChangePlayerSurvivor(int client)
{
	if (!IsValidClient(client)) return;
	
	ClientCommand(client, "jointeam survivor");
	if (FindSurvivorBot() > 0)
	{
		int flags = GetCommandFlags("sb_takecontrol");
		SetCommandFlags("sb_takecontrol", flags & -16385);
		FakeClientCommand(client, "sb_takecontrol");
		SetCommandFlags("sb_takecontrol", flags);
	}
}

//玩家进入旁观指令（被控禁止旁观）
public Action Cmd_AFKTurnClientToSpe(int client, any args)
{
	if (!IsValidClient(client)) return;
	
	if (!IsPinned(client))
		CreateTimer(2.5, Timer_CheckAway, client, TIMER_FLAG_NO_MAPCHANGE);
}

//玩家旁观Timer
public Action Timer_CheckAway(Handle timer, int client)
{
	if (!IsValidClient(client) || IsFakeClient(client)) return;

	ChangeClientTeam(client, 1);
}

//生还是否满员
bool IsSuivivorTeamFull()
{
	for (int i = 1; i < MaxClients; i++)
		if (IsValidClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && IsFakeClient(i))
			return false;
			
	return true;
}

//玩家是否被控
bool IsPinned(int client)
{
	if (IsSurvivor(client))
		if (GetEntPropEnt(client, Prop_Send, "m_tongueOwner", 0) > 0    ||
			GetEntPropEnt(client, Prop_Send, "m_carryAttacker", 0) > 0  ||
			GetEntPropEnt(client, Prop_Send, "m_pounceAttacker", 0) > 0 ||
			GetEntPropEnt(client, Prop_Send, "m_pummelAttacker", 0) > 0 ||
			GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker", 0) > 0)
			return true;
	return false;
}

//客户端是否是生还
bool IsSurvivor(client)
{
	if (IsValidClient(client) && GetClientTeam(client) == 2)
		return true;
	
	return false;
}

//Client是否正确
bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}

//获得Bot生还
int FindSurvivorBot()
{
	for (int client = 1; client <= MaxClients; client++)
		if (IsClientInGame(client) && IsFakeClient(client) && GetClientTeam(client) == 2)
			return client;

	return -1;
}

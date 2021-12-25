#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sourcemod>
#include <left4dhooks>

#define MAXSIZE 33
#define VERSION "0.2.3"

int
	infectedSpawnType = 0,
	infectedLimitCount = 0;

float
	infectedSpawnInterval = 0.0;

bool
	isRoundOver = true,
	isSpawnable = true;

ConVar
	infectedLimitConvar,
	infectedSpawnTypeConvar,
	specialRespawnIntervalConvar;

Handle
	Prepare2SpawnHandle = INVALID_HANDLE;

public Plugin myinfo =
{
    name = "SpecialParty",
    author = "我是派蒙啊",
    description = "特感派对！",
    version = VERSION,
    url = "http://anne.paimeng.ltd/l4d2_plugins/l4d2_specialparty.sp"
};

public void OnPluginStart()
{
	HookEvent("finale_win", Event_MissionOver);
	HookEvent("player_death", Event_PlayerDead);
	HookEvent("mission_lost", Event_MissionOver);
	HookEvent("map_transition", Event_MissionOver);

	infectedLimitConvar = FindConVar("l4d_infected_limit");
	specialRespawnIntervalConvar = FindConVar("versus_special_respawn_interval");
	infectedSpawnTypeConvar = CreateConVar("l4d2_infected_type", "6", "特感类型");//1=Smoker, 2=Boomer, 3=Hunter, 4=Spitter, 5=Jockey, 6=Charger 7=witch 8=Tank

	HookConVarChange(infectedLimitConvar, CvarEvent_InfectedLimitChange);
	HookConVarChange(infectedSpawnTypeConvar, CvarEvent_InfectedSpawnTypeChange);
	HookConVarChange(specialRespawnIntervalConvar, CvarEvent_SpecialIntervalChange);

	infectedLimitCount = GetConVarInt(infectedLimitConvar);
	infectedSpawnType = GetConVarInt(infectedSpawnTypeConvar);
	infectedSpawnInterval = GetConVarFloat(specialRespawnIntervalConvar);
}

				/*	########################################
							L4DHookEvent:START==>
				########################################	*/

//玩家离开安全屋事件
public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	PrintHintTextToAll("%N 离开安全屋", client);
	CreateTimer(0.5, Timer_TurnOffDirector, 0, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(1.0, Timer_TurnOffDirector, 0, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(2.0, Timer_TurnOffDirector, 0, TIMER_FLAG_NO_MAPCHANGE);
	Prepare2SpawnHandle = CreateTimer(0.5, Timer_Prepare2Spawn, 0, TIMER_REPEAT);
}

				/*	########################################
							<==L4DHookEvent:END
				########################################	*/


				/*	########################################
							MyHookEvent:START==>
				########################################	*/

//关卡结束
public Action Event_MissionOver(Event event, const char[] name, bool dont_broadcast)
{
	if(Prepare2SpawnHandle != INVALID_HANDLE)
	{
		CloseHandle(Prepare2SpawnHandle);
		Prepare2SpawnHandle = INVALID_HANDLE;
	}

	return Plugin_Continue;
}

//特感死亡
public Action Event_PlayerDead(Event event, const char[] name, bool dont_broadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid", 0));
	if(!IsSI(client)) return Plugin_Continue;

	if(GetSICount() * 2 <= infectedLimitCount)
		isRoundOver = true;

	return Plugin_Continue;
}

				/*	########################################
							<==MyHookEvent:END
				########################################	*/


				/*	########################################
							ConVarEvent:START==>
				########################################	*/

//特感数量改变事件
public void CvarEvent_InfectedLimitChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	infectedLimitCount = GetConVarInt(infectedLimitConvar);
}

//特感类型改变事件
public void CvarEvent_InfectedSpawnTypeChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	infectedSpawnType = GetConVarInt(infectedSpawnTypeConvar);
}

//特感复活时间改变事件
public void CvarEvent_SpecialIntervalChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	infectedSpawnInterval = GetConVarFloat(specialRespawnIntervalConvar);
}

				/*	########################################
							<==ConVarEvent:END
				########################################	*/


				/*	########################################
								Timer:START==>
				########################################	*/

//关闭导演系统
public Action Timer_TurnOffDirector(Handle timer)
{
	SetConVarInt(FindConVar("director_no_specials"), 1, false, false);
	for(int client = 1; client <= MaxClients; client++)
		if(IsSI(client))
			ForcePlayerSuicide(client);
	return Plugin_Continue;
}

//准备生成特感
public Action Timer_Prepare2Spawn(Handle timer)
{
	isSpawnable = !HasSIButNotTankAlive();
	PrintToChatAll("%d %d", isSpawnable, isRoundOver);
	if(isSpawnable && isRoundOver)
		CreateTimer(infectedSpawnInterval, Timer_StartSpwan, 0, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

//开始生成特感
public Action Timer_StartSpwan(Handle timer)
{
	bool survivors[MAXSIZE];
	GetSurvivors(survivors);
	SpawnInfected(survivors);
	isRoundOver = isSpawnable = false;

	return Plugin_Stop;
}

//自动传送
public Action Timer_AutoTeleport(Handle timer, int SIClient)
{
	if(!IsPlayerAlive(SIClient)) return Plugin_Stop;

	int nav;
	float SIPos[3] = 0.0;
	for(int client = 0; client <= MaxClients; client++)
		if(IsSurvivor(client))
		{
			nav = L4D_GetLastKnownArea(client);
			L4D_FindRandomSpot(nav, SIPos);
			break;
		}
	TeleportEntity(SIClient, SIPos, NULL_VECTOR, NULL_VECTOR);

	return Plugin_Continue;
}

				/*	########################################
							<==Timer:END
				########################################	*/


				/*	########################################
							OtherFunctions:START==>
				########################################	*/

//获得生还玩家
void GetSurvivors(bool[] survivors)
{
	for(int client = 1; client <= MaxClients; client++)
		if(IsClientInTeam(client, 2))
			survivors[client] = true;
}

//生成特感
void SpawnInfected(bool[] survivors)
{
	int nav, SIClient;
	float SIPos[3];
	float SIAng[3];
	for(int client = 1; client <= MaxClients; client++)
		if(survivors[client])
		{
			nav = 0;
			SIClient = -1;
			SIPos[0] = SIPos[1] = SIPos[2] = 0.0;
			SIAng[0] = SIAng[1] = SIAng[2] = 0.0;
			nav = L4D_GetLastKnownArea(client);
			L4D_FindRandomSpot(nav, SIPos);
			SIClient = L4D2_SpawnSpecial(infectedSpawnType, SIPos, SIAng);
			//CreateTimer(120.0, Timer_AutoTeleport, SIClient, TIMER_REPEAT);
			survivors[client] = false;
		}
}

//获得特感数量
int GetSICount()
{
	int si = 0;
	for (int i = 1; i <= MaxClients; i++)
		if (IsValidClient(i) && IsFakeClient(i) && IsSI(i))
			si++;
	
	return si;
}

// //获得TankClient
// int GetTankClient()
// {
// 	for(int client = 1; client <= MaxClients; client++)
// 		if(IsValidClient(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == 8)
// 			return client;
//
// 	return -1;
// }

//客户端是否是特感
bool IsSI(int client)
{
	if (IsClientInTeam(client, 3) && !IsTank(client))
		return true;
	
	return false;
}

//客户端是否是生还
bool IsSurvivor(int client)
{
	if (IsValidClient(client) && GetClientTeam(client) == 2)
		return true;
	
	return false;
}

//客户端是否为Tank
bool IsTank(int client)
{
	if(IsValidClient(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == 8)
		return true;

	return false;
}

//客户端是否正确
bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients &&
			 IsClientConnected(client) && IsClientInGame(client));
}

//客户端是否在指定队伍(team)
bool IsClientInTeam(int client, int team)
{
	return (IsValidClient(client) && GetClientTeam(client) == team);
}

//是否还有非克特感存活
bool HasSIButNotTankAlive()
{
	return GetSICount() == 0;
}

				/*	########################################
							<==OtherFunctions:END
				########################################	*/
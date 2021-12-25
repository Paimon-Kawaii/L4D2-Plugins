#pragma semicolon 1
#pragma newdecls required

#include <colors>
#include <sdktools>
#include <sourcemod>
#include <adminmenu>
#include <left4dhooks>

#define MAXSIZE 33
#define VERSION "1.3.9"

int itietie = -1;

public Plugin myinfo =
{
	name = "SmartSpitter",
	author = "我是派蒙啊",
	description = "口水会吐到人多的地方(你喜欢和别人贴贴是吧)",
	version = VERSION,
	url = "http://github.com/PaimonQwQ/L4D2-Plugins/smartspitter.sp",
};

public void OnPluginStart()
{
	//HookEvent("ability_use", Event_AbilityUse2);//无作用，使用时删去.
	HookEvent("ability_use", Event_AbilityUse, EventHookMode_Pre);
}

//PreHook吐痰Event并获取贴贴目标
public Action Event_AbilityUse(Event event, const char[] name, bool dontBroadcast)
{
	char ability[32];
	GetEventString(event, "ability", ability, 32);
	int client = GetClientOfUserId(GetEventInt(event, "userid", 0));
	if(GetEntProp(client, Prop_Send, "m_zombieClass") != 4 || !StrEqual(ability, "ability_spit")) return Plugin_Continue;
	
	itietie = GetTietieSurvivor();
	//PrintToChatAll("%N 贴贴", itietie);

	return Plugin_Continue;
}

//只是用于输出计算的贴贴结果，无其他作用
/*
* 注意：
* 		计算结果可能与输出结果不符，原因是贴贴目标在口水方向上被其他生还挡住，实际结果没有问题。
*		口水不管多远都会跑过去吐到贴贴目标，所以即使旁边有人也不会去吐，斟酌使用。
*/
public Action Event_AbilityUse2(Event event, const char[] name, bool dontBroadcast)
{
	char ability[32];
	GetEventString(event, "ability", ability, 32);
	int client = GetClientOfUserId(GetEventInt(event, "userid", 0));
	if(GetEntProp(client, Prop_Send, "m_zombieClass") != 4 || !StrEqual(ability, "ability_spit")) return Plugin_Continue;
	
	int testtie = GetClientAimTarget(client);
	PrintToChatAll("计算 %N like贴贴 结果 %N like贴贴", itietie, testtie);

	return Plugin_Continue;
}

//口水选择目标时，将目标替换为贴贴目标
public Action L4D2_OnChooseVictim(int specialInfected, int &curTarget)
{
	if(GetEntProp(specialInfected, Prop_Send, "m_zombieClass") != 4 || !IsValidClient(itietie)) return Plugin_Continue;

	curTarget = itietie;
	return Plugin_Changed;
}

//计算一个喜欢贴贴的玩家并返回Client
int GetTietieSurvivor()
{
	int index = 0;
	int tietie = 0;
	int survivors[4];
	float dis[MAXSIZE] = -1.0;
	for(int client = 1; client <= MaxClients; client++)
		if(IsValidClient(client) && GetClientTeam(client) == 2)
			survivors[index++] = client;
	for(int client = 1; client <= MaxClients; client++)
		if(IsValidClient(client) && GetClientTeam(client) == 2)
		{
			dis[client] = 0.0;
			float tiepos[3] = 0.0;
			GetClientAbsOrigin(client, tiepos);
			for(int i = 0; i < 4; i++)
			{
				float pos[3] = 0.0;
				GetClientAbsOrigin(survivors[i], pos);
				dis[client] += GetVectorDistance(tiepos, pos, true);
			}
		}

	for(int i = 0; i < 4; i++)
		if(dis[survivors[tietie]] > dis[survivors[i]])
			if(dis[survivors[i]] != -1.0)
				tietie = i;

	return survivors[tietie];
}

//判断Client是否有效
bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}
/*
 * @Author:             派蒙
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2022-04-14 11:20:56
 * @Last Modified time: 2023-07-14 23:12:17
 * @Github:             http://github.com/PaimonQwQ
 */

#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sourcemod>
#include <paiutils>
#include <left4dhooks>

#define VERSION "2022.06.09"

ConVar
	g_hAngelParty;	  // 0=Disable, 1=Smoker, 2=Boomer, 3=Hunter,
					  // 4=Spitter, 5=Jockey, 6=Charger, 8=Tank
public Plugin myinfo =
{
	name		= "AngelParty",
	author		= "我是派蒙啊",
	description = "AngelServer的特感派对",
	version		= VERSION,
	url			= "http://github.com/PaimonQwQ/L4D2-Plugins/AngelBeats"
};

//插件入口
public void OnPluginStart()
{
	HookEvent("tongue_pull_stopped", Event_TonguePullStopped);

	g_hAngelParty = CreateConVar("angel_party", "0", "特感派对类型");
	g_hAngelParty.SetBounds(ConVarBound_Upper, true, 6.0);
	g_hAngelParty.SetBounds(ConVarBound_Lower, true, 1.0);
}

//替换特感类型
public Action L4D_OnSpawnSpecial(int &zombieClass, const float vecPos[3], const float vecAng[3])
{
	if (g_hAngelParty.IntValue < 1 || g_hAngelParty.IntValue > 6)
		return Plugin_Continue;

	if (L4D2_IsTankInPlay() && GetSurvivorCount() < 4)
		if (GetSInfectedCount() > FindConVar("angel_infected_limit").IntValue / 2)
			return Plugin_Handled;

	zombieClass = g_hAngelParty.IntValue;
	return Plugin_Changed;
}

// TankParty
public void L4D_OnSpawnSpecial_Post(int client, int zombieClass, const float vecPos[3], const float vecAng[3])
{
	if ((g_hAngelParty.IntValue) != 8)
		return;

	L4D_SetClass(client, 8);
}

//处死被刀的舌头
public Action Event_TonguePullStopped(Event event, const char[] name, bool dontBroadcast)
{
	if (g_hAngelParty.IntValue == 0) return Plugin_Continue;

	int attacker = GetClientOfUserId(event.GetInt("victim"));
	int smoker	 = GetClientOfUserId(event.GetInt("smoker"));
	if (event.GetInt("release_type") == 4)
	{
		char weapon[32];
		GetClientWeapon(attacker, weapon, 32);
		float damage = GetPlayerHealth(smoker);
		if (StrEqual(weapon, "weapon_melee", false))
			SDKHooks_TakeDamage(smoker, attacker, attacker, damage);
	}

	return Plugin_Continue;
}
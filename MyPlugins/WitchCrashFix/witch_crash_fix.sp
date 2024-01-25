/*
 * @Author:             我是派蒙啊
 * @Last Modified by: 我是派蒙啊
 * @Create Date:        2023-12-22 20:31:48
 * @Last Modified time: 2024-01-24 18:03:41
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <dhooks>
#include <sdkhooks>
#include <sdktools>
#include <paiutils>
#include <sourcemod>

#define VERSION       "2023.12.26#TEST"
#define GAMEDATA_FILE "witch_crash_fix"

#define DEBUG         0

#define SDKHOOK       1

DynamicDetour
    g_ddWitch_DoAttack;

public Plugin myinfo =
{
    name = "WitchCrashFix",
    author = "我是派蒙啊",
    description = "",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins/MyPlugins"
};

//插件入口
public void OnPluginStart()
{
    // #if SDKHOOK
    // 	HookEvent("player_death", Event_PlayerDead);
    // #endif

    GameData gamedata = new GameData(GAMEDATA_FILE);
    if (gamedata == null)
        SetFailState("Gamedata not found: \"%s\".", GAMEDATA_FILE);
    CreateDetour(gamedata, g_ddWitch_DoAttack, DTR_Witch_DoAttack, "L4D2::Witch::DoAttack");
}

// #if SDKHOOK
// void Event_PlayerDead(Event event, const char[] name, bool dontBroadcast)
// {
// 	int client = GetClientOfUserId(event.GetInt("userid"));
// 	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
// }
// #endif

void CreateDetour(GameData gamedata, DynamicDetour &detour, DHookCallback callback, const char[] name, bool post = false)
{
    detour = DynamicDetour.FromConf(gamedata, name);
    if (!detour) LogError("Failed to load detour \"%s\" signature.", name);

    if (callback != INVALID_FUNCTION && !detour.Enable(post ? Hook_Post : Hook_Pre, callback))
        LogError("Failed to detour \"%s\".", name);
}

MRESReturn DTR_Witch_DoAttack(int pThis, DHookReturn returns, DHookParam params)
{
    if (params.IsNull(1))
    {
        DHookSetReturn(returns, true);
#if DEBUG
        PrintToChatAll("[WitchCrashFix] 空指针异常！已处死Witch(%d)", pThis);
#endif
        KillEntity(pThis);
        return MRES_Supercede;
    }

    int entity = params.Get(1);
    if (!IsValidClient(entity)) return MRES_Ignored;

#if SDKHOOK
    SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
    DHookSetReturn(returns, true);
    return MRES_Override;
// #else
// 	DataPack data = new DataPack();
// 	data.WriteCell(entity);
// 	data.WriteCell(pThis);
// 	CreateTimer(0.2, Timer_MemoryOutHandle, data, TIMER_FLAG_NO_MAPCHANGE);
// 	return MRES_Handled;
#endif
}

void KillEntity(int iEntity)
{
#if SOURCEMOD_V_MINOR > 8
    RemoveEntity(iEntity);
#else
    AcceptEntityInput(iEntity, "Kill");
#endif
}

#if SDKHOOK
Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
    if (!IsWitch(attacker)) return Plugin_Continue;

    // DataPack data = new DataPack();
    // data.WriteCell(victim);
    // data.WriteFloat(damage);
    // data.WriteCell(attacker);

    // CreateTimer(0.2, Timer_MemoryOutHandle, data, TIMER_FLAG_NO_MAPCHANGE);

    if (FindConVar("god").BoolValue)
    {
        PrintToChatAll("检测到无敌模式开启，跳过溢出处理");
        return Plugin_Handled;
    }
    if (!IsValidClient(victim) || !IsPlayerAlive(victim))
    {
        if (IsValidEntity(attacker)) KillEntity(attacker);
        return Plugin_Handled;
    }

    char difficulty[32];
    FindConVar("z_difficulty").GetString(difficulty, sizeof(difficulty));

    if (!IsPlayerIncap(victim))
    {
        SetEntProp(victim, Prop_Send, "m_isIncapacitated", 1);
        SetEntityHealth(victim, 300);
        if (strcmp(difficulty, "Impossible", false) == 0)
            SetEntProp(victim, Prop_Send, "m_bIsOnThirdStrike", 1);
    }
    else if (IsDeadAfterATK(victim, damage))
    {
        PrintToChatAll("检测到溢出条件：Witch(%d) 杀死 %N，已成功拦截", attacker, victim);
        SetEntProp(victim, Prop_Send, "m_bIsOnThirdStrike", 1);
        KillEntity(attacker);

        return Plugin_Handled;
    }

    return Plugin_Continue;
}
#endif

// Action Timer_MemoryOutHandle(Handle timer, DataPack data)
// {
// 	data.Reset();
// 	int client = data.ReadCell();
// #if SDKHOOK
// 	float damage = data.ReadFloat();
// // #else
// // 	float damage = FindConVar("z_witch_damage").FloatValue;
// #endif
// 	int witch = data.ReadCell();
// 	delete data;

// 	if (FindConVar("god").BoolValue)
// 	{
// 		PrintToChatAll("检测到无敌模式开启，跳过溢出处理");
// 		return Plugin_Stop;
// 	}
// 	if (!IsValidClient(client) || !IsPlayerAlive(client))
// 	{
// 		if (IsValidEntity(witch)) KillEntity(witch);
// 		return Plugin_Stop;
// 	}

// 	char difficulty[32];
// 	// #if !SDKHOOK
// 	// 	float range = FindConVar("z_witch_attack_range").FloatValue;
// 	// #endif
// 	FindConVar("z_difficulty").GetString(difficulty, sizeof(difficulty));

// 	if (!IsPlayerIncap(client))
// 	{
// 		SetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
// 		SetEntityHealth(client, 300);
// 		if (strcmp(difficulty, "Impossible", false) == 0)
// 			SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
// 	}
// 	else
// 	{
// 		if (IsDeadAfterATK(client, damage))
// 		{
// 			PrintToChatAll("检测到溢出条件：Witch(%d) 杀死 %N", witch, client);
// 			SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
// 			KillEntity(witch);

// 			return Plugin_Stop;
// 		}
// 		// #if !SDKHOOK
// 		// 		if (IsValidEntity(witch) && GetEntityDistance(client, witch) > range) return Plugin_Stop;
// 		// #endif
// 		SDKHooks_TakeDamage(client, 0, 0, damage);
// 	}

// 	return Plugin_Stop;
// }

#if SDKHOOK
bool IsWitch(int iEntity)
{
    if (iEntity < 1 || !IsValidEdict(iEntity))
    {
        return false;
    }

    char sClassName[MAX_NAME_LENGTH];
    GetEdictClassname(iEntity, sClassName, sizeof(sClassName));
    return (strncmp(sClassName, "witch", 5) == 0);    // witch and witch_bride
}
#endif

bool IsDeadAfterATK(int client, float damage)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client) || (!IsPlayerIncap(client) && !IsPlayerOnThirdStrike(client))) return false;

    return GetPlayerHealth(client, _, true) <= damage;
}
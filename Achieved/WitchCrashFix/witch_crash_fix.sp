/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-12-22 20:31:48
 * @Last Modified time: 2024-09-06 22:23:28
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <paiutils>

#define VERSION       "2023.12.26#TEST"
#define GAMEDATA_FILE "witch_crash_fix"

#define DEBUG         1

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
    GameData gamedata = new GameData(GAMEDATA_FILE);
    if (gamedata == null)
        SetFailState("Gamedata not found: \"%s\".", GAMEDATA_FILE);
    CreateDetour(gamedata, g_ddWitch_DoAttack, DTR_Witch_DoAttack, "L4D2::Witch::DoAttack");
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

    SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
    DHookSetReturn(returns, true);
    return MRES_Override;
}

void KillEntity(int iEntity)
{
#if SOURCEMOD_V_MINOR > 8
    RemoveEntity(iEntity);
#else
    AcceptEntityInput(iEntity, "Kill");
#endif
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
    if (!IsWitch(attacker)) return Plugin_Continue;

    if (FindConVar("god").BoolValue)
    {
#if DEBUG
        PrintToChatAll("检测到无敌模式开启，跳过溢出处理");
#endif
        SDKUnhook(victim, SDKHook_OnTakeDamage, OnTakeDamage);
        return Plugin_Handled;
    }
    if (!IsValidClient(victim) || !IsPlayerAlive(victim))
    {
        if (IsValidEntity(attacker)) KillEntity(attacker);
        SDKUnhook(victim, SDKHook_OnTakeDamage, OnTakeDamage);
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
#if DEBUG
        PrintToChatAll("检测到溢出条件：Witch(%d) 杀死 %N，已成功拦截", attacker, victim);
#endif
        SetEntProp(victim, Prop_Send, "m_bIsOnThirdStrike", 1);
        SDKUnhook(victim, SDKHook_OnTakeDamage, OnTakeDamage);
        KillEntity(attacker);

        return Plugin_Handled;
    }

    return Plugin_Continue;
}

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

bool IsDeadAfterATK(int client, float damage)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client) || (!IsPlayerIncap(client) && !IsPlayerOnThirdStrike(client))) return false;

    return GetPlayerHealth(client, _, true) <= damage;
}
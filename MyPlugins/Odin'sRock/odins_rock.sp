/*
 * @Author:             我是派蒙啊
 * @Last Modified by: 我是派蒙啊
 * @Create Date:        2023-03-18 14:59:54
 * @Last Modified time: 2024-01-25 14:21:34
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <paiutils>
#include <sourcemod>
#include <left4dhooks>

#define VERSION "2024.01.25"
#define DEBUG   0

ConVar
    g_hOdinsRock,
    g_hOdinsTrick,
    g_hOdinsTime,
    g_hOdinsHuman,

    g_hOdinsPunch,
    g_hOdinsPunchH,

    g_hOdinsTeleport;

bool g_bIsRockTime[MAXPLAYERS + 1] = { true, ... };

public Plugin myinfo =
{
    name = "Odin's Rock",
    author = "我是派蒙啊",
    description = "因果律石头ww",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins/MyPlugins"
};

public void OnPluginStart()
{
    g_hOdinsRock = CreateConVar("odins_rock", "1", "开关因果律武器ww", _, true, 0.0, true, 1.0);
    g_hOdinsTeleport = CreateConVar("odins_tp", "0", "克在丢石后是否会传送到玩家", _, true, 0.0, true, 1.0);
    g_hOdinsHuman = CreateConVar("odins_rock_human", "0", "玩家Tank是否可以使用", _, true, 0.0, true, 1.0);
    g_hOdinsTime = CreateConVar("odins_time", "5", "AI克自动丢石时间");
    g_hOdinsTrick = CreateConVar("odins_trick", "5", "奥丁之饼伤害", _, true, 0.0);
    g_hOdinsPunch = CreateConVar("odins_rock_punch", "600", "石头的冲击力");
    g_hOdinsPunchH = CreateConVar("odins_rock_punch_h", "260", "石头的垂直击飞力度");

    AutoExecConfig(_, "odins_rock");
}

public void OnMapStart()
{
    for (int i = 0; i <= MaxClients; i++)
        g_bIsRockTime[i] = true;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impuls)
{
    if (!IsTank(client) || !g_hOdinsRock.BoolValue || !IsFakeClient(client)) return Plugin_Continue;

    if (g_bIsRockTime[client] /*&& !IsEntitySawThreats(client)*/)
    {
        g_bIsRockTime[client] = false;
        buttons |= IN_ATTACK2;
        CreateTimer(g_hOdinsTime.FloatValue, Timer_ResetRockTime, client, TIMER_FLAG_NO_MAPCHANGE);

        return Plugin_Changed;
    }

    return Plugin_Continue;
}

/* --------------------------------------
 *             GOD BLESS YOU...
 * -------------------------------------- */
public Action L4D_TankRock_OnRelease(int tank, int rock, float vecPos[3], float vecAng[3], float vecVel[3], float vecRot[3])
{
    if (!g_hOdinsRock.BoolValue || !IsTank(tank))
        return Plugin_Continue;

#if DEBUG
    PrintToChatAll("%N 释放了石头", tank);
#endif

    if (!IsFakeClient(tank) && !g_hOdinsHuman.BoolValue)
        return Plugin_Continue;

    int target;
    if (IsTank(tank))
        target = GetClientAimTarget(tank);

    float pos[3];
    if (!IsSurvivor(target) && IsTank(tank))
    {
        GetClientEyePosition(tank, pos);
        target = GetNearestSurvivor(pos);
    }

    if (!IsSurvivor(target))
        target = GetNearestSurvivor(vecPos);

#if DEBUG
    PrintToChatAll("%N 被石头锁定", target);
#endif

    if (!IsSurvivor(target))
        return Plugin_Continue;

    SDKHook(target, SDKHook_OnTakeDamage, OnTakeDamage);

    PrintHintText(target, "奥丁之饼降临ww");
    for (int i = 1; i <= MaxClients; i++)
        if (IsValidClient(i) && i != target)
            PrintHintText(i, "奥丁：%N 饿了，请你吃饼ww", target);
    GetClientEyePosition(target, pos);
    for (int i = 0; i < 3; i++)
        vecPos[i] = pos[i];
    vecPos[2] += 10;

    pos[0] += 20;
    pos[2] += 100;
    if (IsTank(tank) && g_hOdinsTeleport.BoolValue)
        TeleportEntity(tank, pos, NULL_VECTOR, NULL_VECTOR);

    return Plugin_Changed;
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
    if (!IsTankRock(inflictor)) return Plugin_Continue;

    damage = g_hOdinsTrick.FloatValue;

    if (!IsTank(attacker)) return Plugin_Continue;
    float velocity[3], pos1[3], pos2[3];
    GetClientAbsOrigin(attacker, pos1);
    GetClientAbsOrigin(victim, pos2);
    MakeVectorFromPoints(pos1, pos2, velocity);
    NormalizeVector(velocity, velocity);
    ScaleVector(velocity, g_hOdinsPunch.FloatValue);
    velocity[2] = (velocity[2] > 0 ? velocity[2] : 0.0) + g_hOdinsPunchH.FloatValue;

    DataPack data = new DataPack();
    data.WriteCell(victim);
    data.WriteFloatArray(velocity, 3);
    CreateTimer(0.01, Timer_RockImpact, data, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Changed;
}

Action Timer_RockImpact(Handle timer, DataPack data)
{
    data.Reset();
    float velocity[3], curvel[3];
    int victim = data.ReadCell();
    data.ReadFloatArray(velocity, 3);

    GetEntPropVector(victim, Prop_Data, "m_vecAbsVelocity", curvel);
    if (curvel[0] != 0 || curvel[1] != 0)
    {
        delete data;
        return Plugin_Stop;
    }

    TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, velocity);
    return Plugin_Continue;
}

Action Timer_ResetRockTime(Handle timer, int client)
{
    g_bIsRockTime[client] = true;

    return Plugin_Stop;
}

int GetNearestSurvivor(const float pos[3])
{
    int target;
    float dis = -1.0, surPos[3];
    for (int i = 1; i < MaxClients; i++)
        if (IsSurvivor(i) && IsPlayerAlive(i) && !IsPlayerIncap(i))
        {
            GetClientAbsOrigin(i, surPos);
            float tmp = GetVectorDistance(pos, surPos, true);
            if (dis > tmp || dis == -1)
            {
                dis = tmp;
                target = i;
            }
        }

    return target;
}

bool IsTankRock(int entity)
{
    if (entity <= MaxClients || !IsValidEdict(entity))
        return false;

    char classname[MAX_NAME_LENGTH];
    GetEdictClassname(entity, classname, sizeof(classname));
    return (strcmp(classname, "tank_rock") == 0);
}
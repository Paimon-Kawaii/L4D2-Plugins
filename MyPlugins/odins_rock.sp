/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-03-18 14:59:54
 * @Last Modified time: 2023-06-27 22:00:12
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <l4d2tools>
#include <sourcemod>
#include <left4dhooks>

#define VERSION "2023.04.13"
#define DEBUG 0

ConVar g_hOdinsRock, g_hOdinsHuman, g_hOdinsTeleport;
bool g_bIsRockTime[MAXPLAYERS + 1] = {true, ...};

public Plugin myinfo =
{
    name = "Odin's Rock",
    author = "我是派蒙啊",
    description = "因果律石头(笑",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins/MyPlugins"
};

public void OnPluginStart()
{
    g_hOdinsRock = CreateConVar("odins_rock", "0", "开关因果律武器(笑");
    g_hOdinsHuman = CreateConVar("odins_hunman", "0", "开关因果律武器(笑");
    g_hOdinsTeleport = CreateConVar("odins_tp", "0", "开关因果律武器(笑");
}

public void OnMapStart()
{
    for(int i = 0; i <= MaxClients; i++)
        g_bIsRockTime[i] = true;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impuls)
{
    if(!IsTank(client)) return Plugin_Continue;

    if(g_hOdinsRock.BoolValue && g_bIsRockTime[client] && IsFakeClient(client) && !CanPlayerSeeThreats(client))
    {
        g_bIsRockTime[client] = false;
        buttons |= IN_ATTACK2;
        CreateTimer(10.0, Timer_ResetRockTime, client, TIMER_FLAG_NO_MAPCHANGE);

        return Plugin_Changed;
    }

    return Plugin_Continue;
}

public Action L4D_TankRock_OnRelease(int tank, int rock, float vecPos[3], float vecAng[3], float vecVel[3], float vecRot[3])
{
    if(!g_hOdinsRock.BoolValue || !IsTank(tank))
        return Plugin_Continue;

#if DEBUG
    PrintToChatAll("%N 释放了石头", tank);
#endif

    if(!IsFakeClient(tank) && !g_hOdinsHuman.BoolValue)
        return Plugin_Continue;

    int target;
    if(IsTank(tank))
        target = GetClientAimTarget(tank);

    float pos[3];
    if(!IsSurvivor(target) && IsTank(tank))
    {
        GetClientEyePosition(tank, pos);
        target = GetNearestSurvivor(pos);
    }

    if(!IsSurvivor(target))
        target = GetNearestSurvivor(vecPos);

#if DEBUG
    PrintToChatAll("%N 被石头锁定", target);
#endif

    if(!IsSurvivor(target))
        return Plugin_Continue;

    PrintHintText(target, "奥丁之饼降临(笑");
    for(int i = 1; i <= MaxClients; i++)
        if(IsValidClient(i) && i != target)
            PrintHintText(i, "奥丁：%N 饿了，请你吃饼(笑", target);
    GetClientAbsOrigin(target, pos);
    for(int i = 0; i < 3; i++)
        vecPos[i] = pos[i];
    vecPos[2] += 10;

    pos[0] += 20;
    pos[2] += 100;
    if(IsTank(tank) && g_hOdinsTeleport.BoolValue)
        TeleportEntity(tank, pos, NULL_VECTOR, NULL_VECTOR);

    return Plugin_Changed;
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
    for(int i = 1; i < MaxClients; i++)
        if(IsSurvivor(i) && IsPlayerAlive(i) && !IsPlayerIncap(i))
        {
            GetClientAbsOrigin(i, surPos);
            float tmp = GetVectorDistance(pos, surPos, true);
            if(dis > tmp || dis == -1)
            {
                dis = tmp;
                target = i;
            }
        }

    return target;
}
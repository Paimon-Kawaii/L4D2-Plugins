/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-06-05 18:00:29
 * @Last Modified time: 2023-06-06 20:25:38
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sourcemod>
// #include <l4d2tools>

#define VERSION "2023.06.05"
#define MAXSIZE MAXPLAYERS + 1
#define DEBUG 0

ConVar
    g_hABHLimit,
    g_hABHEnable;

bool
    g_bABHLock[MAXSIZE] = {false, ...},
    g_bABHReset[MAXSIZE] = {false, ...};

float
    g_fSurABHSpeed[MAXSIZE] = {0.0, ...},
    g_fSurLastSpeed[MAXSIZE] = {0.0, ...};

public Plugin myinfo =
{
    name = "ABH for l4d",
    author = "我是派蒙啊",
    description = "在 L4D 中使用 ABH 技巧",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins"
}

// 注册ConVar
public void OnPluginStart()
{
    g_hABHEnable = CreateConVar("l4d_abh_enable", "1", "ABH 开关", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hABHLimit = CreateConVar("l4d_abh_maxspeed", "2000", "ABH 最大空速", FCVAR_NONE, true, 0.0, true, 9999.0);

    AutoExecConfig(true, "l4d_abh");
}

// ABH加速
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float ang[3])
{
    if(!IsSurvivor(client) || !IsPlayerAlive(client) || !g_hABHEnable.BoolValue)
        return Plugin_Continue;

    bool isgrounded = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") != -1;
    if((~buttons & (IN_BACK | IN_JUMP)) || !isgrounded)
    {
        g_bABHLock[client] = false;
        return Plugin_Continue;
    }
    if(g_bABHLock[client]) return Plugin_Continue;

    g_bABHLock[client] = true;
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
    float speed = SquareRoot(Pow(vel[0], 2.0) + Pow(vel[1], 2.0));
    if(speed < FloatAbs(g_fSurLastSpeed[client]))
        g_bABHReset[client] = true;

    float fwd[3], right[3], up[3], result[3] = { 0.0, ... };
    GetAngleVectors(ang, fwd, right, up);

    g_fSurLastSpeed[client] = g_fSurABHSpeed[client];
    if(FloatAbs(g_fSurABHSpeed[client]) < speed || g_bABHReset[client])
        g_fSurABHSpeed[client] = -speed;
    else if(g_hABHLimit.FloatValue > FloatAbs(g_fSurABHSpeed[client]))
        g_fSurABHSpeed[client] *= view_as<bool>(buttons & IN_DUCK) ? 1.6 : 1.2;

    ScaleVector(fwd, g_fSurABHSpeed[client]);
#if DEBUG
    PrintToChat(client, "st %.2f sp %.2f v %.2f", g_fSurLastSpeed[client], g_fSurABHSpeed[client], speed);
#endif
    AddVectors(fwd, result, result);
    AddVectors(right, result, result);
    AddVectors(up, result, result);
    result[2] = vel[2];

    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, result);
    g_bABHReset[client] = false;
    return Plugin_Changed;
}

/**
 * @brief Returns true if client is correct.
 *
 * @param client    Client index.
 * @return          True if client is correct. False otherwise.
 */
bool IsValidClient(int client)
{
    return (0 < client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}

/**
 * @brief Returns true if client is a survivor.
 * 
 * @param client    Client index.
 * @return          True if client is a survivor. False otherwise.
 */
bool IsSurvivor(int client)
{
    return (IsValidClient(client) && GetClientTeam(client) == 2);
}
/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-03-06 19:29:00
 * @Last Modified time: 2023-07-14 23:12:16
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sdkhooks>
#include <sourcemod>
#include <paiutils>

#define VERSION "2023.03.06"

ConVar
    g_hTankBhop,
    g_hTankDamage,
    g_hRockDamage,
    g_hTankBhopStop,
    g_hTankBhopPower;

public Plugin myinfo =
{
    name = "Tank Damage",
    author = "我是派蒙啊",
    description = "克伤害修改",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins/MyPlugins"
};

//插件入口
public void OnPluginStart()
{
    g_hTankBhop = CreateConVar("tank_bhop", "1", "");
    g_hTankDamage = CreateConVar("tank_damage", "24", "");
    g_hRockDamage = CreateConVar("tank_rock_damage", "24", "");
    g_hTankBhopStop = CreateConVar("tank_bhop_stop_dis", "50", "");
    g_hTankBhopPower = CreateConVar("tank_bhop_power", "120", "");
    g_hTankDamage.SetBounds(ConVarBound_Lower, true, 0.0);
    g_hRockDamage.SetBounds(ConVarBound_Lower, true, 0.0);
    AutoExecConfig(true, "tank_damage");
}

//在插件加载完毕后
public void OnAllPluginsLoaded()
{
    for (int i = 1; i <= MaxClients; i++)
        if (IsValidClient(i) && IsClientInGame(i))
            SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
}

//玩家加载完毕(检查是否为管理员是在完成载入后)
public void OnClientPostAdminCheck(int client)
{
    if (IsValidClient(client))
        SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

//克连跳
public Action OnPlayerRunCmd(int client, int &buttons, int &impuls)
{
    if (!IsValidClient(client))
        return Plugin_Continue;
    int flags = GetEntityFlags(client);
    if (!g_hTankBhop.BoolValue || !(IsTank(client) && (flags & FL_ONGROUND)))
        return Plugin_Continue;

    float tpos[3], spos[3];
    int sur = GetClientAimTarget(client);
    if (!IsValidClient(sur))
        return Plugin_Continue;
    GetClientAbsOrigin(sur, spos);
    GetClientAbsOrigin(client, tpos);
    float dis = GetVectorDistance(tpos, spos, false);
    if (dis < g_hTankBhopStop.FloatValue)
        return Plugin_Continue;

    buttons |= IN_JUMP;
    buttons |= IN_DUCK;
    buttons |= IN_ATTACK;

    float vec[3] = {0.0};
    SubtractVectors(spos, tpos, vec);
    NormalizeVector(vec, vec);
    ScaleVector(vec, g_hTankBhopPower.FloatValue);
    TankBhop(client, buttons, vec);

    return Plugin_Continue;
}

void TankBhop(int client, int &buttons, float vec[3])
{
    if (!(buttons & IN_FORWARD || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT))
        return;

    float vel[3] = {0.0};
    GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vel);
    AddVectors(vel, vec, vel);
    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
}

//Tank伤害更改
Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damageType, int &weapon, float damageForce[3], float damagePosition[3])
{
    if(IsSurvivor(victim) && IsTank(attacker))
    {
        damage = IsTankRock(inflictor) ? g_hRockDamage.FloatValue : g_hTankDamage.FloatValue;
        return Plugin_Changed;
    }

    return Plugin_Continue;
}

//是否是石头
bool IsTankRock(int entity)
{
    if (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity))
    {
        char name[64];
        GetEdictClassname(entity, name, sizeof(name));
        return StrEqual(name, "tank_rock");
    }

    return false;
}
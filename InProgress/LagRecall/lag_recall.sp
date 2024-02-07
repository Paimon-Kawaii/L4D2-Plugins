/*
 * @Author: 我是派蒙啊
 * @Last Modified by: 我是派蒙啊
 * @Create Date: 2024-02-02 19:02:53
 * @Last Modified time: 2024-02-07 19:51:57
 * @Github: https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <dhooks>
#include <paiutils>
#include <sdktools>
#include <anim_bone>
#include <sourcemod>
#include <left4dhooks>

#define VERSION "2024.02.07"

public Plugin myinfo =
{
    name = "LagRecall",
    author = "我是派蒙啊",
    description = "修正高延迟射击",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins/MyPlugins"
};

#define DEBUG          0
#define DEBUG_LOCAL    0
#define DEBUG_HEAD_POS 0

#if DEBUG_LOCAL
    #include <debug_draw>
#endif

#if DEBUG
    #include <vector_show.sp>
#endif

#define INVALID_CLIENT        -1
#define INVALID_DISTANCE      -1.0

#define MAXSIZE               MAXPLAYERS + 1
#define MAX_CLASSNAME_LENGTH  23
#define MAX_DISTANCE_LAG_SHOT 15

static int
    g_iShootTarget[MAXSIZE] = { -1, ... };

static char
    g_sWeaponNames[][] = {
        "weapon_pistol",
        "weapon_pistol_magnum",

        "weapon_smg",
        "weapon_smg_silenced",

        "weapon_rifle_desert",
        "weapon_rifle_ak47",
        "weapon_rifle_sg552",
        "weapon_sniper_military",

        "weapon_rifle",
        "weapon_hunting_rifle",
        "weapon_sniper_awp",
        "weapon_sniper_scout",

        "weapon_rifle_m60",
    };
#define WEAPON_COUNT 13

bool CheckWeapon(int weapon, char[] clsname, int len)
{
    if (!IsValidEntity(weapon)) return false;

    GetEntityClassname(weapon, clsname, len);
    bool flag = false;
    for (int i = 0; i < WEAPON_COUNT; i++)
    {
        if (strcmp(g_sWeaponNames[i], clsname) != 0) continue;
        flag = true;
        break;
    }

    return flag;
}

// #if DEBUG_HEAD_POS && DEBUG_LOCAL
// public Action OnPlayerRunCmd(int client, int &buttons)
// {
//     if (!IsInfected(client)) return Plugin_Continue;

//     float origin[3];
//     float netlag = GetClientAvgLatency(1, NetFlow_Both) / 1000 + GetLerpTime(1);
//     GetBoneLagPosition(client, Bone_Head, origin, netlag);
//     DebugDrawCross(origin);

//     if (GetZombieClass(client) == ZC_HUNTER)
//     {
//         buttons = IN_DUCK;
//         if (!(GetEntProp(client, Prop_Data, "m_nOldButtons") & IN_ATTACK))
//             buttons |= IN_ATTACK;
//     }

//     return Plugin_Changed;
// }
// #endif

Action TEHook_Bullets(const char[] te_name, const int[] Players, int numClients, float delay)
{
#if DEBUG_HEAD_POS
    return Plugin_Continue;
#endif

    int client = TE_ReadNum("m_iPlayer");
#if DEBUG_LOCAL
    if (!client) client = 1;
#endif
    if (!IsSurvivor(client)) return Plugin_Continue;
    g_iShootTarget[client] = -1;

    // Check weapon.
    static char clsname[MAX_CLASSNAME_LENGTH];
    int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (!CheckWeapon(weapon, clsname, MAX_CLASSNAME_LENGTH))
        return Plugin_Continue;

    // Get origin and direction-angle.
    static float origin[3], angle[3];
    TE_ReadVector("m_vecOrigin", origin);
    angle[0] = TE_ReadFloat("m_vecAngles[0]");
    angle[1] = TE_ReadFloat("m_vecAngles[1]");
#if DEBUG
    ShowAngle(2, origin, angle, 1.0, 1000.0, 0.1, 0.1);
#endif

    // Get direction vector.
    static float s[3], sLen;
    GetAngleVectors(angle, s, NULL_VECTOR, NULL_VECTOR);
    NormalizeVector(s, s);    // 方向向量: s = {l, m, n}
    sLen = GetVectorLength(s);

    // Get lag time
    float ping = GetClientAvgLatency(client, NetFlow_Both);
    float lerp = GetLerpTime(client);
#if DEBUG
    PrintToChatAll("%N ping: %.2fms lerp: %.2fms", client, ping, lerp * 1000);
#endif
    float netlag = ping / 1000 + lerp;

    static float temp[3], oe[3];
    int target = INVALID_CLIENT;
    float distance = INVALID_DISTANCE;
    // Find closest SI recalled by lag time.
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!(IsInfected(i) && IsPlayerAlive(i))) continue;

        GetBoneLagPosition(i, Bone_Head, temp, netlag);    //回溯位置
        MakeVectorFromPoints(temp, origin, oe);            //向量oe = origin - eye
        // 点到直线距离: d = |s × oe|/|s|
        // The distance from point to ray.
        GetVectorCrossProduct(s, oe, temp);
        float dis = GetVectorLength(temp) / sLen;
        if (dis < distance || distance == INVALID_DISTANCE)
        {
            distance = dis;
            target = i;
        }    // Get min distance.
    }
    if (!IsValidClient(target) || IsTank(target)) return Plugin_Continue;

#if DEBUG
    GetClientEyePosition(target, temp);
    MakeVectorFromPoints(temp, origin, oe);    //向量oe = origin - eye
    // 点到直线距离: d = |s × oe|/|s|
    GetVectorCrossProduct(s, oe, temp);
    float realDis = GetVectorLength(temp) / sLen;
    PrintToChatAll("%N aim %N dis: %.2f real_dis: %.2f", client, target, distance, realDis);
#endif

    if (distance > MAX_DISTANCE_LAG_SHOT) return Plugin_Continue;
    g_iShootTarget[client] = target;

    float damage = GetWeaponDamage(clsname, distance) * 4;

#if DEBUG
    int heal = GetPlayerHealth(target);
#endif
    SDKHooks_TakeDamage(target, client, client, damage, DMG_BULLET, weapon);
#if DEBUG
    PrintToChatAll("%N 对 %N 造成 %d 伤害(%.5f)", client, target, heal - GetPlayerHealth(target), damage);
#endif
    return Plugin_Continue;
}

void GetBoneLagPosition(int client, Bone_Type bone_type, float origin[3], float lag)
{
    static float velocity[3];
    int bone = L4D_GetZombieBone(client, bone_type);
    L4D_GetBonePosition(client, bone, origin);
    GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", velocity);
    ScaleVector(velocity, (lag + 0.04) * -1);    // 0.04s is the engine lag time
    // 回溯延迟时间后特感位置
    AddVectors(origin, velocity, origin);    // Get SI's position in lag time past.
}

float GetWeaponDamage(const char[] clsname, float distance)
{
    int damage;
    float range, rangeModifier, gainRange, final_damage;
    damage = L4D2_GetIntWeaponAttribute(clsname, L4D2IWA_Damage);
    range = L4D2_GetFloatWeaponAttribute(clsname, L4D2FWA_Range);
    rangeModifier = L4D2_GetFloatWeaponAttribute(clsname, L4D2FWA_RangeModifier);
    gainRange = L4D2_GetFloatWeaponAttribute(clsname, L4D2FWA_GainRange);

    if (distance <= gainRange)
        final_damage = CalculateDamage(damage, rangeModifier, distance);
    else if (distance <= range) final_damage = CalculateGainDamage(damage, range, rangeModifier, gainRange, distance);
    else final_damage = 0.0;

    return final_damage;
}

float CalculateDamage(int damage, float rangeModifier, float distance)
{
    // 0~1500
    // f(x) = dmg * pow(rm, distance / 500)
    return damage * Pow(rangeModifier, distance / 500);
}

float CalculateGainDamage(int damage, float range, float rangeModifier, float gainRange, float distance)
{
    // 1500~range
    // f1(x) = f(x) * ((r - distance) / (r - gr))
    return CalculateDamage(damage, rangeModifier, distance) * ((range - distance) / (range - gainRange));
}

#if DEBUG
Action TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
    int heal = GetPlayerHealth(victim);
    SDKHooks_TakeDamage(victim, inflictor, attacker, damage, damagetype, GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon"));
    PrintToChatAll("%N take %.2f dmg(%d) (%d)(%d)", victim, damage, heal - GetPlayerHealth(victim), inflictor, attacker);

    return Plugin_Continue;
}

public void OnAllPluginsLoaded()
{
    for (int i = 1; i <= MaxClients; i++)
        if (IsValidClient(i) && IsClientConnected(i))
            SDKHook(i, SDKHook_TraceAttack, TraceAttack);
}

public void OnClientConnected(int client)
{
    SDKHook(client, SDKHook_TraceAttack, TraceAttack);
}
#endif

ConVar
    g_cvMinUpdateRate,
    g_cvMaxUpdateRate,
    g_cvMinInterpRatio,
    g_cvMaxInterpRatio;

public void OnPluginStart()
{
    AddTempEntHook("Bullets", TEHook_Bullets);

    g_cvMinUpdateRate = FindConVar("sv_minupdaterate");
    g_cvMaxUpdateRate = FindConVar("sv_maxupdaterate");
    g_cvMinInterpRatio = FindConVar("sv_client_min_interp_ratio");
    g_cvMaxInterpRatio = FindConVar("sv_client_max_interp_ratio");
}

// From LerpMonitor
// https://github.com/A1mDev/L4D2-Competitive-Plugins
float GetLerpTime(int client)
{
    char buffer[64];

    if (!GetClientInfo(client, "cl_updaterate", buffer, sizeof(buffer)))
    {
        buffer = "";
    }

    int updateRate = StringToInt(buffer);
    updateRate = RoundFloat(clamp(float(updateRate), g_cvMinUpdateRate.FloatValue, g_cvMaxUpdateRate.FloatValue));

    if (!GetClientInfo(client, "cl_interp_ratio", buffer, sizeof(buffer)))
    {
        buffer = "";
    }

    float flLerpRatio = StringToFloat(buffer);

    if (!GetClientInfo(client, "cl_interp", buffer, sizeof(buffer)))
    {
        buffer = "";
    }

    float flLerpAmount = StringToFloat(buffer);

    if (g_cvMinInterpRatio != null && g_cvMaxInterpRatio != null && g_cvMinInterpRatio.FloatValue != -1.0)
    {
        flLerpRatio = clamp(flLerpRatio, g_cvMinInterpRatio.FloatValue, g_cvMaxInterpRatio.FloatValue);
    }

    return maximum(flLerpAmount, flLerpRatio / updateRate);
}

float maximum(float a, float b)
{
    return (a > b) ? a : b;
}

float clamp(float inc, float low, float high)
{
    return (inc > high) ? high : ((inc < low) ? low : inc);
}
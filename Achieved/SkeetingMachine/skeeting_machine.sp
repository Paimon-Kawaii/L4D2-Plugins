/*
 * @Author:             我是派蒙啊
 * @Last Modif ied by:   我是派蒙啊
 * @Create Date:        2023-07-11 20:44:03
 * @Last Modif ied time: 2023-08-05 19:06:48
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#define DEBUG 0
#define DEBUG_RAY 0

#include <sdkhooks>
#include <sdktools>
#include <paiutils>
#include <sourcemod>

#if DEBUG_RAY
    #include <vector_show.sp>
#endif 

#define VERSION "2023.08.05"
#define MAXSIZE MAXPLAYERS + 1

#define TRACE_TICK 20

int
    g_iRayTick[MAXSIZE],
    g_iBotTarget[MAXSIZE] = { -1, ... },

    g_iThreats[9] =
    {
        0,          // Nothing
        30,         // Smoker
        10,         // Boomer
        70,         // Hunter
        20,         // Spitter
        60,         // Jockey
        80,         // Charger
        100,        // Witch
        100,        // Tank
    };

bool
    g_bShovable[MAXSIZE],
    g_bReloading[MAXSIZE],
    g_bSawable[MAXSIZE][MAXSIZE];

float
    g_fZombieThreats[MAXSIZE][MAXSIZE];

ConVar
    g_hSkeetEnable,
    g_hInfiniteAmmo,
    g_hPowerfulMode,
    g_hSvInfiniteAmmo;

public Plugin myinfo =
{
    name = "Skeeting-machine",
    author = "我是派蒙啊",
    description = "人机生还自瞄",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins"
};

public void OnPluginStart()
{
    g_hSvInfiniteAmmo = FindConVar("sv_infinite_ammo");
    g_hSkeetEnable = CreateConVar("smsb_enable", "1", "", _, true, 0.0, true, 1.0);
    g_hPowerfulMode = CreateConVar("smsb_givemepower", "0", "", _, true, 0.0, true, 1.0);
    g_hInfiniteAmmo = CreateConVar("smsb_infinite_ammo", "0", "", _, true, 0.0, true, 1.0);

    g_hSkeetEnable.AddChangeHook(ConVarChanged_SkeetEnable);

    HookEvent("round_start", Event_RoundStart);
    HookEvent("weapon_fire", Event_WeaponFire);
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("weapon_reload", Event_WeaponReload);
}

void ConVarChanged_SkeetEnable(ConVar convar, const char[] oldValue, const char[] newValue)
{
    FindConVar("sb_dont_shoot").SetInt(convar.BoolValue);
    if (!convar.BoolValue)
    {
        UnhookEvent("weapon_fire", Event_WeaponFire);
        UnhookEvent("player_spawn", Event_PlayerSpawn);
        UnhookEvent("player_death", Event_PlayerDeath);
        UnhookEvent("weapon_reload", Event_WeaponReload);
    } else {
        HookEvent("weapon_fire", Event_WeaponFire);
        HookEvent("player_spawn", Event_PlayerSpawn);
        HookEvent("player_death", Event_PlayerDeath);
        HookEvent("weapon_reload", Event_WeaponReload);
    }
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    FindConVar("sb_escort").SetInt(1);
    FindConVar("sb_all_bot_game").SetInt(1);
    FindConVar("sb_vomit_blind_time").SetInt(0);
    FindConVar("sb_dont_shoot").SetInt(g_hSkeetEnable.BoolValue);
    FindConVar("sb_close_checkpoint_door_interval").SetFloat(0.1);
    for (int i = 0; i <= MaxClients; i++)
    {
        g_iRayTick[i] = 0;
        g_iBotTarget[i] = -1;
        g_bReloading[i] = false;
    }
}

void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!IsFakeClient(client)) return;
    g_bShovable[client] = true;

    if (!g_hInfiniteAmmo.BoolValue || g_hSvInfiniteAmmo.BoolValue) return;
    int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (!IsValidEntity(weapon)) return;

    int clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
    SetEntProp(weapon, Prop_Send, "m_iClip1", clip + 1);
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    for(int i = 0; i <= MaxClients; i++)
        g_bSawable[i][client] = true;
        // if(IsSurvivor(i))
        //     g_bSawable[i][client] = IsVisibleTo(client, i);
        // else g_bSawable[i][client] = true;
    SDKHook(client, SDKHook_TraceAttack, TraceAttack);
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    for (int i = 0; i <= MaxClients; i++)
        g_fZombieThreats[i][client] = 0.0;
    SDKUnhook(client, SDKHook_TraceAttack, TraceAttack);
}

void Event_WeaponReload(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    g_bReloading[client] = true;
    g_bShovable[client] = false;
}

Action TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damageType, int &ammoType, int hitBox, int hitGroup)
{
    if (!g_hPowerfulMode.BoolValue || !IsSurvivor(attacker)
        || !IsFakeClient(attacker) || !IsInfected(victim) || IsTank(victim))
        return Plugin_Continue;

    damage = RoundToFloor(damage) * ((damageType & DMG_BUCKSHOT) ? 1.25
        : ((damageType & DMG_BULLET) ? 4.0 : 1.0));

#if DEBUG
    PrintToChatAll("%N atk %N: %.2f dmg", attacker, victim, damage);
#endif

    return Plugin_Changed;
}

public Action OnPlayerRunCmd(int survivor, int &buttons)
{
#if DEBUG
    if (IsInfected(survivor))
    {
        if (IsFakeClient(survivor))
        {
            SetEntityMoveType(survivor, MOVETYPE_NONE);
            buttons &= ~IN_ATTACK | ~IN_ATTACK2;
        }
        else SetPlayerHealth(survivor, 10000);

        return Plugin_Changed;
    }
#endif 

    if (!g_hSkeetEnable.BoolValue || !IsSurvivor(survivor)
        || !IsFakeClient(survivor) || !IsPlayerAlive(survivor))
        return Plugin_Continue;

    //SetEntPropFloat(survivor, Prop_Send, "m_flLaggedMovementValue", 3.0);

    bool siAlive = HasInfectedAlive(true);
    int aimInf = GetClosestZombie(survivor, NULL_VECTOR);
    if (!siAlive && !IsValidEntity(aimInf))
        g_iBotTarget[survivor] = -1;

    int targetSI = g_iBotTarget[survivor];
    if (siAlive)
    {
        // int botSI, aimSI = GetClosestClientAimer(survivor, TEAM_INFECTED);
        // if (IsInfected(aimSI)) targetSI = aimSI;
        // else botSI = GetClosestInfectedPinner(survivor);

        // if (IsInfected(botSI)) targetSI = botSI;
        // else botSI = GetClosestClient(survivor, NULL_VECTOR, TEAM_INFECTED, _, true);
        // if (IsInfected(botSI)) targetSI = botSI;

        // if (IsInfected(aimSI) && IsInfected(botSI) && aimSI != botSI)
        // {
        //     float aimDis = GetEntityDistance(survivor, aimSI);
        //     float clsDis = GetEntityDistance(survivor, botSI);
// #if DEBUG
//             PrintToChatAll("%N %N dis %.2f", aimSI, botSI, aimDis - clsDis);
// #endif 

        //     if (aimDis > clsDis) targetSI = botSI;
        //     else targetSI = aimSI;
        // }

        // botSI = GetClosestClient(survivor, NULL_VECTOR, TEAM_INFECTED, false, true);
        // if (!IsInfected(targetSI) && IsInfected(botSI)) targetSI = botSI;

        targetSI = GetDangerousZombie(survivor);
        if (IsValidEntity(aimInf) && IsInfected(targetSI) && !IsPinningSurvivor(targetSI))
        {
            float infPos[3], surPos[3], siPos[3];
            GetEntityAbsOrigin(aimInf, infPos);
            GetClientAbsOrigin(survivor, surPos);
            GetClientAbsOrigin(targetSI, siPos);
            float infDis = GetVectorDistance(infPos, surPos);
            float siDis = GetVectorDistance(siPos, surPos);
            if (IsRock(aimInf)) infDis -= 200;
            else if (IsEntitySawThreats(targetSI)) siDis -= 100;
            g_iBotTarget[survivor] = infDis > siDis ? targetSI : aimInf;
        } else if (IsInfected(targetSI))
            g_iBotTarget[survivor] = targetSI;
    } else if (IsValidEntity(aimInf))
        g_iBotTarget[survivor] = aimInf;

    float height, distance;
    int target = g_iBotTarget[survivor];
    int oldbtns = GetEntProp(survivor, Prop_Data, "m_nOldButtons");
    int weapon = GetEntPropEnt(survivor, Prop_Send, "m_hActiveWeapon");

    if (!IsValidEntity(weapon))
    {
        buttons |= IN_WEAPON1;
        return Plugin_Changed;
    }

    char clsName[32];
    GetEdictClassname(weapon, clsName, sizeof(clsName));
    bool shotgun = !strcmp(clsName, "weapon_pumpshotgun") ||
        !strcmp(clsName, "weapon_shotgun_chrome");
    bool shootAble = (IsInfected(target) && IsPlayerAlive(target)
        && !IsPlayerIncap(target) && !IsGhost(target))
        || (!IsInfected(target) && IsValidEntity(target));
    if (shootAble)
    {
        float eyePos[3], surPos[3], tarPos[3], tarDir[3], angles[3];
        GetClientEyePosition(survivor, surPos);
        if (IsInfected(target))
        {
            GetClientEyePosition(target, eyePos);
            GetClientAbsOrigin(target, tarPos);
            tarPos[2] = (tarPos[2] + eyePos[2]) / 2;
            int zclass = GetZombieClass(target);
            switch(zclass)
            {
                case ZC_CHARGER, ZC_BOOMER, ZC_SPITTER:
                    tarPos[2] += 15;
                case ZC_SMOKER:
                    tarPos[2] += 25;
                case ZC_HUNTER:
                    if (GetEntProp(target, Prop_Send, "m_isAttemptingToPounce"))
                    {
                        GetClientEyePosition(target, tarPos);
                        tarPos[2] -= 5;
                        if (shotgun) tarPos[2] -= 10;
                    }
            }

            if (IsPinningSurvivor(target))
            {
                switch(zclass)
                {
                    case ZC_HUNTER, ZC_SMOKER:
                        GetClientAbsOrigin(target, tarPos);
                    case ZC_JOCKEY:
                        GetClientEyePosition(target, tarPos);
                }
            }
        }
        else
        {
            GetEntityAbsOrigin(target, tarPos);
            tarPos[2] += 10;
        }
        MakeVectorFromPoints(surPos, tarPos, tarDir);
        GetVectorAngles(tarDir, angles);
        TeleportEntity(survivor, NULL_VECTOR, angles, NULL_VECTOR);

        if (IsInfected(target) && !IsEntitySawThreats(survivor))
            return Plugin_Changed;

        height = FloatAbs(tarPos[2] - surPos[2]);
        distance = GetEntityMinDistanceToTeam(target, TEAM_SURVIVOR);
        if (distance < 500 && GetGameTickCount() - g_iRayTick[survivor] >= TRACE_TICK)
        {
            g_iRayTick[survivor] = GetGameTickCount();
            g_bSawable[survivor][target] = IsVisibleTo(survivor, target);
        }
        if (!g_bSawable[survivor][target])
        {
            buttons |= IN_RELOAD;
            return Plugin_Changed;
        }

        if (IsInfected(target) && IsPinningSurvivor(target))
            distance = 0.0;
        if (g_bReloading[survivor])
        {
            float time = GetGameTime();
            float cNextAtk = GetEntPropFloat(survivor, Prop_Data, "m_flNextAttack");
            float wNextAtk = GetEntPropFloat(weapon, Prop_Data, "m_flNextPrimaryAttack");
            float cDelta =  cNextAtk - time;
            float wDelta =  wNextAtk - time;
            float delta = shotgun ? wDelta : cDelta;
            int clip = GetEntProp(weapon, Prop_Send, "m_iClip1");

            clip = g_hPowerfulMode.BoolValue ? GetAliveInfectedCount() : clip;

#if DEBUG
            PrintToChatAll("%N cNextAtk %.2f wNextAtk %.2f", survivor, cDelta, wDelta);
#endif 
            if (delta < -0.1) g_bReloading[survivor] = false;
            if (((IsInfected(target) && (IsEntitySawThreats(survivor)
                || IsEntitySawThreats(target)))
                || (IsValidEntity(target) && distance < 500)))
            {
#if DEBUG
                PrintToChatAll("%N skip reload", survivor);
#endif 

                if (!shotgun)
                {
                    time = GetGameTime() + 0.2;
                    SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", time);
                    SetEntPropFloat(survivor, Prop_Send, "m_flNextAttack", time);
                    SetEntPropFloat(weapon, Prop_Send, "m_flPlaybackRate", 5.0);
                }
                SetEntProp(weapon, Prop_Send, "m_iClip1", clip > 2 ? clip : 2);
                g_bReloading[survivor] = false;
            }
        }
        else if (IsValidEntity(target))
        {
            if ((shotgun && (height > 600 || distance > 600))
                || (!GetEntProp(weapon, Prop_Send, "m_iClip1")
                && !g_hInfiniteAmmo.BoolValue))
            {
                buttons |= IN_RELOAD;
                buttons &= ~IN_ATTACK & ~IN_ATTACK2;

                return Plugin_Changed;
            }

#if DEBUG
            if (IsInfected(target))
                PrintToChatAll("%N atk %N", survivor, target);
#endif 
            if (!(oldbtns & IN_ATTACK))
            {
                buttons |= IN_ATTACK;
                buttons &= ~IN_ATTACK2;
                if(shotgun) g_bShovable[survivor] = false;
            }
            if (g_bShovable[survivor])
            {
                buttons |= IN_ATTACK2;
                g_bShovable[survivor] = false;
            }
            SetEntProp(survivor, Prop_Send, "m_iShovePenalty", -1);
        }
    }

    if ((!siAlive || !IsValidClient(target) || height > 800 || distance > 800)
        && !g_bReloading[survivor] && !g_hInfiniteAmmo.BoolValue)
        buttons |= IN_RELOAD;

    return Plugin_Changed;
}

bool IsRock(int entity)
{
    if (!IsValidEntity(entity))
        return false;

    char name[16];
    GetEntityClassname(entity, name, sizeof(name));
    if (strcmp(name, "tank_rock"))
        return false;

    return true;
}

float GetEntityMinDistanceToTeam(int entity, int team)
{
    float dis = -1.0, pos[3], tarPos[3];
    if (IsValidClient(entity))
        GetClientAbsOrigin(entity, tarPos);
    else GetEntityAbsOrigin(entity, tarPos);
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidClient(i) || !IsPlayerAlive(i)
            || IsPlayerIncap(i) || GetClientTeam(i) != team) continue;

        GetClientAbsOrigin(i, pos);
        float tmp = GetVectorDistance(tarPos, pos);
        if (dis <= tmp && dis != -1) continue;

        dis = tmp;
    }

    return dis;
}

bool IsVisibleTo(int client, int target = -1, const float entPos[3] = NULL_VECTOR)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client))
        return false;
    float tarPos[3], pos[3];
    AddVectors(entPos, NULL_VECTOR, pos);
    if (IsValidEntity(target)) GetEntityAbsOrigin(target, pos);
    GetClientEyePosition(client, tarPos);
    if(!IsInfected(target))
    {
        pos[2] += 15;
        tarPos[2] -= 5;
    }

#if DEBUG_RAY
    ShowPos(2, tarPos, pos, 0.2, _, 0.1, 0.5);
#endif 

    Handle trace = TR_TraceRayFilterEx(pos, tarPos, MASK_VISIBLE,
        RayType_EndPoint, SelfIgnore_TraceFilter, target);
    if (!TR_DidHit(trace) || TR_GetEntityIndex(trace) == client)
    {
        delete trace;
        return true;
    }
    delete trace;
    return false;
}

bool SelfIgnore_TraceFilter(int entity, int mask, int self)
{
    return entity != self;
}

// int GetClosestInfectedPinner(int client)
// {
//     int target = -1;
//     float dis = -1.0, pos[3], tarPos[3];
//     GetClientAbsOrigin(client, tarPos);
//     for (int i = 1; i <= MaxClients; i++)
//     {
//         if (!IsInfected(i) || !IsPlayerAlive(i)
//             || IsPlayerIncap(i) || !IsPinningSurvivor(i)) continue;

//         GetClientAbsOrigin(i, pos);
//         float tmp = GetVectorDistance(tarPos, pos, true);
//         if (dis <= tmp && dis != -1) continue;

//         target = i;
//         dis = tmp;
//     }

//     return target;
// }

int GetDangerousZombie(int survivor, float farDis = 600.0, float clsDis = 300.0)
{
    float pos[3], tarPos[3];
    int result = 0, s = survivor;

    if (IsValidClient(s)) GetClientAbsOrigin(s, tarPos);

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsInfected(i) || !IsPlayerAlive(i) || IsGhost(i) || IsPlayerIncap(i)) continue;

        int zclass = GetZombieClass(i);
        g_fZombieThreats[s][i] = g_iThreats[zclass] * 1.0;

        GetClientAbsOrigin(i, pos);
        float dis = GetVector2Distance(tarPos, pos);
        if (dis > farDis)
            g_fZombieThreats[s][i] -= RoundToCeil((dis - farDis) / 4);
        else if (dis < clsDis)
            g_fZombieThreats[s][i] += RoundToNearest((clsDis - dis) / 2);

        dis = FloatAbs(tarPos[2] - pos[2]);
        if (dis > farDis)
            g_fZombieThreats[s][i] -= RoundToCeil((dis - farDis) / 4);

        if (IsEntitySawThreats(i)) g_fZombieThreats[s][i] *= 1.2;
        if (GetClientAimTarget(i) == s) g_fZombieThreats[s][i] *= 1.5;
        if (IsPinningSurvivor(i)) g_fZombieThreats[s][i] *= 0.5;

        float time, duration;
        if (IsUsingAbility(i)) g_fZombieThreats[s][i] *= 5.0;
        else if (GetAbilityCooldown(i, time, duration))
            if (time <= 0) g_fZombieThreats[s][i] *= 1.8;
            else if (time > duration / 2) g_fZombieThreats[s][i] *= 0.8;
            else if (time < duration / 3) g_fZombieThreats[s][i] *= 1.2;
#if DEBUG
        PrintToChatAll("%N %N danger: %.2f", s, i, g_fZombieThreats[s][i]);
#endif 
    }

    for (int i = 0; i <= MaxClients; i++)
        if (g_fZombieThreats[s][result] < g_fZombieThreats[s][i])
            result = i;

    return result;
}

bool IsUsingAbility(int client)
{
    if (!IsInfected(client) || !IsPlayerAlive(client) || IsGhost(client)) return false;

    int class = GetZombieClass(client);
    int ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
    if (!IsValidEntity(ability))
        return false;

    switch(class)
    {
        case ZC_SMOKER:
            return view_as<bool>(GetEntProp(ability, Prop_Send, "m_tongueState"));
        case ZC_HUNTER:
            return view_as<bool>(GetEntProp(ability, Prop_Send, "m_isLunging"));
        case ZC_JOCKEY:
            return view_as<bool>(GetEntProp(ability, Prop_Send, "m_isLeaping"));
        case ZC_CHARGER:
            return view_as<bool>(GetEntProp(ability, Prop_Send, "m_isCharging"));
        default:
            return false;
    }
}

bool GetAbilityCooldown(int client, float &time, float &duration)
{
    int ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
    if (!IsValidEntity(ability))
        return false;

    duration = GetEntPropFloat(ability, Prop_Send, "m_duration");
    time = GetEntPropFloat(ability, Prop_Send, "m_timestamp") - GetGameTime();
    return true;
}

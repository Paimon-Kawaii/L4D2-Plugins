/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-07-11 20:44:03
 * @Last Modified time: 2023-07-24 19:12:20
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#define DEBUG 0

#include <sdkhooks>
#include <sdktools>
#include <paiutils>
#include <sourcemod>

#if DEBUG
    #include <vector_show.sp>
#endif

#define VERSION "2023.07.15"
#define MAXSIZE MAXPLAYERS + 1

#define SHOOT_TICK 10
#define TRACE_TICK 20

int
    g_iRayTick[MAXSIZE],
    g_iShootTick[MAXSIZE],
    g_iBotTarget[MAXSIZE] = { -1, ... };

bool
    g_bSawable[MAXSIZE],
    g_bReloading[MAXSIZE];

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
    if(!convar.BoolValue)
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
    for(int i = 0; i <= MaxClients; i++)
    {
        g_iBotTarget[i] = -1;
        g_iRayTick[i] = g_iShootTick[i] = 0;
        g_bSawable[i] = g_bReloading[i] = false;
    }
}

void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    g_iShootTick[client] = GetGameTickCount();

    if(!IsFakeClient(client)) return;

    if(!g_hInfiniteAmmo.BoolValue || g_hSvInfiniteAmmo.BoolValue) return;
    int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if(!IsValidEntity(weapon)) return;

    int clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
    SetEntProp(weapon, Prop_Send, "m_iClip1", clip + 1);
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    SDKHook(client, SDKHook_TraceAttack, TraceAttack);
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    SDKUnhook(client, SDKHook_TraceAttack, TraceAttack);
}

void Event_WeaponReload(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    g_bReloading[client] = true;
}

Action TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damageType, int &ammoType, int hitBox, int hitGroup)
{
    if(!g_hPowerfulMode.BoolValue || !IsSurvivor(attacker)
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
    if(IsInfected(survivor))
    {
        if(IsFakeClient(survivor))
        {
            SetEntityMoveType(survivor, MOVETYPE_NONE);
            buttons &= ~IN_ATTACK | ~IN_ATTACK2;
        }
        else SetPlayerHealth(survivor, 10000);

        return Plugin_Changed;
    }
#endif

    if(!g_hSkeetEnable.BoolValue || !IsSurvivor(survivor)
        || !IsFakeClient(survivor) || !IsPlayerAlive(survivor))
        return Plugin_Continue;

    bool siAlive = HasInfectedAlive(true);
    int aimInf = GetClosestZombie(survivor, NULL_VECTOR);
    if(!siAlive && !IsValidEntity(aimInf))
        g_iBotTarget[survivor] = -1;

    int aimSI = g_iBotTarget[survivor];
    if(siAlive)
    {
        int botSI, clsAimer = GetClosestClientAimer(survivor, TEAM_INFECTED);
        if(IsInfected(clsAimer)) botSI = aimSI = clsAimer;
        else botSI = GetClosestInfectedPinner(survivor);

        if(IsInfected(botSI)) aimSI = botSI;
        else botSI = GetClosestClient(survivor, NULL_VECTOR, TEAM_INFECTED);
        if(IsInfected(botSI)) aimSI = botSI;

        if(IsInfected(clsAimer) && IsInfected(botSI))
        {
            float aimDis = GetEntityDistance(survivor, clsAimer);
            float clsDis = GetEntityDistance(survivor, botSI) + 80;

            if(aimDis > clsDis) aimSI = botSI;
            else aimSI = clsAimer;
        }

        botSI = GetClosestClient(survivor, NULL_VECTOR, TEAM_INFECTED, false);
        if(!IsInfected(aimSI) && IsInfected(botSI)) aimSI = botSI;

        if(IsValidEntity(aimInf) && IsInfected(aimSI) && !IsPinningSurvivor(aimSI))
        {
            float infPos[3], surPos[3], siPos[3];
            GetEntityAbsOrigin(aimInf, infPos);
            GetClientAbsOrigin(survivor, surPos);
            GetClientAbsOrigin(aimSI, siPos);
            float infDis = GetVectorDistance(infPos, surPos);
            float siDis = GetVectorDistance(siPos, surPos);
            if(IsRock(aimInf)) infDis -= 200;
            else if(IsEntitySawThreats(aimSI)) siDis -= 200;
            g_iBotTarget[survivor] = infDis > siDis ? aimSI : aimInf;
        }
        else if(IsInfected(aimSI))
            g_iBotTarget[survivor] = aimSI;
    } else if(IsValidEntity(aimInf))
        g_iBotTarget[survivor] = aimInf;

    float height, distance;
    int target = g_iBotTarget[survivor];
    int oldbtns = GetEntProp(survivor, Prop_Data, "m_nOldButtons");
    int weapon = GetEntPropEnt(survivor, Prop_Send, "m_hActiveWeapon");

    if(!IsValidEntity(weapon))
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
    if(shootAble)
    {
        float eyePos[3], surPos[3], tarPos[3], tarDir[3], angles[3];
        GetClientEyePosition(survivor, surPos);
        if(IsInfected(target))
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
                    if(GetEntProp(target, Prop_Send, "m_isAttemptingToPounce"))
                    {
                        GetClientEyePosition(target, tarPos);
                        tarPos[2] -= 5;
                        if(shotgun) tarPos[2] -= 15;
                    }
            }

            if(IsPinningSurvivor(target))
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

        if(IsInfected(target) && !IsEntitySawThreats(survivor))
            return Plugin_Changed;

        height = FloatAbs(tarPos[2] - surPos[2]);
        distance = GetEntityMinDistanceToTeam(target, TEAM_SURVIVOR);
        if(!IsInfected(target) && distance < 500
            && GetGameTickCount() - g_iRayTick[survivor] >= TRACE_TICK)
        {
            g_iRayTick[survivor] = GetGameTickCount();
            g_bSawable[survivor] = IsVisibleTo(survivor, target);
        }
        if(!IsInfected(target) && !g_bSawable[survivor])
        {
            buttons |= IN_RELOAD;
            return Plugin_Changed;
        }

        if(IsInfected(target) && IsPinningSurvivor(target))
            distance = 0.0;
        if(g_bReloading[survivor])
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
            if(delta < -0.1) g_bReloading[survivor] = false;
            if(((IsInfected(target) && (IsEntitySawThreats(survivor)
                || IsEntitySawThreats(target)))
                || (IsValidEntity(target) && distance < 500)))
            {
#if DEBUG
                PrintToChatAll("%N skip reload", survivor);
#endif
                g_bReloading[survivor] = false;
                SetEntProp(weapon, Prop_Send, "m_iClip1", clip ? clip + 1 : 2);
            }
        }
        if(!g_bReloading[survivor] && IsValidEntity(target))
        {
            if((shotgun && (height > 600 || distance > 600))
                || (!GetEntProp(weapon, Prop_Send, "m_iClip1")
                && !g_hInfiniteAmmo.BoolValue))
            {
                buttons |= IN_RELOAD;
                buttons &= ~IN_ATTACK & ~IN_ATTACK2;

                return Plugin_Changed;
            }
            else if(shotgun)
            {
#if DEBUG
                if(IsInfected(target))
                    PrintToChatAll("%N atk %N", survivor, target);
#endif
                // if(GetGameTickCount() - g_iShootTick[survivor] >= SHOOT_TICK)
                //     buttons |= IN_ATTACK;
                // else buttons |= IN_ATTACK2;
                if(!(oldbtns & IN_ATTACK) || (oldbtns & IN_ATTACK2))
                    buttons |= IN_ATTACK;
                else buttons |= IN_ATTACK2;
                SetEntProp(survivor, Prop_Send, "m_iShovePenalty", -1);
            }
            else if(!(oldbtns & IN_ATTACK))
                buttons |= IN_ATTACK;
        }
    }

    if((!siAlive || !IsValidClient(target) || height > 800 || distance > 800)
        && !g_bReloading[survivor] && !g_hInfiniteAmmo.BoolValue)
        buttons |= IN_RELOAD;

    return Plugin_Changed;
}

bool IsRock(int entity)
{
    if(!IsValidEntity(entity))
        return false;

    char name[16];
    GetEntityClassname(entity, name, sizeof(name));
    if(strcmp(name, "tank_rock"))
        return false;

    return true;
}

int GetClosestInfectedPinner(int client)
{
    int target = -1;
    float dis = -1.0, pos[3], tarPos[3];
    GetClientAbsOrigin(client, tarPos);
    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsInfected(i) || !IsPlayerAlive(i)
            || IsPlayerIncap(i) || !IsPinningSurvivor(i)) continue;

        GetClientAbsOrigin(i, pos);
        float tmp = GetVectorDistance(tarPos, pos, true);
        if(dis <= tmp && dis != -1) continue;

        target = i;
        dis = tmp;
    }

    return target;
}

float GetEntityMinDistanceToTeam(int entity, int team)
{
    float dis = -1.0, pos[3], tarPos[3];
    if(IsValidClient(entity))
        GetClientAbsOrigin(entity, tarPos);
    else GetEntityAbsOrigin(entity, tarPos);
    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsValidClient(i) || !IsPlayerAlive(i)
            || IsPlayerIncap(i) || GetClientTeam(i) != team) continue;

        GetClientAbsOrigin(i, pos);
        float tmp = GetVectorDistance(tarPos, pos);
        if(dis <= tmp && dis != -1) continue;

        dis = tmp;
    }

    return dis;
}

bool IsVisibleTo(int target, int self = -1, const float entPos[3] = NULL_VECTOR)
{
    if (!IsSurvivor(target) || !IsPlayerAlive(target))
        return false;
    float tarPos[3], pos[3];
    AddVectors(entPos, NULL_VECTOR, pos);
    if(IsValidEntity(self)) GetEntityAbsOrigin(self, pos);
    GetClientEyePosition(target, tarPos);
    pos[2] += 15; tarPos[2] -= 5;

#if DEBUG
    ShowPos(2, tarPos, pos, 0.2, _, 0.1, 0.5);
#endif

    Handle trace = TR_TraceRayFilterEx(pos, tarPos, MASK_VISIBLE,
        RayType_EndPoint, SelfIgnore_TraceFilter, self);
    if (!TR_DidHit(trace) || TR_GetEntityIndex(trace) == target)
    {
        delete trace;
        return true;
    }
    delete trace;
    return false;
}

bool SelfIgnore_TraceFilter(int entity, int mask, int self)
{
    if(IsValidEntity(entity))
        return false;

    return true;
}
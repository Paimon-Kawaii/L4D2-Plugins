/*
 * @Author:             派蒙
 * @Last Modified by:   派蒙
 * @Create Date:        2022-03-23 12:42:32
 * @Last Modified time: 2022-04-17 12:28:04
 * @Github:             http://github.com/PaimonQwQ
 */

#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sourcemod>
#include <left4dhooks>

#define MAXSIZE 33
#define VERSION "2022.04.17"

int
    g_iHours,
    g_iMinutes,
    g_iSeconds,
    g_iRetryTimes,
    g_iTotalDamage[MAXSIZE],
    g_iKillZombies[MAXSIZE],
    g_iKillSpecial[MAXSIZE],
    g_iFriendDamage[MAXSIZE],
    g_iDamageFriend[MAXSIZE];

public Plugin myinfo =
{
    name = "AngelMvp",
    author = "我是派蒙啊",
    description = "AngelServer的技术信息统计",
    version = VERSION,
    url = "http://github.com/PaimonQwQ/L4D2-Plugins/AngelBeats"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_mvp", MVPinfo, "MVP Msg");
    RegConsoleCmd("sm_kills", MVPinfo, "MVP Msg");
    HookEvent("round_end", Event_RoundEnd);
    HookEvent("finale_win", Event_RoundEnd);
    HookEvent("round_start", Event_RoundStart);
    HookEvent("player_hurt", Event_PlayerHurt);
    HookEvent("map_transition", Event_RoundEnd);
    HookEvent("mission_lost", Event_MissionLost);
    HookEvent("player_death", Event_InfectedDeath);
    HookEvent("infected_death", Event_ZombiesDeath);
}

public Action L4D_OnFirstSurvivorLeftSafeArea()
{
    for(int i = 1; i <= MaxClients; i++)
    {
        g_iKillZombies[i] = 0;
        g_iKillSpecial[i] = 0;
        g_iFriendDamage[i] = 0;
        g_iDamageFriend[i] = 0;
        g_iTotalDamage[i] = 0;
    }
    return Plugin_Continue;
}

public Action MVPinfo(int client, any args)
{
    ShowMVPMsg();
    return Plugin_Handled;
}

public Action Event_RoundEnd(Handle event, char[] name, bool dontBroadcast)
{
    ShowMVPMsg();
    return Plugin_Continue;
}

public Action Event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        g_iTotalDamage[i] = 0;
        g_iKillZombies[i] = 0;
        g_iKillSpecial[i] = 0;
        g_iFriendDamage[i] = 0;
        g_iDamageFriend[i] = 0;
    }
    return Plugin_Continue;
}

public Action Event_MissionLost(Event event, const char[] name, bool dont_broadcast)
{
    g_iRetryTimes++;
    return Plugin_Continue;
}

public Action Event_PlayerHurt(Handle event, char[] name, bool dontBroadcast)
{
    int victimId = GetEventInt(event, "userid", 0);
    int victim = GetClientOfUserId(victimId);
    int attackerId = GetEventInt(event, "attacker", 0);
    int attacker = GetClientOfUserId(attackerId);
    int damageDone = GetEventInt(event, "dmg_health", 0);
    if (IsValidClient(victim) && IsValidClient(attacker) && GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 2 && GetEntProp(victim, Prop_Send, "m_isIncapacitated", 4, 0) < 1)
    {
        g_iFriendDamage[attacker] += damageDone;
        g_iDamageFriend[victim] += damageDone;
    }
    if (victimId && attackerId && IsValidClient(victim) && IsValidClient(attacker))
    {
        if (GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 3)
        {
            int zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass", 4, 0);
            if (zombieClass >= 1 && zombieClass < 7)
            {
                if (zombieClass == 1 && damageDone > 250)
                    damageDone = 250;
                if (zombieClass == 3 && damageDone > 250)
                    damageDone = 250;
                if (zombieClass == 2 && damageDone > 50)
                    damageDone = 50;
                if (zombieClass == 6 && damageDone > 600)
                    damageDone = 600;
                if (zombieClass == 4 && damageDone > 100)
                    damageDone = 100;
                if (zombieClass == 5 && damageDone > 325)
                    damageDone = 325;
                g_iTotalDamage[attacker] += damageDone;
            }
        }
    }
    return Plugin_Continue;
}

public Action Event_InfectedDeath(Handle event, char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker", 0));
    int client = GetClientOfUserId(GetEventInt(event, "userid", 0));
    if (IsValidClient(attacker) && IsValidClient(client))
        if (GetClientTeam(attacker) == 2 && GetClientTeam(client) == 3)
            g_iKillSpecial[attacker] += 1;
    return Plugin_Continue;
}

public Action Event_ZombiesDeath(Handle event, char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker", 0));
    if (IsValidClient(attacker) && GetClientTeam(attacker) == 2)
        g_iKillZombies[attacker] += 1;
    return Plugin_Continue;
}

int SortByDamageDesc(int elem1, int elem2, int[] array, Handle hndl)
{
    if (g_iTotalDamage[elem2] < g_iTotalDamage[elem1])
        return -1;
    if (g_iTotalDamage[elem1] < g_iTotalDamage[elem2])
        return 1;
    if (elem1 > elem2)
        return -1;
    if (elem2 > elem1)
        return 1;
    return 0;
}

bool IsValidClient(int client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client);
}

void ShowMVPMsg()
{
    GetMapTime();
    int players = 0;
    int players_clients[MAXSIZE];
    PrintToChatAll("\x03[MVP统计]");
    PrintToChatAll("\x03章节时长 \x04%dh:%dm:%ds \x03重启次数 \x04%d", g_iHours, g_iMinutes, g_iSeconds, g_iRetryTimes);
    for (int client = 1; client <= MaxClients; client++)
        if (IsClientInGame(client) && GetClientTeam(client) == 2)
        {
            players++;
            players_clients[players] = client;
        }
    SortCustom1D(players_clients, MAXSIZE, SortByDamageDesc);
    for (int i = 0; i <= MaxClients; i++)
    {
        int client = players_clients[i];
        if (IsValidClient(client) && GetClientTeam(client) == 2)
            PrintToChatAll("\x03特感\x04%2d \x03丧尸\x04%3d \x03黑/被黑\x04%2d/%2d \x03伤害\x04%4d \x05%N", g_iKillSpecial[client], g_iKillZombies[client], g_iFriendDamage[client], g_iDamageFriend[client], g_iTotalDamage[client], client);
    }
}

void GetMapTime()
{
    float seconds = GetGameTime();
    g_iHours = RoundToFloor(seconds / 3600);
    g_iMinutes = RoundToFloor((seconds - g_iHours * 3600) / 60);
    g_iSeconds = RoundToFloor(seconds - g_iHours * 3600 - g_iMinutes * 60);
}
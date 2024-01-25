/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-12-14 15:26:19
 * @Last Modified time: 2023-12-14 15:57:56
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <colors>
#include <sdktools>
#include <paiutils>
#include <sourcemod>

#define VERSION "2023.12.14"

#define DEBUG 0

#define GAMEDATA_FILE "play_for_death"
#define MAXSIZE MAXPLAYERS + 1

bool
    g_bBeDying[MAXSIZE];

public Plugin myinfo =
{
    name = "GameManager",
    author = "我是派蒙啊",
    description = "果果服人数管理",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins/MyPlugins"
};

public void OnClientConnected(int client)
{
    if(IsFakeClient(client)) return;

    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
    if(IsFakeClient(client)) return;

    SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if(!IsSurvivor(victim)) return Plugin_Continue;

    if(!IsPlayerIncap(victim) && !IsPlayerOnThirdStrike(victim)) return Plugin_Continue;
    if(GetPlayerHealth(victim, _, true) >= damage)
    {
        if(!g_bBeDying[victim])
        {
            g_bBeDying[victim] = true;

            return Plugin_Handled;
        }
    }
}
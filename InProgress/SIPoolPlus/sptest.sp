/*
 * @Author: 我是派蒙啊
 * @Last Modified by: 我是派蒙啊
 * @Create Date: 2024-02-17 11:26:28
 * @Last Modified time: 2024-03-25 15:49:42
 * @Github: https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#define DEBUG   0

#define VERSION ""

//#define LIBRARY_NAME "si_pool"
// #define GAMEDATA_FILE ""

#include <sdktools>
#include <sourcemod>

//#include <colors>
#include <paiutils>
#include <left4dhooks>

#if DEBUG
#endif

#include <si_pool>

public Plugin myinfo =
{
    name = "SP Test",
    author = "我是派蒙啊",
    description = "SIPool test",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins"
};

SIPool g_hSIPool;

//#define MAXSIZE MAXPLAYERS + 1
public void OnPluginStart()
{
    RegConsoleCmd("sm_sp", CMD_SP);
}

public void OnMapStart()
{
    if (!g_hSIPool) g_hSIPool = SIPool.Instance();

    // g_hSIPool.Resize(MaxClients);
    // PrintToChatAll("%d", g_hSIPool.Size);
}

Action CMD_SP(int client, int args)
{
    float pos[3];
    GetClientAbsOrigin(client, pos);
    pos[0] += 100;
    pos[2] += 100;

    // PrintToChatAll("%.2f %.2f %.2f", pos[0], pos[1], pos[2]);

    for (int i = 1; i <= 4; i++)
    {
        // if (IsInfected(i))
        // {
        //     PrintToChatAll("%N alive: %d", i, IsPlayerAlive(i));
        //     SetEntProp(i, Prop_Send, "m_lifeState", 1);
        //     PrintToChatAll("%N alive: %d", i, IsPlayerAlive(i));
        // }
        int idx = g_hSIPool.RequestSIBot(GetRandomInt(1, 6), pos);
        PrintToChatAll("索引:%d", idx);
        if (idx != -1)
        {
            PrintToChatAll("名称:%N", idx);
            PrintToChatAll("类型:%d", GetZombieClass(idx));
        }
    }

    return Plugin_Handled;
}
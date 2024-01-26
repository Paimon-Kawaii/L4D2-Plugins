/*
 * @Author:             我是派蒙啊
 * @Last Modified by: 我是派蒙啊
 * @Create Date:        2023-06-01 14:25:29
 * @Last Modified time: 2024-01-25 21:07:34
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sourcemod>
#include <paiutils>
#include <left4dhooks>

// int carried[MAXPLAYERS + 1];
public Plugin myinfo =
{
    name = "Test",
    author = "我是派蒙啊",
    description = "",
    version = "",
    url = ""
};

// void Test()
// {
//     GetVectorAngles()
// }
public void OnPluginStart()
{
    RegConsoleCmd("sm_esc", Cmd_ESC);
}

// public void OnClientConnected(int client)
// {
//     PrintToChatAll("%N", client);
//     ClientCommand(client, "bind \"ESCAPE\" \"sm_esc\"");
// }

// public void OnClientDisconnect(int client)
// {
//     PrintToChatAll("%N", client);
//     ClientCommand(client, "bind \"ESCAPE\" \"cancelselect\"");
// }

Action Cmd_ESC(int client, int args)
{
    char buffer[32], prop[32], type[4], data[16];
    GetCmdArg(1, prop, sizeof(prop));
    GetCmdArg(1, prop, sizeof(prop));
    GetCmdArg(2, data, sizeof(data));
    int iData = StringToInt(data);

    SetEntProp(client, Prop_Send, prop, iData);

    return Plugin_Continue;
}

//特感连跳
// public Action OnPlayerRunCmd(int client, int &buttons, int &impuls)
// {
//     if (!IsValidClient(client) || IsFakeClient(client)) return Plugin_Continue;

//     if ((buttons & IN_JUMP) && GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == -1)
//         buttons &= ~IN_JUMP;

//     return Plugin_Changed;
// }

// void test()
// {
//     CreateEntityByName("")
// }

// L4D2_Charger_StartCarryingVictim
// L4D2_Charger_EndPummel

// public Action L4D2_OnStartCarryingVictim(int victim, int attacker)
// {
//     if(!IsSurvivor(victim) || !IsInfected(attacker))
//         return Plugin_Continue;

//     carried[attacker] = victim;
//     CreateTimer(0.5, Timer_Release, attacker, TIMER_FLAG_NO_MAPCHANGE);

//     return Plugin_Continue;
// }

// Action Timer_Release(Handle timer, int client)
// {
//     L4D2_Charger_EndPummel(carried[client], client);

//     return Plugin_Stop;
// }
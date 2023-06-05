/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-06-01 14:25:29
 * @Last Modified time: 2023-06-05 20:51:44
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <l4d2tools>
#include <sourcemod>

public Plugin myinfo =
{
    name = "Test",
    author = "我是派蒙啊",
    description = "",
    version = "",
    url = ""
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_esc", Cmd_ESC);
}

public void OnClientConnected(int client)
{
    PrintToChatAll("%N", client);
    ClientCommand(client, "bind \"ESCAPE\" \"sm_esc\"");
}

public void OnClientDisconnect(int client)
{
    PrintToChatAll("%N", client);
    ClientCommand(client, "bind \"ESCAPE\" \"cancelselect\"");
}

Action Cmd_ESC(int client, int args)
{
    PrintToChatAll("escape");

    return Plugin_Continue;
}

//特感连跳
public Action OnPlayerRunCmd(int client, int &buttons, int &impuls)
{
    if (!IsValidClient(client)) return Plugin_Continue;

    if (IsSurvivor(client) && (buttons & IN_JUMP)
        && GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == -1)
        buttons &= ~IN_JUMP;

    return Plugin_Changed;
}

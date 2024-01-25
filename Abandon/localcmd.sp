/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-06-28 14:26:12
 * @Last Modified time: 2023-06-28 14:31:20
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public Plugin myinfo =
{
    name = "Local Command",
    author = "我是派蒙啊",
    description = "",
    version = "",
    url = ""
};

public void OnPluginStart()
{
    AddCommandListener(Cmd_CallBack, "sm_admin");
    AddCommandListener(Cmd_CallBack, "sm_rygive");
}

Action Cmd_CallBack(int client, char[] command, int args)
{
    if(client != 0) return Plugin_Continue;
    FakeClientCommand(1, command);
    return Plugin_Handled;
}
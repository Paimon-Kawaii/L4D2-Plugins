/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-12-18 20:06:26
 * @Last Modified time: 2023-12-18 21:00:52
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <paiutils>
#include <sourcemod>

#define VERSION "2023.12.18"

#define DEBUG 0
#define MAXSIZE MAXPLAYERS + 1

float
    g_iFlashPressTime[MAXSIZE];

public Plugin myinfo =
{
    name = "夜视插件",
    author = "我是派蒙啊",
    description = "开启夜视",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins/MyPlugins"
};

public void OnClientPostAdminCheck(int client)
{
    if(IsFakeClient(client)) return;

    PrintToChat(client, "双击手电筒可开启夜视");
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse)
{
    if(impulse != 100) return;

    if(GetEngineTime() - g_iFlashPressTime[client] > 0.3)
    {
        PrintHintText(client, "双击开启/关闭夜视");
        g_iFlashPressTime[client] = GetEngineTime();

        return;
    }

    int status = GetEntProp(client, Prop_Send, "m_bNightVisionOn");
    // SetEntProp(client, Prop_Send, "m_bHasNightVision", 1 - status);
    SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1 - status);

    PrintHintText(client, "夜视仪已%s", status ? "关闭" : "开启");
}
/*
 * @Author:             派蒙
 * @Last Modified by:   派蒙
 * @Create Date:        2022-06-04 13:22:42
 * @Last Modified time: 2022-06-06 23:09:19
 * @Github:             http://github.com/PaimonQwQ
 */

#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <l4d2tools>
#include <sourcemod>
#include <left4dhooks>

#define MAXSIZE 33
#define VERSION "2022.06.05"

public Plugin myinfo =
{
    name = "视角修复",
    author = "我是派蒙啊",
    description = "神仙Bot的视角修复",
    version = VERSION,
    url = "http://github.com/PaimonQwQ/L4D2-Plugins/OtherPlugins"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_fix", Cmd_ViewFix, "View Fix");
    HookEvent("bot_player_replace", Event_PlayerJoined);
}

public Action Cmd_ViewFix(int client, any args)
{
    if(IsSurvivor(client) && !IsFakeClient(client))
        SetClientViewEntity(client, client);

    return Plugin_Handled;
}

public Action Event_PlayerJoined(Event event, const char[] name, bool dont_broadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(IsSurvivor(client) && !IsFakeClient(client) && L4D_HasAnySurvivorLeftSafeArea())
        SetClientViewEntity(client, client);

    return Plugin_Continue;
}
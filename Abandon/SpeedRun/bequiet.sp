/*
 * @Author:             派蒙
 * @Last Modified by:   派蒙
 * @Create Date:        2022-06-21 15:52:15
 * @Last Modified time: 2022-06-21 17:05:40
 * @Github:             http://github.com/PaimonQwQ
 */

#pragma semicolon 1
#pragma newdecls required

#include <colors>
#include <sourcemod>

public Plugin myinfo =
{
    name = "BeQuiet",
    author = "Sir",
    description = "Please be Quiet!",
    version = "1.33.7",
    url = "https://github.com/SirPlease/SirCoding"
}

public void OnPluginStart()
{
    AddCommandListener(Say_Callback, "say");
    AddCommandListener(Say_Callback, "say_team");

    //Server CVar
    HookEvent("server_cvar", Event_ServerConVar, EventHookMode_Pre);
    HookEvent("player_changename", Event_NameChange, EventHookMode_Pre);
}

public Action Say_Callback(int client, char[] command, int args)
{
    char sayWord[MAX_NAME_LENGTH];
    GetCmdArg(1, sayWord, sizeof(sayWord));

    if(sayWord[0] == '/')
        return Plugin_Handled;

    return Plugin_Continue;
}

public Action Event_ServerConVar(Event event, const char[] name, bool dontBroadcast)
{
    return Plugin_Handled;
}

public Action Event_NameChange(Event event, const char[] name, bool dontBroadcast)
{
    int clientid = event.GetInt("userid");
    int client = GetClientOfUserId(clientid);

    if (IsValidClient(client))
        return Plugin_Handled;

    return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client)) return false;

    return true;
}
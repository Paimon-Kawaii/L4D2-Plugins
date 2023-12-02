/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-11-20 14:29:21
 * @Last Modified time: 2023-11-20 14:57:29
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <paiutils>
#include <sourcemod>

#define VERSION "2023.11.19"

Address
    g_pServer;

Handle
    g_hCGameServer_SetMaxClients;

public Plugin myinfo =
{
    name = "SurvivorModelTest",
    author = "我是派蒙啊",
    description = "",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins/MyPlugins"
};

//插件入口
public void OnPluginStart()
{
    InitGameData();
    RegAdminCmd("sm_clients", Cmd_SetClients, ADMFLAG_GENERIC, "Set max clients");
}

void InitGameData()
{
    GameData gamedata = new GameData("clients_unlock");
    g_pServer = gamedata.GetAddress("ServerAddr");

    StartPrepSDKCall(SDKCall_Static);
    if(!PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CGameServer::SetMaxClients"))
    {
        LogError("Failed to find signature: \"CGameServer::SetMaxClients\"");
    } else {
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
        g_hCGameServer_SetMaxClients = EndPrepSDKCall();
        if(g_hCGameServer_SetMaxClients == null)
            LogError("Failed to create SDKCall: \"CGameServer::SetMaxClients\"");
    }

    delete gamedata;
}

void SetMaxClients(int count)
{
    SDKCall(g_hCGameServer_SetMaxClients, g_pServer, count);
    PrintToChatAll("Max clients count set to %d", count);
}

//管理员作弊指令
Action Cmd_SetClients(int client, any args)
{
    if (!IsValidClient(client)) return Plugin_Handled;

    char arg[16];
    GetCmdArg(args, arg, sizeof(arg));
    SetMaxClients(StringToInt(arg));

    return Plugin_Handled;
}
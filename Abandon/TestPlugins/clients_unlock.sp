/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-11-20 14:29:21
 * @Last Modified time: 2024-09-16 20:02:54
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
    g_hCBaseServer_GetMaxClients,
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
    RegAdminCmd("sm_cs", Cmd_SetClients, ADMFLAG_GENERIC, "Set max clients");

    FindConVar("sv_maxplayers").SetBounds(ConVarBound_Upper, false);
}

void InitGameData()
{
    GameData gamedata = new GameData("clients_unlock");
    g_pServer = gamedata.GetAddress("ServerAddr");

    StartPrepSDKCall(SDKCall_Server);
    if (!PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CGameServer::SetMaxClients"))
    {
        LogError("Failed to find signature: \"CGameServer::SetMaxClients\"");
    }
    else {
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
        g_hCGameServer_SetMaxClients = EndPrepSDKCall();
        if (g_hCGameServer_SetMaxClients == null)
            LogError("Failed to create SDKCall: \"CGameServer::SetMaxClients\"");
    }

    StartPrepSDKCall(SDKCall_Server);
    if (!PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CBaseServer::GetMaxClients"))
    {
        LogError("Failed to find signature: \"CBaseServer::GetMaxClients\"");
    }
    else {
        PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
        g_hCBaseServer_GetMaxClients = EndPrepSDKCall();
        if (g_hCBaseServer_GetMaxClients == null)
            LogError("Failed to create SDKCall: \"CBaseServer::GetMaxClients\"");
    }

    delete gamedata;
}

int GetMaxClients2()
{
    return SDKCall(g_hCBaseServer_GetMaxClients, g_pServer);
}

void SetMaxClients(int count)
{
    if (count == 0) return;
    PrintToChatAll("sdk读取client %d", GetMaxClients2());
    SDKCall(g_hCGameServer_SetMaxClients, g_pServer, count);
    PrintToChatAll("sdk写入client %d", count);
    PrintToChatAll("sdk读取client %d", GetMaxClients2());

    Address pClientCnts1 = g_pServer + view_as<Address>(65);
    Address pClientCnts2 = g_pServer + view_as<Address>(136);
    PrintToChatAll("内存1读取clients %d", LoadFromAddress(pClientCnts1, NumberType_Int32));
    StoreToAddress(pClientCnts1, count, NumberType_Int32);
    PrintToChatAll("内存1写入clients %d", LoadFromAddress(pClientCnts1, NumberType_Int32));
    PrintToChatAll("内存2读取clients %d", LoadFromAddress(pClientCnts2, NumberType_Int32));
    StoreToAddress(pClientCnts2, count, NumberType_Int32);
    PrintToChatAll("内存2写入clients %d", LoadFromAddress(pClientCnts2, NumberType_Int32));
}

//管理员作弊指令
Action Cmd_SetClients(int client, any args)
{
    if (!IsValidClient(client)) return Plugin_Handled;

    char arg[16];
    GetCmdArg(args, arg, sizeof(arg));
    SetMaxClients(StringToInt(arg));
    PrintToChatAll("sdk读取client %d", GetMaxClients2());
    PrintToChatAll("api调用GetMaxClients() %d", GetMaxClients());
    PrintToChatAll("api读取MaxClients %d", MaxClients);

    return Plugin_Handled;
}
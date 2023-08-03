/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-08-02 22:48:24
 * @Last Modified time: 2023-08-02 23:22:46
 * @Github:             https://github.com/Paimon-Kawaii
 */

#include <dhooks>
#include <sdktools>
#include <sdkhooks>
#include <paiutils>
#include <sourcemod>

Handle
    g_hDebugDrawLine;

public Plugin myinfo =
{
    name = "Test Draw Line",
    author = "我是派蒙啊",
    description = "",
    version = "",
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins"
};

public void OnPluginStart()
{
    GameData gamedata = new GameData("test_draw");

    StartPrepSDKCall(SDKCall_Static);
    if (PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "DebugDrawLine"))
    {
        PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
        PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);

        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
        PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
        PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);

        g_hDebugDrawLine = EndPrepSDKCall();
    } else ThrowError("Failed to load signature: \"CTerrorPlayer::DebugDrawLine\"");
}

// DebugDrawLine(Vector const&, Vector const&, int, int, int, bool, float)
void DebugDrawLine(const float start[3], const float end[3], int color[3], bool test = true, float duration = 1000.0)
{
    PrintToChatAll("TEST3");
    SDKCall(g_hDebugDrawLine, start, end, color[0], color[1], color[2], test, duration);
}

public void OnPlayerRunCmdPost(int client, int buttons)
{
    if(IsFakeClient(client)) return;

    // int oldbtns = GetEntProp(client, Prop_Data, "m_nOldButtons");
    // if(oldbtns & IN_USE) return;
    // PrintToChat(client, "TEST1");

    if(!(buttons & IN_USE)) return;

    float pos1[3], pos2[3];
    GetClientAbsOrigin(client, pos2);
    AddVectors(pos1, NULL_VECTOR, pos2);
    pos2[0] += 1000;

    DebugDrawLine(pos1, pos2, {255, 255, 255});
    DebugDrawLine(pos1, pos2, {255, 255, 255}, false);
}
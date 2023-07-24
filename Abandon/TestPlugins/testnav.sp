#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sourcemod>
#include <left4dhooks>

#define DEBUG 1

#if DEBUG
    #include <vector_show.sp>
#endif

Address
    g_pCNavMesh;

Handle
    g_hGetNextBot,
    g_hGetLocomotion,

    g_hClimbLadder,
    g_hGetConnection,
    g_hGetLadderCount,
    g_hGetLadderByID;

enum LadderConnectionType
{
    LADDER_TOP_FORWARD = 0,
    LADDER_TOP_LEFT,
    LADDER_TOP_RIGHT,
    LADDER_TOP_BEHIND,
    LADDER_BOTTOM,
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
    int oldbtns = GetEntProp(client, Prop_Data, "m_nOldButtons");
    if(!(buttons & IN_RELOAD) || (oldbtns & IN_RELOAD)) return Plugin_Continue;

    int area, ladder;
    float start[3], end[3], ang[3], fwd[3];
    GetClientAbsOrigin(client, start);
    GetClientEyeAngles(client, ang);

    start[2] += 70;
    GetAngleVectors(ang, fwd, NULL_VECTOR, NULL_VECTOR);
    NormalizeVector(fwd, fwd);
    ScaleVector(fwd, 100.0);
    for(int i = 0; i < 3; i++)
        end[i] = start[i] + fwd[i];

#if DEBUG
    // The points are right, dont need to check
    ShowPos(4, start, end, 10.0, 0.0, 0.0, 2.0);
#endif

    // PrintToChat(client, "end %d", L4D_GetNearestNavArea(end));
    // SDKCall(g_hFindNavAreaOrLadder, g_pCNavMesh, start, end, area, ladder);
    // bool result = FindNavAreaOrLadderAlongRay(g_pCNavMesh, start, end, area, ladder);
    // PrintToChat(client, "result %d, area %d, ladder %d", result, area, ladder);

    // if(!ladder) return Plugin_Continue;
    // int top = SDKCall(g_hGetConnection, ladder, LADDER_TOP_BEHIND);
    // PrintToChat(client, "top %d", top);



    // return Plugin_Continue;
    int witch = MaxClients + 1;
    while((witch = FindEntityByClassname(witch, "witch")) && IsValidEntity(witch))
    {
        Address nextbot = SDKCall(g_hGetNextBot, witch);
        if(!nextbot) return Plugin_Continue;
        Address locomotion = SDKCall(g_hGetLocomotion, nextbot);
        if(!locomotion) return Plugin_Continue;

        SDKCall(g_hClimbLadder, locomotion, ladder, top);
    }

    return Plugin_Continue;
}

public void OnPluginStart()
{
    GameData gamedata = new GameData("test_gamedata");
    if(gamedata == null)
        SetFailState("Failed to load gamedata.");

    StartPrepSDKCall(SDKCall_Entity);
    if (PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CBaseEntity::MyNextBotPointer"))
    {
        PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
        g_hGetNextBot = EndPrepSDKCall();
    } else LogError("Failed to find offset: \"CBaseEntity::MyNextBotPointer\"");

    StartPrepSDKCall(SDKCall_Raw);
    if (PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "INextBot::GetLocomotionInterface"))
    {
        PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
        g_hGetLocomotion = EndPrepSDKCall();
    } else LogError("Failed to find offset: \"INextBot::GetLocomotionInterface\"");

    StartPrepSDKCall(SDKCall_Raw);
    if (PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "ILocomotion::ClimbLadder"))
    {
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer);
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer);
        g_hClimbLadder = EndPrepSDKCall();
    } else LogError("Failed to find offset: \"ILocomotion::ClimbLadder\"");

    StartPrepSDKCall(SDKCall_Raw);
    if(PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CNavMesh::GetLadderCount"))
    {
        PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
        PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);

        PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
        g_hGetLadderCount = EndPrepSDKCall();
    } else LogError("Failed to find offset: \"CNavMesh::GetLadderCount\"");

    StartPrepSDKCall(SDKCall_Raw);
    if(PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CNavMesh::GetLadderByID"))
    {
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);

        PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
        g_hGetLadderByID = EndPrepSDKCall();
    } else LogError("Failed to find offset: \"CNavMesh::GetLadderByID\"");

    g_pCNavMesh = GameConfGetAddress(gamedata, "TerrorNavMesh");

    delete gamedata;
}

// bool CNavMesh::FindNavAreaOrLadderAlongRay(const Vector &start, const Vector &end, CNavArea **bestArea, CNavLadder **bestLadder, CNavArea *ignore)
// origin: https://github.com/SourceSDK2013Ports/csgo-src/blob/main/src/game/server/nav_edit.cpp#L235
// bool FindNavAreaOrLadderAlongRay(Address navMesh, const float from[3], const float to[3], int &navArea, int &navLadder, int areaIgnore = -1)
// {
//     if(!navMesh) return false;

//     return SDKCall(g_hFindNavAreaOrLadder, navMesh, from, to, navArea, navLadder, areaIgnore);
// }
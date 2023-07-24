/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-07-03 00:23:44
 * @Last Modified time: 2023-07-14 23:12:16
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sdkhooks>
#include <paiutils>
#include <sourcemod>
#include <left4dhooks>

#define DEBUG 1

#if DEBUG
    #include <vector_show.sp>
#endif

Address
    g_pCNavMesh;

Handle
    // g_hIsUsingLadder,
    // g_hClimbUpToLedge,
    // g_hIsClimbingUpToLedge,
    // g_hFindNavAreaOrLadder,
    g_hGetLadderByID,
    g_hGetLadderCount,
    // g_hFindLadderEntity;

    g_hClimbLadder,
    // g_hDescendLadder,

    g_hGetNextBot,
    g_hGetLocomotion;

public Plugin myinfo =
{
    name = "Test GameData",
    author = "我是派蒙啊",
    description = "控制女巫",
    version = "",
    url = ""
};

public void OnPluginStart()
{
    InitGameData();
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
    if(!IsValidClient(client)) return Plugin_Continue;
    int oldbtns = GetEntProp(client, Prop_Data, "m_nOldButtons");
    if(!((buttons & IN_RELOAD) && !(oldbtns & IN_RELOAD))) return Plugin_Continue;

    int max = SDKCall(g_hGetLadderCount, g_pCNavMesh);
    // PrintToChat(client, "%d", max);
    int[] ladders = new int[max];
    int count = 0;
    int index = 0;
    int ent_count = GetMaxEntities();
    while(count < max)
    {
        if(index > ent_count) break;
        int navLadder = SDKCall(g_hGetLadderByID, g_pCNavMesh, index++);
        if(!navLadder) continue;
        ladders[count++] = navLadder;
        PrintToChat(client, "%d", navLadder);
    }

    float pos[3]; index = 0;
    int witch = MaxClients + 1;
    while((witch = FindEntityByClassname(witch, "witch")) && IsValidEntity(witch))
    {
        if(index == max)
        {
            PrintToChat(client, "end");
            break;
        }
        Address nextbot = SDKCall(g_hGetNextBot, witch);
        if (!nextbot) return Plugin_Handled;

        Address locomotion = SDKCall(g_hGetLocomotion, nextbot);
        if (!locomotion) return Plugin_Handled;
        GetEntPropVector(witch, Prop_Send, "m_vecOrigin", pos);
        PrintToChat(client, "%d climb %d", witch, ladders[index]);
        SDKCall(g_hClimbLadder, locomotion, ladders[index++], L4D_GetNearestNavArea(pos));
    }
//     int area, ladder;
//     float start[3], end[3], ang[3], fwd[3];
//     GetClientAbsOrigin(client, start);
//     GetClientEyeAngles(client, ang);

//     start[2] += 70;
//     GetAngleVectors(ang, fwd, NULL_VECTOR, NULL_VECTOR);
//     NormalizeVector(fwd, fwd);
//     ScaleVector(fwd, 400.0);
//     for(int i = 0; i < 3; i++)
//         end[i] = start[i] + fwd[i];

// #if DEBUG
//     ShowPos(4, start, end, 10.0, 0.0, 0.0, 3.0);
// #endif
//     // SDKCall(g_hFindNavAreaOrLadder, g_pCNavMesh, start, end, area, ladder);
//     bool result = FindNavAreaOrLadderAlongRay(g_pCNavMesh, start, end, area, ladder);
//     // PrintToChat(client, "result %d, area %d, ladder %d", result, area, ladder);

//     return Plugin_Continue;
//     int witch = MaxClients + 1;
//     while ( (witch = FindEntityByClassname(witch, "witch")) && IsValidEntity(witch))
//     {
//         Address nextbot = SDKCall(g_hGetNextBot, witch);
//         if (!nextbot) return Plugin_Continue;

//         Address locomotion = SDKCall(g_hGetLocomotion, nextbot);
//         if (!locomotion) return Plugin_Continue;

//         // bool result = SDKCall(g_hIsUsingLadder, locomotion);

//         PrintToChat(client, "%d", result);
//     }

    return Plugin_Continue;
}

public void Useless()
{
}

/*
Action Cmd_Test(int client, int args)
{
    int witch = MaxClients + 1;
    while ( (witch = FindEntityByClassname(witch, "witch")) && IsValidEntity(witch))
    {
        Address nextbot = SDKCall(g_hGetNextBot, witch);
        if (!nextbot) return Plugin_Handled;

        Address locomotion = SDKCall(g_hGetLocomotion, nextbot);
        if (!locomotion) return Plugin_Handled;

        // bool onladder = SDKCall(g_hIsUsingLadder, locomotion);
        
        // PrintToChatAll("%d onladder %d", witch, onladder);

        int client = 0;
        while(!IsValidClient(++client) || IsFakeClient(client))
            continue;
        // while(!IsSurvivor(++client) || !IsFakeClient(client))
        //     continue;

        float target[3], rotate[3];
        GetClientAbsOrigin(client, target);
        GetEntPropVector(witch, Prop_Send, "m_angRotation", rotate);
        float fwd[3] = {0.0, 90.0, 0.0}, right[3], up[3];
        GetAngleVectors(rotate, fwd, right, up);
        bool result = SDKCall(g_hClimbUpToLedge, locomotion, target, fwd, witch);
        PrintToChatAll("climb to: (%.2f, %.2f, %.2f) \nforward: (%.2f, %.2f, %.2f) \ntarget: %N \nresult: %d",
            target[0], target[1], target[2], rotate[0], rotate[1], rotate[2], client, result);
    //ILocomotion::ClimbUpToLedge(Vector const&,Vector const&,CBaseEntity const*)

    }
    // float start[3], ang[3], end[3];
    // GetClientEyePosition(client, start);
    // GetClientAbsOrigin(client, ang);

    // GetClientEyePosition(client, end);
    // end[0] += 10000;

    // int area[99], ladder[99];
    // int ignore;
    // // CNavMesh::FindNavAreaOrLadderAlongRay(
    // //      Vector const&,Vector const&,
    // //      CNavArea **,CNavLadder **,CNavArea *)
    // SDKCall(g_hFindNavAreaOrLadder, g_pCNavMesh, start, end, area, ladder, ignore);
    // for(int i = 0; i < 99; i++)
    //     for(int v =  0; v < 99; v++)
    //         PrintToChat(client, "area %d, ladder %d", area[i], ladder[i]);

    return Plugin_Handled;
}

Action Cmd_Test2(int client, int args)
{
    int witch = MaxClients + 1;
    while ( (witch = FindEntityByClassname(witch, "witch")) && IsValidEntity(witch))
    {
        Address nextbot = SDKCall(g_hGetNextBot, witch);
        if (!nextbot) return Plugin_Handled;

        Address locomotion = SDKCall(g_hGetLocomotion, nextbot);
        if (!locomotion) return Plugin_Handled;

        bool climb = SDKCall(g_hIsClimbingUpToLedge, locomotion);
        
        PrintToChatAll("%d climbing %d", witch, climb);
    }
    return Plugin_Handled;
}
*/

void InitGameData()
{
    GameData gamedata = new GameData("witch_control");
    if(gamedata == null)
        SetFailState("Failed to load \"witch_control.txt\" gamedata.");

    // StartPrepSDKCall(SDKCall_Raw);
    // if(PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "ILocomotion::IsClimbingUpToLedge"))
    // {
    //     PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
    //     g_hIsClimbingUpToLedge = EndPrepSDKCall();
    // } else LogError("Failed to find offset: \"ILocomotion::IsClimbingUpToLedge\"");

    // StartPrepSDKCall(SDKCall_Raw);
    // if(PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "ILocomotion::ClimbUpToLedge"))
    // {
    //     //bool ClimbUpToLedge( const Vector &landingGoal,
    //     //  const Vector &landingForward, const CBaseEntity *obstacle )
    //     PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
    //     PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
    //     PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
    //     PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
    //     g_hClimbUpToLedge = EndPrepSDKCall();
    // } else LogError("Failed to find offset: \"ILocomotion::ClimbUpToLedge\"");

    StartPrepSDKCall(SDKCall_Entity);
    if(PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CBaseEntity::MyNextBotPointer"))
    {
        PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
        g_hGetNextBot = EndPrepSDKCall();
    } else LogError("Failed to find offset: \"CBaseEntity::MyNextBotPointer\"");

    StartPrepSDKCall(SDKCall_Raw);
    if(PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "INextBot::GetLocomotionInterface"))
    {
        PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
        g_hGetLocomotion = EndPrepSDKCall();
    } else LogError("Failed to find offset: \"INextBot::GetLocomotionInterface\"");

    StartPrepSDKCall(SDKCall_Raw);
    if(PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "ILocomotion::ClimbLadder"))
    {
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer);
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer);
        g_hClimbLadder = EndPrepSDKCall();
    } else LogError("Failed to find offset: \"ILocomotion::ClimbLadder\"");

    // StartPrepSDKCall(SDKCall_Raw);
    // if(PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "ILocomotion::DescendLadder"))
    // {
    //     PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer);
    //     PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer);
    //     g_hDescendLadder = EndPrepSDKCall();
    // } else LogError("Failed to find offset: \"ILocomotion::DescendLadder\"");

    // StartPrepSDKCall(SDKCall_Raw);
    // if(PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "ILocomotion::IsUsingLadder"))
    // {
    //     PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
    //     g_hIsUsingLadder = EndPrepSDKCall();
    // } else LogError("Failed to find offset: \"ILocomotion::IsUsingLadder\"");

    // StartPrepSDKCall(SDKCall_Raw);
    // if(PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CNavMesh::FindNavAreaOrLadderAlongRay"))
    // {
    //     PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
    //     PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
    //     PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByRef);
    //     PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByRef);
    //     PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);

    //     PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
    //     g_hFindNavAreaOrLadder = EndPrepSDKCall();
    // } else LogError("Failed to find offset: \"CNavMesh::FindNavAreaOrLadderAlongRay\"");

    StartPrepSDKCall(SDKCall_Raw);
    if(PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CNavMesh::GetLadderByID"))
    {
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);

        PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
        g_hGetLadderByID = EndPrepSDKCall();
    } else LogError("Failed to find offset: \"CNavMesh::CNavMesh::GetLadderByID\"");

    StartPrepSDKCall(SDKCall_Raw);
    if(PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CNavMesh::GetLadderCount"))
    {
        PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
        g_hGetLadderCount = EndPrepSDKCall();
    } else LogError("Failed to find offset: \"CNavMesh::GetLadderCount\"");

    // StartPrepSDKCall(SDKCall_Raw);
    // if(PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CNavLadder::FindLadderEntity"))
    // {
    //     PrepSDKCall_SetReturnInfo(SDKType_Edict, SDKPass_Pointer);
    //     g_hFindLadderEntity = EndPrepSDKCall();
    // } else LogError("Failed to find offset: \"CNavLadder::FindLadderEntity\"");

    g_pCNavMesh = GameConfGetAddress(gamedata, "TerrorNavMesh");

    delete gamedata;
}

// bool FindNavAreaOrLadderAlongRay(Address navMesh, const float from[3], const float to[3], int &navArea, int &navLadder, int areaIgnore = -1)
// {
//     if(!navMesh) return false;
//     PrintToChatAll("before: area %d, ladder %d", navArea, navLadder);

//     bool result = SDKCall(g_hFindNavAreaOrLadder, navMesh, from, to, navArea, navLadder, areaIgnore);

//     PrintToChatAll("result %d, area %d, ladder %d", result, navArea, navLadder);
// }
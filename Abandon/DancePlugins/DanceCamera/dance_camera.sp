/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-03-18 22:22:37
 * @Last Modified time: 2023-07-14 23:12:16
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <paiutils>
#include <sourcemod>
#include <keyvalues>
// #include <clientprefs>
// #undef REQUIRE_PLUGIN
#include <fnemotes>
#undef REQUIRE_PLUGIN
#include <freecamera>

#define VERSION "2023.03.25"
#define MAXSIZE 33

#define CAMERA_MODEL "models/editor/camera.mdl"
#define GHOST_MODEL "models/tools/toolsnodraw.mdl"

int
    g_iGhostEnt[MAXSIZE] = {-1, ...},
    g_iCameraEnt[MAXSIZE] = {-1, ...};

bool
    g_bIsDancing[MAXSIZE] = {false, ...},
    g_bIsCameraActive[MAXSIZE] = {false, ...};

ConVar
    g_hDanceCameraEnable;

public Plugin myinfo =
{
    name = "Dance Camera",
    author = "我是派蒙啊",
    description = "跳舞摄像机，提供类似MMD的跳舞镜头控制",
    version = VERSION,
    url = "https://github.com/Paimon-Kawaii/L4D2-Plugins/tree/main/MyPlugins"
};

public void OnPluginStart()
{
    // Convars
    CreateConVars();
    // Execute cfg
    HookEvent("player_death", Event_PlayerDead, EventHookMode_Pre);
    AutoExecConfig(true, "dance_camera");
}

void CreateConVars()
{
    // Turn on/off dance camera, 1 for on, 0 for off
    g_hDanceCameraEnable = CreateConVar("dance_camera_allow", "1", "开启跳舞相机, 1=开启 0=关闭");
}

void Event_PlayerDead(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(!IsValidClient(client)) return;
    int camera = GetClientCamera(client);
    if(!IsValidEntity(client) || !IsClientCameraActive(client)) return;

    g_bIsCameraActive[client] = false;
    AcceptEntityInput(camera, "Disable", client);
    AcceptEntityInput(camera, "Kill");
    RemoveEntity(camera);
}

public void OnClientDisconnect(int client)
{
    g_bIsDancing[client] = g_bIsCameraActive[client] = false;
    int camera = GetClientCamera(client);
    if(IsValidEntity(camera))
    {
        AcceptEntityInput(camera, "Disable");
        AcceptEntityInput(camera, "Kill");
        RemoveEntity(camera);
    }
}

public void OnMapStart()
{
    if (!IsModelPrecached(CAMERA_MODEL) || !IsModelPrecached(GHOST_MODEL))
    {
        PrecacheModel(CAMERA_MODEL);
        PrecacheModel(GHOST_MODEL);
    }
}

public void OnMapEnd()
{
    for (int i = 1; i <= MaxClients; i++)
        DisableCamera(i);
}

public Action OnPlayerRunCmd(int client)
{
    if(IsSurvivor(client) && g_hDanceCameraEnable.BoolValue && !fnemotes_IsClientEmoting(client) && IsClientCameraActive(client))
        DisableCamera(client);

    return Plugin_Continue;
}

public void fnemotes_OnEmote(int client)
{
    if (IsSurvivor(client) && g_hDanceCameraEnable.BoolValue)
        EnableCamera(client);
}

public Action FC_OnPlayerCameraActived(int &client)
{
    if(IsValidClient(client) && g_hDanceCameraEnable.BoolValue)
        return Plugin_Handled;

    return Plugin_Continue;
}

void EnableCamera(int client)
{
    if (!IsSurvivor(client))
        return;

    // Try get a camera
    int camera = CreateCamera(client);
    if (!IsValidEntity(camera))
        return;

    // Now we got our camera, let player view it.
    SetClientCamera(client, camera);
    g_bIsCameraActive[client] = true;
    AcceptEntityInput(camera, "Enable", client);
}

void DisableCamera(int client)
{
    if (!IsSurvivor(client))
        return;

    int camera = GetClientCamera(client);
    int ghost = EntRefToEntIndex(g_iGhostEnt[client]);
    // If player has a camera, disable it.
    if (IsValidEntity(camera))
    {
        g_bIsCameraActive[client] = false;
        AcceptEntityInput(camera, "Disable", client);
        AcceptEntityInput(camera, "Kill");
        RemoveEntity(camera);
    }
    if (IsValidEntity(ghost))
    {
        AcceptEntityInput(ghost, "Disable", client);
        AcceptEntityInput(ghost, "Kill");
        RemoveEntity(ghost);
    }
}

int CreateCamera(int target)
{
    int camera;
    // float origin[3], rotate[3], lookat[3];

    // GetEntPropVector(target, Prop_Send, "m_vecOrigin", origin);
    // GetEntPropVector(target, Prop_Send, "m_angRotation", rotate);

    camera = GetClientCamera(target);
    if (!IsValidEntity(camera))
        camera = CreateEntityByName("point_viewcontrol_survivor");

    // GetAngleVectors(rotate, lookat, NULL_VECTOR, NULL_VECTOR);
    // NormalizeVector(lookat, lookat);
    // ScaleVector(lookat, -50.0);
    // AddVectors(lookat, origin, origin);
    // rotate[0] = 30.0;
    // origin[2] += 100.0;

    // CreateAndPlayIntro3(camera, target);
    CreateAndPlayIntro2(camera, target);
    // CreateAndPlayIntro(camera, target);

    return camera;
}

void CreateAndPlayIntro3(int camera, int target)
{
    char ptrack[10][64];
    float origin[3], rotate[3], pos[3];
    GetClientAbsOrigin(target, origin);
    GetClientAbsAngles(target, rotate);
    // GetEntPropVector(target, Prop_Send, "m_vecOrigin", origin);
    // GetEntPropVector(target, Prop_Send, "m_angRotation", rotate);

    for(int i = 0; i < 10; i++)
    {
        Format(ptrack[i], 64, "path_track_%d_%d", i, GetRandomInt(10000, 99999));
        // PrintToChatAll("%s", ptrack[i]);
    }

    int path_track[10];
    for(int i = 0; i < 10; i++)
    {
        path_track[i] = CreateEntityByName("path_corner");
        // path_track[i] = CreateEntityByName("path_track");
        DispatchKeyValue(path_track[i], "targetname", ptrack[i]);
        DispatchKeyValueFloat(path_track[i], "speed", GetRandomInt(32, 128) * 20.0);

        for(int v = 0; v < 3; v++)
        {
            pos[v] = origin[v] + GetRandomInt(10, 20);
            rotate[v] += GetRandomInt(0, 360);
        }

        if(i == 0)
        {
            DispatchKeyValue(camera, "moveto", ptrack[i]);
            // DispatchKeyValueFloat(camera, "speed", GetRandomInt(32, 128) * 20.0);
            DispatchKeyValueVector(camera, "origin", pos);
            DispatchKeyValueVector(camera, "angles", rotate);
        }

        DispatchKeyValueVector(path_track[i], "origin", pos);
        DispatchKeyValueVector(path_track[i], "angles", rotate);
        DispatchKeyValueFloat(path_track[i], "wait", GetRandomInt(1, 5) * 100.0);
        if(i < 9) DispatchKeyValue(path_track[i], "target", ptrack[i + 1]);
    }

    for(int i = 0; i < 10; i++)
    {
        DispatchSpawn(path_track[i]);
        ActivateEntity(path_track[i]);
    }

    DispatchSpawn(camera);
    ActivateEntity(camera);
    AcceptEntityInput(camera, "Enable");
}

void CreateAndPlayIntro2(int camera, int target)
{
    char ftrack[64], ptrack[10][64];

    int func_track = CreateEntityByName("func_tracktrain");
    Format(ftrack, sizeof(ftrack), "func_track_%d", GetRandomInt(10000, 99999));
    DispatchKeyValue(func_track, "targetname", ftrack);
    DispatchKeyValue(func_track, "height", "0");

    float origin[3], rotate[3], pos[3];
    GetClientAbsOrigin(target, origin);
    GetClientAbsAngles(target, rotate);

    for(int i = 0; i < 10; i++)
    {
        Format(ptrack[i], 64, "path_track_%d_%d", i, GetRandomInt(10000, 99999));
        // PrintToChatAll("%s", ptrack[i]);
    }

    int path_track[10];
    for(int i = 0; i < 10; i++)
    {
        path_track[i] = CreateEntityByName("path_track");
        DispatchKeyValue(path_track[i], "targetname", ptrack[i]);

        for(int v = 0; v < 3; v++)
        {
            pos[v] = origin[v] + GetRandomInt(10, 20);
            rotate[v] += GetRandomInt(0, 360);
        }

        if(i == 0)
        {
            DispatchKeyValue(func_track, "target", ptrack[i]);
            DispatchKeyValueVector(camera, "origin", pos);
            DispatchKeyValueVector(func_track, "origin", pos);
            // DispatchKeyValueVector(func_track, "angles", rotate);
        }

        DispatchKeyValueVector(path_track[i], "origin", pos);
        DispatchKeyValueVector(path_track[i], "angles", rotate);
        DispatchKeyValue(path_track[i], "model", GHOST_MODEL);
        if(i < 9) DispatchKeyValue(path_track[i], "target", ptrack[i + 1]);
    }

    for(int i = 0; i < 10; i++)
    {
        DispatchSpawn(path_track[i]);
        ActivateEntity(path_track[i]);
        AcceptEntityInput(path_track[i], "EnablePath");
        AcceptEntityInput(path_track[i], "EnableAlternatePath");
    }

    DispatchKeyValue(camera, "model", CAMERA_MODEL);
    // DispatchKeyValue(func_track, "model", GHOST_MODEL);
    DispatchSpawn(camera);
    ActivateEntity(camera);
    DispatchSpawn(func_track);
    ActivateEntity(func_track);

    SetVariantString(ftrack);
    AcceptEntityInput(camera, "SetParent");
    SetVariantFloat(64.0);
    AcceptEntityInput(func_track, "SetSpeed");
    // SetVariantString("eyes");
    // AcceptEntityInput(camera, "SetParentAttachment");
    // AcceptEntityInput(func_track, "Toggle");
    AcceptEntityInput(camera, "Enable");
    SetVariantString(ptrack[0]);
    AcceptEntityInput(func_track, "MoveToPathNode");
}

void CreateAndPlayIntro(int camera, int target)
{
    char ghostname[64], cameraname[64];
    int ghost = CreateEntityByName("prop_dynamic");
    DispatchKeyValue(ghost, "model", GHOST_MODEL);
    FormatEx(ghostname, sizeof(ghostname), "ghostAnim%i", GetRandomInt(1000000, 9999999));
    DispatchKeyValue(ghost, "targetname", ghostname);
    DispatchSpawn(ghost);
    ActivateEntity(ghost);
    SetVariantString("c4m1_intro");
    AcceptEntityInput(ghost, "SetAnimation");
    g_iGhostEnt[target] = EntIndexToEntRef(ghost);

    DispatchKeyValue(camera, "model", CAMERA_MODEL);
    // DispatchKeyValueVector(camera, "origin", origin);
    FormatEx(cameraname, sizeof(cameraname), "testCam%i", GetRandomInt(1000000, 9999999));
    DispatchKeyValue(camera, "targetname", cameraname);
    DispatchSpawn(camera);
    ActivateEntity(camera);

    SetVariantString(ghostname);
    AcceptEntityInput(camera, "SetParent");
    SetVariantString("Attachment_1");
    AcceptEntityInput(camera, "SetParentAttachment");
    AcceptEntityInput(camera, "Enable");

    // Fix position
    float tpos[3], cpos[3];
    GetClientAbsOrigin(target, tpos);
    GetEntPropVector(camera, Prop_Send, "m_vecOrigin", cpos);
    float dis = GetVectorDistance(tpos, cpos);
    // tpos[2] -= 100;
    if (dis > 500)
        TeleportEntity(ghost, tpos, NULL_VECTOR, NULL_VECTOR);
}

int GetClientCamera(int client)
{
    if (!IsValidClient(client))
        return -1;

    return EntRefToEntIndex(g_iCameraEnt[client]);
}

bool IsClientCameraActive(int client)
{
    if (!IsValidClient(client))
        return false;

    return g_bIsCameraActive[client];
}

bool SetClientCamera(int client, int entity)
{
    if (!IsValidClient(client))
        return false;

    g_iCameraEnt[client] = IsValidEntity(entity) ? EntIndexToEntRef(entity) : -1;
    return true;
}
/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-12-22 20:31:48
 * @Last Modified time: 2024-01-06 12:12:53
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <sdkhooks>
#include <sdktools>
#include <paiutils>
#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <flashlight>

#define VERSION "2024.01.04"

#define DEBUG 0

int g_BeamSprite;
bool g_bFlashAvailable;

ConVar g_hLightTrail;
// Handle g_iBeamTimer[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name = "光影随行",
    author = "我是派蒙啊",
    description = "",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins/MyPlugins"
};

public void OnPluginStart()
{
    g_hLightTrail = CreateConVar("light_trail_enable", "1", "光尾开关", FCVAR_NONE, _, _, true, 1.0);
}

public void OnMapStart()
{
    g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public void OnLibraryAdded(const char[] name)
{
    if (!strcmp(name, "fnemotes", false))
        g_bFlashAvailable = true;
}

public void OnLibraryRemoved(const char[] name)
{
    if (!strcmp(name, "fnemotes", false))
        g_bFlashAvailable = false;
}

// Action Say_Callback(int client, char[] command, int args)
// {
//     char say[MAX_NAME_LENGTH];
//     GetCmdArg(1, say, sizeof(say));

//     if((say[0] != '!' && say[0] != '/'))
//         return Plugin_Continue;

//     say[0] = '!';
//     if(strcmp(say,"!light", false))
//         return Plugin_Continue;

//     return Plugin_Continue;
// }

public void FL_OnPlayerLightOn(int client)
{
    if(!g_hLightTrail || !g_hLightTrail.BoolValue)
        return;

    CreateTimer(1.0, Timer_LightActive, client, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
}

// public void FL_OnPlayerLightOff(int client)
// {
//     PrintToChatAll("%N Off", client);
//     if(g_iBeamTimer[client] == INVALID_HANDLE) return;

//     KillTimer(g_iBeamTimer[client]);
//     g_iBeamTimer[client] = INVALID_HANDLE;
// }

Action Timer_LightActive(Handle timer, int client)
{
    if(!IsValidClient(client) || !IsPlayerAlive(client))
        return Plugin_Stop;
    if(!g_hLightTrail || !g_hLightTrail.BoolValue)
        return Plugin_Stop;
    if(g_bFlashAvailable && !FL_IsLightOn(client))
        return Plugin_Stop;

    SetUpBeamSpirit(client, 2.0, 7.0, 100);
    // PrintToChatAll("%N beam", client);
    return Plugin_Continue;
}

void SetUpBeamSpirit(int client, float life, float width, int alpha)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client)) return;

    int beamEnt = CreateEntityByName("prop_dynamic_override", -1);
    float pos[3];
    GetClientAbsOrigin(client, pos);
    if (!IsValidEdict(beamEnt)) return;

    float beamPos[3], beamAng[3];
    GetEntPropVector(client, Prop_Send, "m_vecOrigin", beamPos);
    GetEntPropVector(client, Prop_Data, "m_angRotation", beamAng);
    DispatchKeyValue(beamEnt, "model", "models/editor/camera.mdl");
    SetEntPropVector(beamEnt, Prop_Send, "m_vecOrigin", beamPos);
    SetEntPropVector(beamEnt, Prop_Send, "m_angRotation", beamAng);
    DispatchSpawn(beamEnt);
    SetEntPropFloat(beamEnt, Prop_Send, "m_flModelScale", 0.0);
    SetEntProp(beamEnt, Prop_Send, "m_nSolidType", 6);
    SetEntityRenderMode(beamEnt, RENDER_TRANSCOLOR);
    SetEntityRenderColor(beamEnt, 255, 255, 255, 0);
    SetVariantString("!activator");
    AcceptEntityInput(beamEnt, "SetParent", client, _, 0);
    SetVariantString("spine");
    AcceptEntityInput(beamEnt, "SetParentAttachment");
    int colorA[4], colorB[4];
    for(int i = 0; i < 3; i++)
    {
        colorA[i] = GetRandomInt(0, 255);
        colorB[i] = GetRandomInt(0, 255);
    }
    colorA[3] = colorB[3] = alpha;
    TE_SetupBeamFollow(beamEnt, g_BeamSprite, 100, life, width, 1.0, 3, colorA);
    TE_SendToAll();
    TE_SetupBeamFollow(beamEnt, g_BeamSprite, 100, life, 1.0, 1.0, 3, colorB);
    TE_SendToAll();
    // PrintToChatAll("%d", beamEnt);

    CreateTimer(1.2, Timer_DeleteParticles, beamEnt, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_DeleteParticles(Handle timer, int beam)
{
    if (IsValidEntity(beam))
        KillEntity(beam);

    return Plugin_Stop;
}

void KillEntity(int entity)
{
    if(!IsValidEntity(entity)) return;
    SetEntityFlags(entity, GetEntityFlags(entity) | FL_KILLME);
#if SOURCEMOD_V_MINOR > 8
    RemoveEntity(entity);
#else
    AcceptEntityInput(entity, "Kill");
#endif
}
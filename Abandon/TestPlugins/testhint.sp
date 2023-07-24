/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-07-07 14:27:53
 * @Last Modified time: 2023-07-07 15:45:11
 * @Github:             https://github.com/Paimon-Kawaii
 */
#pragma semicolon 1
#pragma newdecls required
 
#include <sdktools>
#include <sdkhooks>

public void OnPluginStart()
{    
    RegConsoleCmd("sm_hint", cHint);
}

public Action cHint (int client, int args)
{
    if(!client || !IsClientInGame(client) || !IsPlayerAlive(client)) return Plugin_Handled;
    
    // Event hevent = CreateEvent("instructor_server_hint_create", true);
    // hevent.FireToClient(client);

    float vOrigin[3], vAngles[3];
    GetClientEyeAngles(client, vAngles);
    GetClientEyePosition(client, vOrigin);
        
    Handle TraceRay = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceFilter, client);
        
    if (TR_DidHit(TraceRay))
        TR_GetEndPosition(vOrigin, TraceRay);
        
    vOrigin[2] += 25.0;
    delete TraceRay;

    /*To Alive Survivor and Infected players*/
    //int entity = CreateEntityByName("info_target_instructor_hint"); 
    //DispatchKeyValue(entity, "targetname", "123456");
    //DispatchSpawn(entity);
    //TeleportEntity(entity, vOrigin, NULL_VECTOR, NULL_VECTOR);

    /*To only Alive Survivors*/
    int entity = CreateEntityByName("info_target"); 
    DispatchKeyValue(entity, "targetname", "123456");
    DispatchKeyValue(entity, "spawnflags", "1");
    DispatchSpawn(entity);
    TeleportEntity(entity, vOrigin, NULL_VECTOR, NULL_VECTOR);
    SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);

    char szBuffer[36];
    Format(szBuffer, sizeof szBuffer, "OnUser1 !self:Kill::%f:-1", 10.0);

    SetVariantString(szBuffer); 
    AcceptEntityInput(entity, "AddOutput"); 
    AcceptEntityInput(entity, "FireUser1");


    entity = CreateEntityByName("env_instructor_hint");
    DispatchKeyValue(entity, "hint_timeout", "10");
    DispatchKeyValue(entity, "hint_allow_nodraw_target", "1");
    DispatchKeyValue(entity, "hint_target", "123456"); //a entity's targetname
    DispatchKeyValue(entity, "hint_auto_start", "1");
    DispatchKeyValue(entity, "hint_color", "200 200 200");
    DispatchKeyValue(entity, "hint_icon_offscreen", "icon_info");
    DispatchKeyValue(entity, "hint_instance_type", "0");
    DispatchKeyValue(entity, "hint_icon_onscreen", "icon_info");
    DispatchKeyValue(entity, "hint_caption", "Hello, this is custom message");
    DispatchKeyValue(entity, "hint_static", "0");
    DispatchKeyValue(entity, "hint_nooffscreen", "0");
    DispatchKeyValue(entity, "hint_icon_offset", "10");
    DispatchKeyValue(entity, "hint_range", "800");
    DispatchKeyValue(entity, "hint_forcecaption", "1");
    DispatchSpawn(entity);
    TeleportEntity(entity, vOrigin, NULL_VECTOR, NULL_VECTOR); 

    SetVariantString(szBuffer); 
    AcceptEntityInput(entity, "AddOutput"); 
    AcceptEntityInput(entity, "FireUser1");
    
    return Plugin_Handled;
}

public bool TraceFilter (int entity, int mask, int client)
{
    if (entity == client)
        return false;
    return true;
} 

public Action Hook_SetTransmit(int entity, int client)
{
    if( GetClientTeam(client) != 3)
        return Plugin_Handled;
    
    return Plugin_Continue;
}
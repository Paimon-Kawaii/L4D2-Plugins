/*
 * @Author:             派蒙
 * @Last Modified by:   派蒙
 * @Create Date:        2022-06-04 14:53:37
 * @Last Modified time: 2022-06-19 15:19:59
 * @Github:             http://github.com/PaimonQwQ
 */

#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <l4d2tools>
#include <sourcemod>
#include <left4dhooks>

public void OnPluginStart()
{
    FindConVar("sm_min_lerp").SetBounds(ConVarBound_Lower, false);
    RegConsoleCmd("sm_lerp", Lerp_Cmd, "");
}

//插件信息
public Action Lerp_Cmd(int client, any args)
{
    char buffer[32];
    if(args < 1)
    {
        GetClientInfo(client, "cl_interp", buffer, sizeof(buffer));
        PrintToChat(client, "Lerp: %s", buffer);
        return Plugin_Handled;
    }
    GetCmdArg(1, buffer, sizeof(buffer));
    float lerp = StringToFloat(buffer);
    FindConVar("sm_min_lerp").SetFloat((lerp > 0 ? lerp * -1 : lerp) * 10);
    Format(buffer, sizeof(buffer), "%.2f", lerp / 10);
    SetClientInfo(client, "cl_interp_ratio", buffer);
    GetClientInfo(client, "cl_interp_ratio", buffer, sizeof(buffer));
    PrintToChat(client, "Lerp-Ratio: %s", buffer);

    return Plugin_Handled;
}

// bool CreateStatic(int& prop, const char[] model)
// {
//     prop = CreateEntityByName("prop_dynamic_override");
//     DispatchKeyValue(prop, "model", model);
//     DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
//     SetEntProp(prop, Prop_Send, "m_nSolidType", 6);
//     return DispatchSpawn(prop);
// }

public Action OnPlayerRunCmd(int client, int &buttons, int &impuls)
{
    if(!IsValidClient(client) || IsFakeClient(client))
        return Plugin_Continue;

    if(buttons & IN_ZOOM)
    {
        char model[256];
        int entity = GetClientAimTarget(client, false);
        if(!IsValidEntity(entity)) return Plugin_Continue;
        GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
        if(!StrContains(model, "mdl", false)) return Plugin_Continue;
        PrintToChat(client, "model => %s", model);
        if (!IsModelPrecached(model))
            PrecacheModel(model);

        SetEntityModel(client, model);
        buttons &= ~IN_ZOOM;
    }

    return Plugin_Continue;
}

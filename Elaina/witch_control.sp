/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-06-28 11:33:15
 * @Last Modified time: 2023-07-14 23:12:16
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#define DEBUG 0

// #include <menus>
#include <dhooks>
#include <actions>
#include <sdktools>
#include <sdkhooks>
#include <paiutils>
#include <sourcemod>

#if DEBUG
    #include "vector_show.sp"
#endif

#define VERSION "2023.06.28"
#define MAXSIZE MAXPLAYERS + 1

#define ANIM_STANDING_CRYING 2 //
#define ANIM_SITTING 4 //
#define ANIM_CATCHING_TARGET 6 //
#define ANIM_SETTING_ANGRY 29 //
#define ANIM_FALL 54 //
#define ANIM_RUN_JUMP 57 //

#define INVALID_NAV_LADDER -1
#define MENU_DISPLAY_INFINITE 0

#define CAMERA_MODEL "models/editor/camera.mdl"

int
    g_iWitch[MAXSIZE] = { -1, ... },
    g_iCamera[MAXSIZE] = { -1, ... };

float
    g_fLiftHeight[MAXSIZE];

bool
    g_bWitchAngry[MAXSIZE],
    g_bAngryResume[MAXSIZE],
    g_bWitchControl[MAXSIZE];

ConVar
    g_hWitchWander,
    g_hWitchWalkSpeed;

// Address
//     g_pCNavMesh;

Handle
    g_hGetNextBot,
    g_hGetLocomotion,

    // g_hClimbLadder,
    // g_hDescendLadder,
    // g_hFindNavAreaOrLadder,

    g_hResetStatus,
    g_hClimbUpToLedge,

    g_hSetZombieClass,
    g_hSetAcceleration,

    // g_hIsUsingLadder,
    g_hIsClimbingUpToLedge;

public Plugin myinfo =
{
    name = "Witch Control",
    author = "我是派蒙啊",
    description = "控制女巫",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins"
};

public void OnPluginStart()
{
    if(!InitGameData())
        SetFailState("Failed to load gamedata: \"witch_control.txt\", content incorrect.");

    LoadTranslations("witch_control.phrases");

    g_hWitchWander = FindConVar("witch_force_wander");
    g_hWitchWander.SetBool(false);
    // g_hWitchWalkSpeed = FindConVar("z_witch_speed");
    g_hWitchWalkSpeed = FindConVar("z_witch_speed_inured");

    HookEvent("round_start", Event_RoundStart);
    HookEvent("witch_spawn", Event_WitchSpawned);
    AddNormalSoundHook(StopControlSound);
}

bool InitGameData()
{
    GameData gamedata = new GameData("witch_control");
    if (gamedata == null)
        SetFailState("Gamedata not found: \"witch_control.txt\".");

    bool status = true;
    StartPrepSDKCall(SDKCall_Entity);
    if (PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CBaseEntity::MyNextBotPointer"))
    {
        PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
        g_hGetNextBot = EndPrepSDKCall();
    } else LogError("Failed to find offset: \"CBaseEntity::MyNextBotPointer\"");
    if(!g_hGetNextBot) status = false;

    StartPrepSDKCall(SDKCall_Raw);
    if (PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "INextBot::GetLocomotionInterface"))
    {
        PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
        g_hGetLocomotion = EndPrepSDKCall();
    } else LogError("Failed to find offset: \"INextBot::GetLocomotionInterface\"");
    if(!g_hGetLocomotion) status = false;

    StartPrepSDKCall(SDKCall_Player);
    if (PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTerrorPlayer::SetClass"))
    {
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
        g_hSetZombieClass = EndPrepSDKCall();
    } else LogError("Failed to load signature: \"CTerrorPlayer::SetClass\"");
    if(!g_hSetZombieClass) status = false;

    StartPrepSDKCall(SDKCall_Raw);
    if (PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "ILocomotion::Reset"))
    {
        PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
        g_hResetStatus = EndPrepSDKCall();
    } else LogError("Failed to find offset: \"ILocomotion::Reset\"");
    if(!g_hResetStatus) status = false;

    StartPrepSDKCall(SDKCall_Raw);
    if (PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "ILocomotion::SetAcceleration"))
    {
        PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
        g_hSetAcceleration = EndPrepSDKCall();
    } else LogError("Failed to find offset: \"ILocomotion::SetAcceleration\"");
    if(!g_hSetAcceleration) status = false;

    StartPrepSDKCall(SDKCall_Raw);
    if (PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "ILocomotion::ClimbUpToLedge"))
    {
        PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
        PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
        PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);

        PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
        g_hClimbUpToLedge = EndPrepSDKCall();
    } else LogError("Failed to find offset: \"ILocomotion::ClimbUpToLedge\"");
    if(!g_hClimbUpToLedge) status = false;

    StartPrepSDKCall(SDKCall_Raw);
    if (PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "ILocomotion::IsClimbingUpToLedge"))
    {
        PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
        g_hIsClimbingUpToLedge = EndPrepSDKCall();
    } else LogError("Failed to find offset: \"ILocomotion::IsClimbingUpToLedge\"");
    if(!g_hIsClimbingUpToLedge) status = false;

    // StartPrepSDKCall(SDKCall_Raw);
    // if (PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "ILocomotion::ClimbLadder"))
    // {
    //     PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer);
    //     PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer);
    //     g_hClimbLadder = EndPrepSDKCall();
    // } else LogError("Failed to find offset: \"ILocomotion::ClimbLadder\"");
    // if(!g_hClimbLadder) status = false;

    // StartPrepSDKCall(SDKCall_Raw);
    // if (PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "ILocomotion::DescendLadder"))
    // {
    //     PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer);
    //     PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer);
    //     g_hDescendLadder = EndPrepSDKCall();
    // } else LogError("Failed to find offset: \"ILocomotion::DescendLadder\"");
    // if(!g_hDescendLadder) status = false;

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

    // StartPrepSDKCall(SDKCall_Raw);
    // if (PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "ILocomotion::IsUsingLadder"))
    // {
    //     PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
    //     g_hIsUsingLadder = EndPrepSDKCall();
    // } else LogError("Failed to find offset: \"ILocomotion::IsUsingLadder\"");
    // if(!g_hIsUsingLadder) status = false;

    // DynamicDetour enterGhostDetour = DynamicDetour.FromConf(gamedata, "L4DD::CTerrorPlayer::OnEnterGhostState");
    // if (!enterGhostDetour || !enterGhostDetour.Enable(Hook_Post, OnEnterGhostState))
    //     LogError("Failed to load detour: \"L4DD::CTerrorPlayer::OnEnterGhostState\"");
    // if(!enterGhostDetour) status = false;

    // g_pCNavMesh = GameConfGetAddress(gamedata, "TerrorNavMesh");
    // if(!g_pCNavMesh) status = false;
    delete gamedata;

    return status;
}

/*
MRESReturn OnEnterGhostState(int pThis, DHookReturn hReturn, DHookParam hParams)
{
    if (IsInfected(pThis) && !IsTank(pThis) && !IsFakeClient(pThis))
        CreateWitchMenu(pThis);

    return MRES_Ignored;
}
*/

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        g_iWitch[client] = -1;
        g_fLiftHeight[client] = 0.0;
        g_bAngryResume[client] = g_bWitchAngry[client] = g_bWitchControl[client] = false;

        int camera = GetClientCamera(client);
        if (IsValidEntity(camera))
        {
            AcceptEntityInput(camera, "Kill");
            RemoveEntity(camera);
        }
        g_iCamera[client] = -1;
    }
}

// https://forums.alliedmods.net/showthread.php?t=336724
void Event_WitchSpawned(Event event, const char[] name, bool dontBroadcast)
{
    int witch = event.GetInt("witchid");
    int target = CreateEntityByName("info_target");
    if(!IsValidEntity(witch) || !IsValidEntity(target)) return;

    char buffer[64];
    float pos[3], ang[3], fwd[3];
    GetEntPropVector(witch, Prop_Send, "m_vecOrigin", pos);
    GetEntPropVector(witch, Prop_Send, "m_angRotation", ang);
    GetAngleVectors(ang, fwd, NULL_VECTOR, NULL_VECTOR);
    ScaleVector(fwd, 20.0);
    for(int i = 0; i < 3; i++)
        pos[i] += fwd[i];
    pos[2] += 20;

    Format(buffer, sizeof(buffer), "hint_target_%d", target);
    DispatchKeyValue(target, "targetname", buffer);
    DispatchKeyValue(target, "spawnflags", "1");
    DispatchSpawn(target);
    TeleportEntity(target, pos, NULL_VECTOR, NULL_VECTOR);
    SDKHook(target, SDKHook_SetTransmit, SetTransmit);

    Format(buffer, sizeof(buffer), "OnUser1 !self:Kill::%f:-1", 10.0);
    SetVariantString(buffer);
    AcceptEntityInput(target, "AddOutput");
    AcceptEntityInput(target, "FireUser1");

    int hint = CreateEntityByName("env_instructor_hint");
    DispatchKeyValue(hint, "hint_timeout", "0");
    DispatchKeyValue(hint, "hint_allow_nodraw_target", "1");
    Format(buffer, sizeof(buffer), "hint_target_%d", target);
    DispatchKeyValue(hint, "hint_target", buffer);
    DispatchKeyValue(hint, "hint_auto_start", "1");
    DispatchKeyValue(hint, "hint_color", "200 200 200");
    DispatchKeyValue(hint, "hint_icon_offscreen", "icon_tip");
    DispatchKeyValue(hint, "hint_instance_type", "0");
    DispatchKeyValue(hint, "hint_icon_onscreen", "icon_tip");
    Format(buffer, sizeof(buffer), "%T", "WitchControl", LANG_SERVER);
    DispatchKeyValue(hint, "hint_caption", buffer);
    DispatchKeyValue(hint, "hint_static", "0");
    DispatchKeyValue(hint, "hint_nooffscreen", "0");
    DispatchKeyValue(hint, "hint_icon_offset", "10");
    // DispatchKeyValue(hint, "hint_range", "800");
    DispatchKeyValue(hint, "hint_forcecaption", "1");

    DispatchSpawn(hint);
    TeleportEntity(hint, pos, NULL_VECTOR, NULL_VECTOR);
    AcceptEntityInput(hint, "ShowHint");

    Format(buffer, sizeof(buffer), "OnUser1 !self:Kill::%f:-1", 10.0);
    SetVariantString(buffer);
    AcceptEntityInput(hint, "AddOutput");
    AcceptEntityInput(hint, "FireUser1");

    // Format(buffer, sizeof(buffer), "witch_%d", witch);
    // DispatchKeyValue(witch, "targetname", buffer);
    // SetVariantString(buffer);
    // AcceptEntityInput(target, "SetParent");
    // SetVariantString(buffer);
    // AcceptEntityInput(hint, "SetParent");
}

Action SetTransmit(int entity, int client)
{
    if(!IsInfected(client))
        return Plugin_Handled;

    return Plugin_Continue;
}

Action StopControlSound(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH],
      int &entity, int &channel, float &volume, int &level, int &pitch, int &flags,
      char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
    if (IsValidClient(entity) && g_bWitchControl[entity])
        return Plugin_Handled;

    return Plugin_Continue;
}

/*
void CreateWitchMenu(int client)
{
    char name[64], id[8];
    Format(name, sizeof(name), "%T", "MenuTitle", client);
    Menu menu = new Menu(HandleWitchMenu);
    menu.SetTitle(name);
    float cpos[3], wpos[3], distance;
    GetClientAbsOrigin(client, cpos);

    int witch = MaxClients + 1;
    while ((witch = FindEntityByClassname(witch, "witch")) && IsValidEntity(witch))
    {
        GetEntPropVector(witch, Prop_Send, "m_vecOrigin", wpos);
        distance = GetVectorDistance(cpos, wpos);
        IntToString(witch, id, sizeof(id));
        Format(name, sizeof(name), "Witch(%T: %.1f)", "MenuHintDistance", client, distance);
        menu.AddItem(id, name);
    }
    menu.ExitButton = true;
    menu.Display(client, MENU_DISPLAY_INFINITE);
}

int HandleWitchMenu(Menu menu, MenuAction action, int client, int item)
{
    if (!IsInfected(client)) return 0;
    if (action != MenuAction_Select) return 0;

    int witch;
    char info[32];
    menu.GetItem(item, info, sizeof(info));
    witch = StringToInt(info);

    for (int i = 1; i <= MaxClients; i++)
        if (GetClientWitch(i) == witch && i != client)
        {
            PrintToChat(client, "%T", "WitchBeenTaken", client, i);
            CreateWitchMenu(client);
            return 0;
        }

    SetClientWitch(client, witch);
    ResetPlayerState(client);
    SetViewToWitch(client);
    ShowControlHint(client);
    g_bWitchControl[client] = true;

    return 1;
}
*/

public void OnClientDisconnect(int client)
{
    g_iWitch[client] = -1;
    g_fLiftHeight[client] = 0.0;
    g_bAngryResume[client] = g_bWitchAngry[client] = g_bWitchControl[client] = false;

    int camera = GetClientCamera(client);
    if (IsValidEntity(camera))
    {
        AcceptEntityInput(camera, "Kill");
        RemoveEntity(camera);
    }
    g_iCamera[client] = -1;
}

void ShowControlHint(int client)
{
    DataPack data;
    ClientCommand(client, "gameinstructor_enable 1");

    data = new DataPack();
    data.WriteCell(client);
    data.WriteString("WitchAttack");
    data.WriteString("+attack");
    data.WriteCell(false);
    CreateTimer(0.1, Timer_ShowHint, data, TIMER_FLAG_NO_MAPCHANGE);

    data = new DataPack();
    data.WriteCell(client);
    data.WriteString("WitchSkill");
    data.WriteString("+attack2");
    data.WriteCell(false);
    CreateTimer(4.0, Timer_ShowHint, data, TIMER_FLAG_NO_MAPCHANGE);

    data = new DataPack();
    data.WriteCell(client);
    data.WriteString("WitchDuck");
    data.WriteString("+duck");
    data.WriteCell(false);
    CreateTimer(8.0, Timer_ShowHint, data, TIMER_FLAG_NO_MAPCHANGE);

    data = new DataPack();
    data.WriteCell(client);
    data.WriteString("WitchLose");
    data.WriteString("+use");
    data.WriteCell(true);
    CreateTimer(12.0, Timer_ShowHint, data, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_ShowHint(Handle timer, DataPack data)
{
    data.Reset(false);
    int client = data.ReadCell();
    if (!IsValidClient(client))
        return Plugin_Stop;

    char msg[64], bind[64];
    data.ReadString(msg, sizeof(msg));
    data.ReadString(bind, sizeof(bind));
    bool final = data.ReadCell();
    Format(msg, sizeof(msg), "%T", msg, client);
    int hint = ShowInstructorHint(client, msg, sizeof(msg), bind);

    data.Reset();
    data.WriteCell(hint);
    data.WriteCell(client);
    data.WriteCell(final);
    CreateTimer(3.8, Timer_StopHint, data, TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Stop;
}

Action Timer_StopHint(Handle timer, DataPack data)
{
    data.Reset(false);
    int hint = data.ReadCell();
    int client = data.ReadCell();
    bool final = data.ReadCell();
    delete data;

    if (IsValidEntity(hint))
    {
        AcceptEntityInput(hint, "Kill");
        RemoveEntity(hint);
    }
    if (!IsValidClient(client) || !final) return Plugin_Stop;

    ClientCommand(client, "gameinstructor_enable 0");
    return Plugin_Stop;
}

public void OnActionCreated(BehaviorAction action, int actor, const char[] name)
{
    if (!strcmp(name, "WitchAngry"))
    {
        bool nobody = true;
        for (int client = 1; client <= MaxClients; client++)
            if (g_bWitchControl[client] && GetClientWitch(client) == actor)
            {
                // Witch 已被控制
                nobody = false;
                break;
            }
        if (nobody) return;

        action.OnUpdate = OnWitchAngryUpdate;
        action.OnEnd = OnWitchAngryEnd;
    }
}

Action OnWitchAngryUpdate(BehaviorAction action, int actor, float interval, ActionResult result)
{
    for (int client = 1; client <= MaxClients; client++)
        if (g_bWitchControl[client] && !g_bWitchAngry[client] &&
            GetClientWitch(client) == actor)
        {
            // 延续动作
            result.type = SUSPEND_FOR;
            g_bAngryResume[client] = true;
            SetEntProp(actor, Prop_Send, "m_mobRush", 0);
            SetEntPropFloat(actor, Prop_Send, "m_rage", 0.0);
            break;
        }

    return Plugin_Continue;
}

Action OnWitchAngryEnd(BehaviorAction action, int actor, float interval, ActionResult result)
{
    for (int client = 1; client <= MaxClients; client++)
        if (g_bWitchControl[client] && GetClientWitch(client) == actor)
        {
            g_bWitchAngry[client] = false;
            g_bAngryResume[client] = false;
            SetEntProp(actor, Prop_Send, "m_mobRush", 0);
            break;
        }

    return Plugin_Continue;
}

public void OnMapStart()
{
    if (!IsModelPrecached(CAMERA_MODEL))
        PrecacheModel(CAMERA_MODEL);
}

public Action OnPlayerRunCmd(int client, int &buttons,
    int &impulse, float velocity[3], float angles[3], int &weapon,
    int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
    if (!IsInfected(client) || IsFakeClient(client) || IsTank(client))
        return Plugin_Continue;

    if (!IsPlayerAlive(client))
    {
        g_iWitch[client] = -1;
        g_fLiftHeight[client] = 0.0;
        g_bAngryResume[client] = g_bWitchAngry[client] = g_bWitchControl[client] = false;
        DisableCamera(client);
        SetViewEntity(client, -1);

        return Plugin_Continue;
    }

    int oldbtns = GetEntProp(client, Prop_Data, "m_nOldButtons");
    // 接管Witch
    if((buttons & IN_USE) && !(oldbtns & IN_USE) && !g_bWitchControl[client])
    {
        int witch = GetClientAimTarget(client, false);
        if(!IsValidEntity(witch)) return Plugin_Continue;
        char name[16];
        GetEntityClassname(witch, name, sizeof(name));
        if(strcmp(name, "witch")) return Plugin_Continue;

        for (int i = 1; i <= MaxClients; i++)
            if (GetClientWitch(i) == witch && i != client)
            {
                PrintToChat(client, "%T", "WitchBeenTaken", client, i);
                return Plugin_Continue;
            }

        SetClientWitch(client, witch);
        ResetPlayerState(client);
        SetViewToWitch(client);
        ShowControlHint(client);
        g_bWitchControl[client] = true;

        return Plugin_Continue;
    }

    if(!g_bWitchControl[client]) return Plugin_Continue;

    int health, witch = GetClientWitch(client);
    if (IsValidEntity(witch)) health = GetEntProp(witch, Prop_Data, "m_iHealth");
    // 放弃接管
    if (((buttons & IN_USE) && !(oldbtns & IN_USE)) || !IsValidEntity(witch) || health <= 0)
    {
        if (IsValidEntity(witch))
        {
            int flags = GetEntProp(witch, Prop_Send, "m_fFlags");
            if ((flags & FL_DUCKING))
                SetEntProp(witch, Prop_Data, "m_nSequence", ANIM_SITTING);
            else SetEntProp(witch, Prop_Data, "m_nSequence", ANIM_STANDING_CRYING);
        }

        ScreenFade(client, 1, 1, { 0, 0, 0, 255 });
        g_iWitch[client] = -1;
        g_fLiftHeight[client] = 0.0;
        g_bAngryResume[client] = g_bWitchAngry[client] = g_bWitchControl[client] = false;
        float pos[3];
        GetClientAbsOrigin(client, pos);
        if (IsValidEntity(witch))
            GetEntPropVector(witch, Prop_Send, "m_vecOrigin", pos);
        TeleportEntity(client, { 0.0, 0.0, 0.0 }, NULL_VECTOR, NULL_VECTOR);
        ForcePlayerSuicide(client);
        SetViewEntity(client, -1);
        DisableCamera(client);

        if (IsValidEntity(witch)) pos[2] += 60;
        TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);

        return Plugin_Continue;
    } else SetEntProp(client, Prop_Data, "m_iHealth", health);

    int camera = GetClientCamera(client);
    int flags = GetEntProp(witch, Prop_Send, "m_fFlags");
    int sequence = GetEntProp(witch, Prop_Data, "m_nSequence");
    bool grounded = GetEntPropEnt(witch, Prop_Data, "m_hGroundEntity") != -1;

    // 攀爬时取消接管
    if (IsClimbingUpToLedge(witch))
    {
        UnlockCamera(client, camera, mouse);

        if (grounded) ResetStatus(witch);
        return Plugin_Continue;
    }

    // 攀爬
    if ((buttons & IN_ATTACK2) && !(oldbtns & IN_ATTACK2) && !(flags & FL_DUCKING))
    {
        buttons &= ~IN_ATTACK;
        float start[3], temp[3], target[3], rotate[3], fwd[3];

        GetEntPropVector(camera, Prop_Send, "m_vecOrigin", temp);
        GetEntPropVector(witch, Prop_Send, "m_vecOrigin", start);
        start[2] += temp[2];

        for(int i = 0; i < 3; i++)
            temp[i] = start[i];
        temp[2] += 160;
        Handle trace = TR_TraceRayFilterEx(start, temp, MASK_SOLID,
            RayType_EndPoint, EntityIgnore_TraceFilter);
        if (TR_DidHit(trace))
        {
            int surface = TR_GetSurfaceFlags(trace);
            delete trace;

            if (!(surface & SURF_SKY) && !(surface & SURF_SKY2D))
            {
                PrintHintText(client, "%T", "NarrowSpace", client);
                return Plugin_Continue;
            }
        }

        // 计算目标点
        trace = TR_TraceRayFilterEx(start, angles,
            MASK_SOLID, RayType_Infinite, EntityIgnore_TraceFilter);
        if (TR_DidHit(trace))
        {
            TR_GetEndPosition(target, trace);
            delete trace;

            // 计算距离
            float distance = SquareRoot(Pow(target[0] - start[0],
                 2.0) + Pow(target[1] - start[1], 2.0));
            if (distance > 120)
            {
                PrintHintText(client, "%T", "TargetTooFar", client);
                return Plugin_Continue;
            }

            // 计算高度
            if (!(10 < target[2] - start[2] < 120 * 10))
            {
                PrintHintText(client, "%T", "TargetTooHigh", client);
                return Plugin_Continue;
            }
            GetEntPropVector(witch, Prop_Send, "m_angRotation", rotate);
            GetAngleVectors(rotate, fwd, NULL_VECTOR, NULL_VECTOR);
            NormalizeVector(fwd, fwd);

            target[2] += 20;
            for(int i = 0; i < 3; i++)
            {
                start[i] = target[i] + fwd[i] * 40;
                temp[i] = target[i] - fwd[i] * 40;
            }
            target[2] += 10;
#if DEBUG
            ShowPos(2, start, temp, 100.0, 0.0, 30.0, 30.0);
#endif
            // 计算阻挡
            trace = TR_TraceRayFilterEx(start, temp,
                MASK_SOLID, RayType_EndPoint, EntityIgnore_TraceFilter);
            if (TR_DidHit(trace))
            {
                PrintHintText(client, "%T", "TargetBlocked", client);
                return Plugin_Continue;
            }
            delete trace;
            bool result = ClimbUpToLedge(witch, target, fwd);

            if (result)
            {
                PrintHintText(client, "%T", "ClimbSuccess", client);
                return Plugin_Continue;
            }
        }
    }

    if (g_fLiftHeight[client])
    {
        float pos[3];
        GetEntPropVector(camera, Prop_Send, "m_vecOrigin", pos);
        float delta = pos[2] - g_fLiftHeight[client];
        if (-0.1 < delta < 0.1)
        {
            pos[2] = g_fLiftHeight[client];
            g_fLiftHeight[client] = 0.0;
        }
        else pos[2] += delta > 0 ? -1 : 1;
        TeleportEntity(camera, pos, NULL_VECTOR, NULL_VECTOR);
    }

    if (g_bAngryResume[client])
    {
        UnlockCamera(client, camera, mouse);
        SetEntProp(witch, Prop_Data, "m_nSequence", ANIM_SETTING_ANGRY);

        return Plugin_Continue;
    }

    float pos[3], ang[3];
    if (g_bWitchAngry[client])
    {
        float rage = GetEntPropFloat(witch, Prop_Send, "m_rage");
        TeleportEntity(camera, NULL_VECTOR, angles, NULL_VECTOR);
        if (rage < 0.01 && !g_fLiftHeight[client])
        {
            GetEntPropVector(witch, Prop_Send, "m_vecOrigin", pos);
            g_fLiftHeight[client] = pos[2] - 24;
            SetEntPropFloat(witch, Prop_Send, "m_rage", 0.0);
            GetEntPropVector(witch, Prop_Send, "m_angRotation", ang);
            TeleportEntity(client, NULL_VECTOR, ang, NULL_VECTOR);
        }
        return Plugin_Continue;
    }

    GetEntPropVector(witch, Prop_Send, "m_vecOrigin", pos);
    TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
    ang[0] = angles[0]; ang[1] = 0.0;
    TeleportEntity(camera, NULL_VECTOR, ang, NULL_VECTOR);
    ang[0] = 0.0; ang[1] = angles[1];
    TeleportEntity(witch, NULL_VECTOR, ang, NULL_VECTOR);

    if ((flags & FL_DUCKING))
        SetEntProp(witch, Prop_Data, "m_nSequence", ANIM_SITTING);
    else SetEntProp(witch, Prop_Data, "m_nSequence", ANIM_STANDING_CRYING);

    if ((buttons & IN_ATTACK) && !(oldbtns & IN_ATTACK))
    {
        buttons &= ~IN_ATTACK;
        WitchAngry(client);
    }

    if (!(flags & FL_DUCKING))
        WitchMove(client, buttons);

    if (grounded)
    {
        if ((buttons & IN_DUCK) && !(oldbtns & IN_DUCK) && !g_fLiftHeight[client])
        {
            GetEntPropVector(camera, Prop_Send, "m_vecOrigin", pos);
            if (sequence != ANIM_SITTING)
            {
                g_fLiftHeight[client] = pos[2] - 38;
                TeleportEntity(camera, NULL_VECTOR, {30.0, -25.0, 0.0}, NULL_VECTOR);
                SetEntProp(witch, Prop_Send, "m_fFlags", flags | FL_DUCKING);
                SetEntProp(witch, Prop_Data, "m_nSequence", ANIM_SITTING);
            }
            else
            {
                g_fLiftHeight[client] = pos[2] + 38;
                TeleportEntity(camera, NULL_VECTOR, {30.0, 0.0, 0.0}, NULL_VECTOR);
                SetEntProp(witch, Prop_Send, "m_fFlags", flags & ~FL_DUCKING);
                SetEntProp(witch, Prop_Data, "m_nSequence", ANIM_STANDING_CRYING);
            }
            buttons &= ~IN_DUCK;
        }

        if ((buttons & IN_JUMP) && !(oldbtns & IN_JUMP))
        {
            float vel[3];
            GetEntPropVector(witch, Prop_Data, "m_vecAbsOrigin", pos);
            pos[2] += 20;
            TeleportEntity(witch, pos, NULL_VECTOR, NULL_VECTOR);

            GetEntPropVector(witch, Prop_Data, "m_vecVelocity", vel);
            vel[2] += FindConVar("sv_gravity").FloatValue * 0.6;
            SetEntProp(witch, Prop_Data, "m_nSequence", ANIM_RUN_JUMP);
            SetWitchAcceleration(witch, vel);
        }
    }
    else
    {
        float vel[3];
        GetEntPropVector(witch, Prop_Data, "m_vecVelocity", vel);
        vel[2] -= FindConVar("sv_gravity").FloatValue / 48;
        SetWitchAcceleration(witch, vel);
        SetEntProp(witch, Prop_Data, "m_nSequence", ANIM_FALL);
    }

    return Plugin_Changed;
}

void SetViewToWitch(int client)
{
    EnableCamera(client);
    int witch = GetClientWitch(client);
    int camera = GetClientCamera(client);
    if (!IsValidEntity(camera)) return;

    float origin[3], rotate[3], lookat[3];
    GetEntPropVector(witch, Prop_Send, "m_vecOrigin", origin);
    GetEntPropVector(witch, Prop_Send, "m_angRotation", rotate);
    GetAngleVectors(rotate, lookat, NULL_VECTOR, NULL_VECTOR);
    NormalizeVector(lookat, lookat);
    // ScaleVector(lookat, -10.0);
    // AddVectors(lookat, origin, origin);
    // origin[2] += 75;
    // if (GetEntityFlags(witch) & FL_DUCKING)
    //     origin[2] -= 38;
    // rotate[0] = 30.0;
    ScaleVector(lookat, 16.0);
    AddVectors(lookat, origin, origin);
    origin[2] += 56;
    if (GetEntityFlags(witch) & FL_DUCKING)
        origin[2] -= 38;

    DispatchKeyValueVector(camera, "origin", origin);
    DispatchKeyValueVector(camera, "angles", rotate);

    char name[64];
    Format(name, sizeof(name), "witch_%d", witch);
    DispatchKeyValue(witch, "targetname", name);
    SetVariantString(name);
    AcceptEntityInput(camera, "SetParent");
    SetViewEntity(client, camera);
}

void UnlockCamera(int client, int camera, const int mouse[2])
{
    float ang[3];
    GetEntPropVector(camera, Prop_Send, "m_angRotation", ang);
    if (FloatAbs(ang[0]) < 89.0 || ang[0] * mouse[1] < 0)
        ang[0] += mouse[1] * 0.04;//上负下正
    else ang[0] = 89.0 * (ang[0] < 0 ? -1 : 1);
    ang[1] -= mouse[0] * 0.04;//左负右正
    TeleportEntity(camera, NULL_VECTOR, ang, NULL_VECTOR);
    // ang[1] = (180 - FloatAbs(ang[1])) * ang[1] > 0 ? -1.0 : 1.0;
    TeleportEntity(client, NULL_VECTOR, ang, NULL_VECTOR);
}

bool EntityIgnore_TraceFilter(int entity, int mask, int self)
{
    if (entity == self || IsValidEntity(entity))
        return false;

    return true;
}

void WitchMove(int client, int buttons)
{
    float vel[3] = { 0.0, ... }, rotate[3];
    if (buttons & IN_FORWARD)
        vel[0] += 1;
    if (buttons & IN_BACK)
        vel[0] += -1;
    if (buttons & IN_MOVERIGHT)
        vel[1] += 1;
    if (buttons & IN_MOVELEFT)
        vel[1] += -1;

    if (!vel[0] && !vel[1]) return;

    int witch = GetClientWitch(client);
    GetEntPropVector(witch, Prop_Send, "m_angRotation", rotate);
    float fwd[3], right[3], up[3], result[3];
    GetAngleVectors(rotate, fwd, right, up);

    ScaleVector(fwd, vel[0]);
    ScaleVector(right, vel[1]);
    ScaleVector(up, vel[2]);

    AddVectors(fwd, result, result);
    AddVectors(right, result, result);
    AddVectors(up, result, result);

    NormalizeVector(result, result);
    ScaleVector(result, g_hWitchWalkSpeed.FloatValue);

    SetEntProp(witch, Prop_Data, "m_nSequence", ANIM_CATCHING_TARGET);
    SetWitchAcceleration(witch, result);
}

void ResetPlayerState(int client)
{
    SetEntProp(client, Prop_Send, "m_isGhost", 0);
    SetEntProp(client, Prop_Send, "m_lifeState", 0);
    SetEntProp(client, Prop_Data, "m_iMaxHealth",
        GetEntProp(GetClientWitch(client), Prop_Data, "m_iMaxHealth"));
    SetEntProp(client, Prop_Send, "m_fFlags", GetEntityFlags(client) | FL_GODMODE);
    SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
    SetZombieClass(client, 9);
    SetEntityRenderMode(client, RENDER_TRANSCOLOR);
    SetEntityRenderColor(client, 0, 0, 0, 0);
    SetEntProp(client, Prop_Send, "m_iGlowType", 3);
    SetEntProp(client, Prop_Send, "m_glowColorOverride", 1);
    SetEntProp(client, Prop_Send, "m_fEffects", 0);
    int ability = MakeCompatEntRef(GetEntProp(client, Prop_Send, "m_customAbility"));
    if (IsValidEntity(ability))AcceptEntityInput(ability, "Kill");
    int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
    if (IsValidEntity(weapon)) RemovePlayerItem(client, weapon);
}

int CreateCamera(int target)
{
    int camera = GetClientCamera(target);
    if (!IsValidEntity(camera))
        camera = CreateEntityByName("point_viewcontrol");
    if (!IsValidEntity(camera)) return -1;

    DispatchKeyValue(camera, "model", CAMERA_MODEL);
    DispatchSpawn(camera);
    ActivateEntity(camera);

    return camera;
}

void EnableCamera(int client)
{
    if (!IsValidClient(client))
        return;

    int camera = CreateCamera(client);
    if (!IsValidEntity(camera))
        return;

    SetClientCamera(client, camera);
    AcceptEntityInput(camera, "Enable");
}

void DisableCamera(int client)
{
    if (!IsValidClient(client)) return;

    int camera = GetClientCamera(client);
    if (IsValidEntity(camera))
        AcceptEntityInput(camera, "Disable");
}

int GetClientWitch(int client)
{
    if (!IsValidClient(client))
        return -1;

    return EntRefToEntIndex(g_iWitch[client]);
}

int SetClientWitch(int client, int entity)
{
    if (!IsValidClient(client))
        return false;

    g_iWitch[client] = IsValidEntity(entity) ? EntIndexToEntRef(entity) : -1;
    return true;
}

int GetClientCamera(int client)
{
    if (!IsValidClient(client))
        return -1;

    return EntRefToEntIndex(g_iCamera[client]);
}

bool SetClientCamera(int client, int entity)
{
    if (!IsValidClient(client))
        return false;

    g_iCamera[client] = IsValidEntity(entity) ? EntIndexToEntRef(entity) : -1;
    return true;
}

void SetViewEntity(int client, int view)
{
    SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1, 1);
    SetEntPropEnt(client, Prop_Send, "m_hViewEntity", view);
    SetClientViewEntity(client, IsValidEdict(view) ? view : client);
}

void WitchAngry(int client)
{
    g_bWitchAngry[client] = true;
    int witch = GetClientWitch(client);
    int camera = GetClientCamera(client);
    float pos[3];
    GetEntPropVector(camera, Prop_Send, "m_vecOrigin", pos);
    g_fLiftHeight[client] = pos[2] + 24;

    SetEntPropFloat(witch, Prop_Send, "m_rage", 1.0);
    SetEntProp(witch, Prop_Send, "m_mobRush", 1);
}

// // ILocomotion::IsUsingLadder(void)
// bool IsUsingLadder(int entity)
// {
//     Address locomotion = GetLocomotion(entity);
//     if (locomotion == Address_Null) return false;

//     return SDKCall(g_hIsUsingLadder, locomotion);
// }

// ILocomotion::IsClimbingUpToLedge(void)
bool IsClimbingUpToLedge(int entity)
{
    Address locomotion = GetLocomotion(entity);
    if (locomotion == Address_Null) return false;

    return SDKCall(g_hIsClimbingUpToLedge, locomotion);
}

// ILocomotion::Reset
bool ResetStatus(int entity)
{
    Address locomotion = GetLocomotion(entity);
    if (locomotion == Address_Null) return false;

    return SDKCall(g_hResetStatus, locomotion);
}


// ILocomotion::ClimbUpToLedge(Vector const&,Vector const&,CBaseEntity const*)
bool ClimbUpToLedge(int entity, const float target[3], const float fwd[3], int obstacle = 0)
{
    Address locomotion = GetLocomotion(entity);
    if (locomotion == Address_Null) return false;

    if (!obstacle) obstacle = entity;
    return SDKCall(g_hClimbUpToLedge, locomotion, target, fwd, obstacle);
}

// ILocomotion::SetAcceleration(Vector const&)
void SetWitchAcceleration(int entity, const float acceleration[3])
{
    Address locomotion = GetLocomotion(entity);
    if (locomotion == Address_Null) return;

    float vector[3];
    AddVectors(NULL_VECTOR, acceleration, vector);
    ScaleVector(vector, 100.0);
    SDKCall(g_hSetAcceleration, locomotion, vector);
}

// ======== From [L4D2] Witch Control
// https://forums.alliedmods.net/showthread.php?t=125591
void ScreenFade(int client, int duration, int time, const int color[4])
{
    Handle screen = StartMessageOne("Fade", client);

    if (screen != null)
    {
        BfWriteShort(screen, duration * 400);
        BfWriteShort(screen, time * 400);
        BfWriteShort(screen, 0x0001);
        BfWriteByte(screen, color[0]);    //R
        BfWriteByte(screen, color[1]);    //G
        BfWriteByte(screen, color[2]);    //B
        BfWriteByte(screen, color[3]);    //A
        EndMessage();
    }
}

int ShowInstructorHint(int entity, const char[] message, int lenth, const char[] bind)
{
    char[] hintMsg = new char[lenth];
    strcopy(hintMsg, lenth, message);
    ReplaceString(hintMsg, lenth, "\n", " ");

    char hintName[16];
    int hint = CreateEntityByName("env_instructor_hint");
    if (!IsValidEntity(hint)) return -1;

    Format(hintName, sizeof(hintName), "hint_%d", entity);
    if (IsValidEntity(entity))
    {
        DispatchKeyValue(entity, "targetname", hintName);
        DispatchKeyValue(hint, "hint_target", hintName);
    }

    DispatchKeyValue(hint, "hint_timeout", "3.6");
    DispatchKeyValue(hint, "hint_range", "0.01");
    DispatchKeyValue(hint, "hint_color", "255 255 255");
    DispatchKeyValue(hint, "hint_icon_onscreen", "use_binding");
    DispatchKeyValue(hint, "hint_caption", hintMsg);
    DispatchKeyValue(hint, "hint_binding", bind);

    DispatchSpawn(hint);
    AcceptEntityInput(hint, "ShowHint");

    return hint;
}

// CTerrorPlayer::SetClass(ZombieClassType)
void SetZombieClass(int client, int classtype)
{
    if (!IsValidClient(client)) return;

    SDKCall(g_hSetZombieClass, client, classtype);
}

// ======== ALL below are from BHaType
// https://forums.alliedmods.net/showthread.php?p=2771240
Address GetLocomotion(int entity)
{
    Address nextbot = SDKCall(g_hGetNextBot, entity);
    if (!nextbot) return Address_Null;

    return SDKCall(g_hGetLocomotion, nextbot);
}

// Address GetNextBotPointer(int entity)
// {
//     return SDKCall(g_hGetNextBot, entity);
// }

// Address GetLocomotionPointer(Address nextbot)
// {
//     return SDKCall(g_hGetLocomotion, nextbot);
// }
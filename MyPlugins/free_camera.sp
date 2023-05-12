/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-03-18 22:22:37
 * @Last Modified time: 2023-04-29 12:17:15
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sdkhooks>
#include <l4d2tools>
#include <sourcemod>
#include <keyvalues>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <fnemotes>

#define VERSION "2023.04.29"
#define MAXSIZE 33

#define CAMERA_MODEL "models/editor/camera.mdl"
#define CAMERA_AUTO_COOKIE_NAME "CameraAutoCookies"
#define CAMERA_HINT_COOKIE_NAME "CameraHintCookies"
#define CAMERA_SPEED_COOKIE_NAME "CameraSpeedCookies"

int
    g_iFreeCamera[MAXSIZE] = {-1, ...};

float
    g_fCameraSpeed[MAXSIZE] = {0.0, ...};

bool
    g_bDanceAvailable = false,
    g_bMenuHint[MAXSIZE] = {true, ...},
    g_bIsDancing[MAXSIZE] = {false, ...},
    g_bWaitSpeed[MAXSIZE] = {false, ...},
    g_bAutoCamera[MAXSIZE] = {true, ...},
    g_bIsCameraActive[MAXSIZE] = {false, ...};

Cookie
    g_hCameraCookies[3];

ConVar
    g_hFreeCamera,
    g_hFreeCamSpeed;
    // g_hFreeCamSwitch;

GlobalForward
    g_hOnPlayerCameraActived,
    g_hOnPlayerCameraActivedPost,
    g_hOnPlayerCameraDeactived,
    g_hOnPlayerCameraDeactivedPost;

enum
{
    CAMERA_AUTO_ITEM = 0,
    CAMERA_HINT_ITEM,
    CAMERA_SPEED_ITEM
}

public Plugin myinfo =
{
    name = "Free Camera",
    author = "我是派蒙啊",
    description = "自由摄像机",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins/MyPlugins"
};

public void OnPluginStart()
{
    // Cookies
    InitCookies();
    // Console cmds
    RegCmds();
    // Convars
    CreateConVars();
    // Events
    HookEvents();
    // Commands
    HookCommands();
    // Global forwards
    CreateForwards();
    // Translations
    LoadTranslations("freecamera.phrases");
    // Execute cfg
    AutoExecConfig(true, "free_camera");
}

void InitCookies()
{
    // Reg cookies
    g_hCameraCookies[CAMERA_AUTO_ITEM] = new Cookie(CAMERA_AUTO_COOKIE_NAME, "Camera Settings", CookieAccess_Public);
    g_hCameraCookies[CAMERA_HINT_ITEM] = new Cookie(CAMERA_HINT_COOKIE_NAME, "Camera Settings", CookieAccess_Public);
    g_hCameraCookies[CAMERA_SPEED_ITEM] = new Cookie(CAMERA_SPEED_COOKIE_NAME, "Camera Settings", CookieAccess_Public);
    // Set menu handler
    SetCookieMenuItem(Camera_CookieMenuHandler, CAMERA_AUTO_ITEM, "TITLE_ERROR");
    SetCookieMenuItem(Camera_CookieMenuHandler, CAMERA_HINT_ITEM, "TITLE_ERROR");
    SetCookieMenuItem(Camera_CookieMenuHandler, CAMERA_SPEED_ITEM, "TITLE_ERROR");
}

void RegCmds()
{
    // Create free camera
    RegConsoleCmd("sm_fc", Cmd_FreeCamera, "Free Camera");
    RegConsoleCmd("sm_freecam", Cmd_FreeCamera, "Free Camera");
    // Kill free camera
    RegConsoleCmd("sm_kfc", Cmd_KillFreeCamera, "Kill Free Camera");
    RegConsoleCmd("sm_killfreecam", Cmd_KillFreeCamera, "Kill Free Camera");
    // Open free camera menu
    RegConsoleCmd("sm_fcm", Cmd_FreeCameraMenu, "Free Camera Menu");
    RegConsoleCmd("sm_freecammenu", Cmd_FreeCameraMenu, "Free Camera Menu");
}

void CreateConVars()
{
    // Free camera speed
    g_hFreeCamSpeed = CreateConVar("fc_speed", "60", "自由相机移速");
    // Turn on/off free camera, 1 for on, 0 for off
    g_hFreeCamera = CreateConVar("fc_allow", "1", "开启自由相机, 1=开启 0=关闭");
    // Useless
    // // Turn on/off free camera cmd, 1 for on, 0 for off
    // g_hFreeCamSwitch = CreateConVar("fc_cmd_switch", "0", "自由相机指令, 1=开启 0=关闭");
}

void HookCommands()
{
    // Hooked for player input speed
    AddCommandListener(Say_Callback, "say");
    AddCommandListener(Say_Callback, "say_team");
}

void HookEvents()
{
    // HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
    HookEvent("player_death", Event_PlayerDead, EventHookMode_Pre);
}

void CreateForwards()
{
    g_hOnPlayerCameraActived = new GlobalForward("FC_OnPlayerCameraActived", ET_Event, Param_CellByRef);
    g_hOnPlayerCameraActivedPost = new GlobalForward("FC_OnPlayerCameraActived_Post", ET_Ignore, Param_Cell);
    g_hOnPlayerCameraDeactived = new GlobalForward("FC_OnPlayerCameraDeactived", ET_Event, Param_CellByRef);
    g_hOnPlayerCameraDeactivedPost = new GlobalForward("FC_OnPlayerCameraDeactived_Post", ET_Ignore, Param_Cell);
}

// void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
// {
//     int client = GetClientOfUserId(event.GetInt("userid"));
//     if(!IsSurvivor(client)) return;

//     // Fix survivor view
//     // EnableFreeCamera(client);
//     // DisableFreeCamera(client);
// }

void Event_PlayerDead(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(!IsSurvivor(client)) return;
    int camera = GetClientCamera(client);
    if(!IsValidEntity(camera)) return;

    // Fix survivor view
    g_iFreeCamera[client] = -1;
    g_bIsCameraActive[client] = false;
    AcceptEntityInput(camera, "Disable");
    AcceptEntityInput(camera, "Kill");
    RemoveEntity(camera);

    SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1, 1);
    SetViewEntity(client, -1);
}

public void OnClientPutInServer(int client)
{
    if (!IsValidClient(client) || !AreClientCookiesCached(client))
        return;

    SDKHook(client, SDKHook_TraceAttack, TraceAttack);
    GetClientCameraCookies(client);
}

public void OnClientDisconnect(int client)
{
    int camera = GetClientCamera(client);
    // If player has a camera, kill it.
    if (IsValidEntity(camera))
    {
        g_iFreeCamera[client] = -1;
        g_bIsCameraActive[client] = false;
        AcceptEntityInput(camera, "Disable");
        AcceptEntityInput(camera, "Kill");
        RemoveEntity(camera);
    }
    SDKUnhook(client, SDKHook_TraceAttack, TraceAttack);
}

public void OnClientCookiesCached(int client)
{
    if (!IsValidClient(client) || !AreClientCookiesCached(client))
        return;

    GetClientCameraCookies(client);
}

public void OnAllPluginsLoaded()
{
    g_bDanceAvailable = LibraryExists("fnemotes");

    for (int i = 1; i <= MaxClients; i++)
        if (IsValidClient(i) && AreClientCookiesCached(i))
            GetClientCameraCookies(i);

    for (int i = 1; i <= MaxClients; i++)
        if (IsValidClient(i))
            SDKHook(i, SDKHook_TraceAttack, TraceAttack);
}

public void OnLibraryAdded(const char[] name)
{
    if (!strcmp(name, "fnemotes", false))
        g_bDanceAvailable = true;
}

public void OnLibraryRemoved(const char[] name)
{
    if (!strcmp(name, "fnemotes", false))
        g_bDanceAvailable = false;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("freecamera");
    CreateNative("FC_GetClientCamera", Native_GetClientCamera);
    CreateNative("FC_IsClientCameraActive", Native_IsClientCameraActive);
    CreateNative("FC_IsClientCameraAvailable", Native_IsClientCameraAvailable);
    // CreateNative("FC_SetClientCamera", Native_SetClientCamera);
    return APLRes_Success;
}

public void OnMapStart()
{
    if (!IsModelPrecached(CAMERA_MODEL))
        PrecacheModel(CAMERA_MODEL);
}

public void OnMapEnd()
{
    for (int i = 1; i <= MaxClients; i++)
        DisableFreeCamera(i, true);
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse,
    float vel[3], float angles[3], int& weapon, int& subtype,
    int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    int camera = GetClientCamera(client);
    if (IsValidEntity(camera) && IsClientCameraActive(client))
    {
        // When dance finish, disable camera
        if (g_bDanceAvailable && !fnemotes_IsClientEmoting(client) && g_bIsDancing[client])
        {
            g_bIsDancing[client] = false;
            DisableFreeCamera(client);
            return Plugin_Continue;
        }
        // Move camera
        MoveCamera(client, camera, buttons);
        TeleportEntity(camera, NULL_VECTOR, angles, NULL_VECTOR);

        // May be player needs to exit
        static int btnAllowed = IN_BACK | IN_FORWARD | IN_MOVELEFT | IN_MOVERIGHT | IN_WALK | IN_SPEED | IN_SCORE;
        if (buttons & ~btnAllowed) DisableFreeCamera(client);
        vel[0] = vel[1] = vel[2] = 0.0;
    }

    return Plugin_Continue;
}

public void fnemotes_OnEmote_Pre(int client)
{
    if (IsSurvivor(client) && g_hFreeCamera.BoolValue)
        if (g_bAutoCamera[client])
        {
            EnableFreeCamera(client);
            g_bIsDancing[client] = true;
            if (g_bMenuHint[client])
                PrintToChat(client, "[FC] 聊天框输入 /fcm 设置相机属性");
        }
}

Action TraceAttack(int victim)
{
    // Prevent god mode
    if(IsSurvivor(victim))
        DisableFreeCamera(victim);

    return Plugin_Continue;
}

void GetClientCameraCookies(int client)
{
    g_bMenuHint[client] = view_as<bool>(g_hCameraCookies[CAMERA_HINT_ITEM].GetInt(client, 1));
    g_bAutoCamera[client] = view_as<bool>(g_hCameraCookies[CAMERA_AUTO_ITEM].GetInt(client, 1));
    g_fCameraSpeed[client] = g_hCameraCookies[CAMERA_SPEED_ITEM].GetFloat(client, g_hFreeCamSpeed.FloatValue);
}

void MoveCamera(int client, int camera, int buttons)
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

    GetEntPropVector(camera, Prop_Send, "m_angRotation", rotate);
    float fwd[3], right[3], up[3], result[3] = { 0.0, ... };
    GetAngleVectors(rotate, fwd, right, up);

    ScaleVector(fwd, vel[0]);
    ScaleVector(right, vel[1]);
    ScaleVector(up, vel[2]);

    AddVectors(fwd, result, result);
    AddVectors(right, result, result);
    AddVectors(up, result, result);

    NormalizeVector(result, result);
    ScaleVector(result, g_fCameraSpeed[client] * ((buttons & IN_SPEED) ? 2 : 1));

    TeleportEntity(camera, NULL_VECTOR, NULL_VECTOR, result);
}

Action Cmd_FreeCamera(int client, any args)
{
    if (g_hFreeCamera.BoolValue/* && g_hFreeCamSwitch.BoolValue*/)
        EnableFreeCamera(client);
    return Plugin_Handled;
}

Action Cmd_KillFreeCamera(int client, any args)
{
    if (g_hFreeCamera.BoolValue/* && g_hFreeCamSwitch.BoolValue*/)
    {
        g_bIsDancing[client] = false;
        DisableFreeCamera(client);
    }
    return Plugin_Handled;
}

Action Cmd_FreeCameraMenu(int client, any args)
{
    if (IsValidClient(client))
        if(!AreClientCookiesCached(client))
            PrintToChat(client, "%T", "MENU_PREPARE", client);
        else ShowCookieMenu(client);
    return Plugin_Handled;
}

void Camera_CookieMenuHandler(int client, CookieMenuAction action, any info, char[] title, int maxlen)
{
    switch(view_as<int>(info))
    {
        case CAMERA_AUTO_ITEM:
        {
            Format(title, maxlen, "%T: %T", "AUTO_TITLE", client,
                g_bAutoCamera[client] ? "ITEM_ON" : "ITEM_OFF", client);
            if (action == CookieMenuAction_SelectOption)
            {
                g_bAutoCamera[client] = !g_bAutoCamera[client];
                g_hCameraCookies[info].SetInt(client, g_bAutoCamera[client]);
                PrintToChat(client, "%T: %T", "AUTO_HINT", client,
                    g_bAutoCamera[client] ? "ITEM_ON" : "ITEM_OFF", client);
            }
        }
        case CAMERA_HINT_ITEM:
        {
            Format(title, maxlen, "%T: %T", "HINT_TITLE", client,
                g_bMenuHint[client] ? "ITEM_ON" : "ITEM_OFF", client);
            if (action == CookieMenuAction_SelectOption)
            {
                g_bMenuHint[client] = !g_bMenuHint[client];
                g_hCameraCookies[info].SetInt(client, g_bMenuHint[client]);
                PrintToChat(client, "%T: %T", "HINT_HINT", client,
                    g_bMenuHint[client] ? "ITEM_ON" : "ITEM_OFF", client);
            }
        }
        case CAMERA_SPEED_ITEM:
        {
            Format(title, maxlen, "%T: %.f", "SPEED_TITLE", client, g_fCameraSpeed[client]);
            if (action == CookieMenuAction_SelectOption)
            {
                g_bWaitSpeed[client] = true;
                PrintToChat(client, "%T", "SPEED_HINT", client);
            }
        }
        default:
            Format(title, maxlen, "%T", "ERROR_TITLE", client);
    }
}

Action Say_Callback(int client, const char[] command, int argc)
{
    // No need to block, continue
    if (!g_bWaitSpeed[client] || !IsValidClient(client))
        return Plugin_Continue;

    char buffer[4];
    GetCmdArg(1, buffer, sizeof(buffer));
    int speed = StringToInt(buffer);
    // NaN or 0 is invaild, let player input again
    if (speed < 1)
    {
        PrintToChat(client, "%T", "SPEED_INVALID", client);
        return Plugin_Handled;
    }

    g_bWaitSpeed[client] = false;
    g_fCameraSpeed[client] = speed * 1.0;
    g_hCameraCookies[CAMERA_SPEED_ITEM].SetFloat(client, g_fCameraSpeed[client]);
    PrintToChat(client, "%T: %d", "SPEED_SET_FINISH", client, speed);

    return Plugin_Handled;
}

void EnableFreeCamera(int client)
{
    if (!IsSurvivor(client) || !IsPlayerAlive(client))
        return;

    // Call forward
    Action result = Plugin_Continue;
    Call_StartForward(g_hOnPlayerCameraActived);
    Call_PushCellRef(client);
    Call_Finish(result);
    // Return if forward returns stop
    if (result == Plugin_Handled || result == Plugin_Stop) return;

    // int camera = GetClientCamera(client);
    // if (IsValidEntity(camera))
    //     return;

    // Try get a 'camera'
    int camera = CreateFreeCamera(client);
    if (!IsValidEntity(camera))
        return;

    // Now we got our camera, let player view it.
    SetClientCamera(client, camera);
    g_bIsCameraActive[client] = true;
    AcceptEntityInput(camera, "Enable", client);
    // SetClientViewEntity(client, camera);

    // Call forward
    Call_StartForward(g_hOnPlayerCameraActivedPost);
    Call_PushCell(client);
    Call_Finish();
}

void DisableFreeCamera(int client, bool force = false)
{
    if (!IsSurvivor(client))
        return;

    if(!force)
    {
        // Call forward
        Action result = Plugin_Continue;
        Call_StartForward(g_hOnPlayerCameraDeactived);
        Call_PushCellRef(client);
        Call_Finish(result);
        // Return if forward returns stop, except map end(Force kill camera to prevent bug occur when changing map)
        if (result == Plugin_Handled || result == Plugin_Stop) return;
    }

    int camera = GetClientCamera(client);
    // If player has a camera, disable it.
    if (IsValidEntity(camera))
    {
        // AcceptEntityInput(camera, "Kill");
        // RemoveEntity(camera);
        g_bIsCameraActive[client] = false;
        AcceptEntityInput(camera, "Disable", client);
    }
    // Let player view herself.
    // if (IsValidClient(client))
    //     SetClientViewEntity(client, client);
    // SetClientCamera(client, -1);

    // Call forward
    Call_StartForward(g_hOnPlayerCameraDeactivedPost);
    Call_PushCell(client);
    Call_Finish();
}

int CreateFreeCamera(int target)
{
    int camera;
    float origin[3], rotate[3], lookat[3];

    GetClientAbsOrigin(target, origin);
    GetClientAbsAngles(target, rotate);
    // GetEntPropVector(target, Prop_Send, "m_vecOrigin", origin);
    // GetEntPropVector(target, Prop_Send, "m_angRotation", rotate);

    // Only some ents like gift or rock or some projectiles can get velocity...(dont know why)
    // spitter_projectile : Not a choice because it may be hooked by other plugins...
    // tank_rock: Not a choice because it may be hooked by other plugins...
    // holiday_gift: Not a choice because it will auto destroy.
    // grenade_launcher_projectile : You could see smoke above.
    // molotov_projectile: You could see a fire ball above.
    // pipe_bomb_projectile : You could see red flash light.
    // vomitjar_projectile: : Seems the best choice, no particle, no flash, no effect,
    //              no auto destroy, wont be hooked...Perfect!!!
    camera = GetClientCamera(target);
    if(!IsValidEntity(camera))
        camera = CreateEntityByName("point_viewcontrol");
    if (!IsValidEntity(camera)) return -1;

    GetAngleVectors(rotate, lookat, NULL_VECTOR, NULL_VECTOR);
    NormalizeVector(lookat, lookat);
    ScaleVector(lookat, -50.0);
    AddVectors(lookat, origin, origin);
    rotate[0] = 30.0;
    origin[2] += 100.0;

    // char camName[64];
    // Format(camName, sizeof(camName), "VirtualCamera_%N", target);
    // DispatchKeyValue(camera, "targetname", camName);

    DispatchKeyValue(camera, "model", CAMERA_MODEL);
    DispatchKeyValueVector(camera, "origin", origin);
    DispatchKeyValueVector(camera, "angles", rotate);
    DispatchSpawn(camera);
    ActivateEntity(camera);
    // Vomit has no partice, so we no longer need this...
    // // Record when camera has create
    // float camtime = GetGameTime();

    // AcceptEntityInput(camera, "DisableShadow");
    // SetEntPropEnt(camera, Prop_Data, "m_hOwnerEntity", target);
    // SetEntityRenderMode(camera, RENDER_TRANSCOLOR);
    // SetEntityMoveType(camera, MOVETYPE_NOCLIP);
    // SetEntityRenderColor(camera, 0, 0, 0, 0);
    // SetEntProp(camera, Prop_Send, "m_CollisionGroup", 0);
    // SetEntProp(camera, Prop_Send, "m_nSolidType", 0);

    // Vomit has no partice, so we no longer need this...
    // char name[64];
    // for (int i = 0; i <= MaxEntities; i++)
    // {
    //     if (!IsValidEntity(i)) continue;
    //     GetEntityClassname(i, name, sizeof(name));
    //     PrintToChatAll("%s", name);
    //     if (!strcmp(name, "info_particle_system", false))
    //     {
    //         // When particle create, kill it.(make sure player wont notice that she is a tank rock xD)
    //         float partime = GetEntPropFloat(i, Prop_Send, "m_flStartTime");
    //         // Make sure we find rock particle
    //         if (partime - camtime <= 2.0)
    //             AcceptEntityInput(i, "Kill");
    //     }
    // }

    // Fix position
    // float tpos[3], cpos[3];
    // GetClientAbsOrigin(target, tpos);
    // GetEntPropVector(camera, Prop_Send, "m_vecOrigin", cpos);
    // float dis = GetVectorDistance(tpos, cpos);
    // tpos[2] += 100;
    // if (dis > 500)
    //     TeleportEntity(camera, tpos, NULL_VECTOR, NULL_VECTOR);

    return camera;
}

int Native_GetClientCamera(Handle plugin, int numParams)
{
    return GetClientCamera(GetNativeCell(1));
}

// int Native_SetClientCamera(Handle plugin, int numParams)
// {
//     return view_as<int>(SetClientCamera(GetNativeCell(1), GetNativeCell(2)));
// }

int Native_IsClientCameraAvailable(Handle plugin, int numParams)
{
    return view_as<int>(IsValidEntity(GetClientCamera(GetNativeCell(1))));
}

int GetClientCamera(int client)
{
    if (!IsValidClient(client))
        return -1;

    return EntRefToEntIndex(g_iFreeCamera[client]);
}

int Native_IsClientCameraActive(Handle plugin, int numParams)
{
    return view_as<int>(IsClientCameraActive(GetNativeCell(1)));
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

    g_iFreeCamera[client] = IsValidEntity(entity) ? EntIndexToEntRef(entity) : -1;
    return true;
}

void SetViewEntity(int client, int view)
{
    SetEntPropEnt(client, Prop_Send, "m_hViewEntity", view);
    SetClientViewEntity(client, IsValidEdict(view) ? view : client);
}
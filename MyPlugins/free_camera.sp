/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-03-18 22:22:37
 * @Last Modified time: 2023-03-20 23:42:16
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <fnemotes>
#include <sdktools>
#include <l4d2tools>
#include <sourcemod>
#include <keyvalues>
#include <clientprefs>

#define VERSION "2023.03.20"
#define MAXSIZE 33
// #define HOST 0

#define CAMERA_MODEL "models/editor/camera.mdl"
#define CAMERA_COOKIE_NAME "FreeCameraSettingsCookies"

// int MaxEnities;
// #if HOST
// int g_iCameraInput[33] = {0, ...};
// #endif
int
    g_iFreeCamera[MAXSIZE] = {-1, ...};

float
    g_fCameraSpeed[MAXSIZE] = {0.0, ...};

bool
    g_bWaitSpeed[MAXSIZE] = {false, ...},
    g_bIsDancing[MAXSIZE] = {false, ...},
    g_bFreeCamera[MAXSIZE] = {false, ...},
    g_bAutoCamera[MAXSIZE] = {false, ...};

Cookie
    g_hCameraCookies;

ConVar
    g_hFreeCamera,
    g_hFreeCamSpeed;
    // g_hFreeCamSwitch;

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
//     // MaxEnities = GetMaxEntities();
// #if HOST
// // Seems only client side command, server couldnt catch them...
// // AddCommandListener is a better way to prevent input,
// //if you are the host player, I suggest you open HOST mode.
//     // Hook player movements.
//     AddCommandListener(Movement_CallBack, "+back");
//     AddCommandListener(Movement_CallBack, "-back");
//     AddCommandListener(Movement_CallBack, "+forward");
//     AddCommandListener(Movement_CallBack, "-forward");
//     AddCommandListener(Movement_CallBack, "+moveleft");
//     AddCommandListener(Movement_CallBack, "-moveleft");
//     AddCommandListener(Movement_CallBack, "+moveright");
//     AddCommandListener(Movement_CallBack, "-moveright");
//     // Hook actions witch may interrupt dancing.
//     // AddCommandListener(Movement_CallBack, "+left");
//     // AddCommandListener(Movement_CallBack, "+right");
//     // AddCommandListener(Movement_CallBack, "+use");
//     // AddCommandListener(Movement_CallBack, "+duck");
//     // AddCommandListener(Movement_CallBack, "+jump");
//     // AddCommandListener(Movement_CallBack, "+reload");
//     // AddCommandListener(Movement_CallBack, "+ATTACK");
//     // AddCommandListener(Movement_CallBack, "+ATTACK2");
//     // Hook shift key to allow 'camera' move faster.
//     AddCommandListener(Movement_CallBack, "+speed");
//     AddCommandListener(Movement_CallBack, "-speed");
// #endif

    g_hCameraCookies = new Cookie(CAMERA_COOKIE_NAME, "Camera Settings", CookieAccess_Public);

    // Create free camera
    RegConsoleCmd("sm_fc", Cmd_FreeCamera, "Free Camera");
    RegConsoleCmd("sm_freecam", Cmd_FreeCamera, "Free Camera");
    // Kill free camera
    RegConsoleCmd("sm_kfc", Cmd_KillFreeCamera, "Kill Free Camera");
    RegConsoleCmd("sm_killfreecam", Cmd_KillFreeCamera, "Kill Free Camera");
    // Open free camera menu
    RegConsoleCmd("sm_fcm", Cmd_FreeCameraMenu, "Free Camera Menu");
    RegConsoleCmd("sm_freecammenu", Cmd_FreeCameraMenu, "Free Camera Menu");

    // Free camera speed
    g_hFreeCamSpeed = CreateConVar("fc_speed", "60", "自由相机移速");
    // Turn on/off free camera, 1 for on, 0 for off
    g_hFreeCamera = CreateConVar("fc_allow", "1", "开启自由相机, 1=开启 0=关闭");
    // Useless
    // // Turn on/off free camera cmd, 1 for on, 0 for off
    // g_hFreeCamSwitch = CreateConVar("fc_cmd_switch", "0", "自由相机指令, 1=开启 0=关闭");

    // Hooked for player input speed
    AddCommandListener(Say_Callback, "say");
    AddCommandListener(Say_Callback, "say_team");

    AutoExecConfig(true, "free_camera");
}

public void OnMapStart()
{
    if (!IsModelPrecached(CAMERA_MODEL))
        PrecacheModel(CAMERA_MODEL);
}

public void OnMapEnd()
{
    for (int i = 1; i <= MaxClients; i++)
        KillFreeCamera(i);
}

public void OnAllPluginsLoaded()
{
    for(int client = 1; client <= MaxClients; client++)
    {
        if(!IsValidClient(client)) continue;
        // Try get client camera settings
        KeyValues KvCamera = GetCameraKeyValue(client);
        g_bAutoCamera[client] = view_as<bool>(KvCamera.GetNum("IsAuto", 1));
        g_fCameraSpeed[client] = KvCamera.GetFloat("MoveSpeed", g_hFreeCamSpeed.FloatValue);

        delete KvCamera;
    }
}

public void OnClientPostAdminCheck(int client)
{
    // Try get client camera settings
    KeyValues KvCamera = GetCameraKeyValue(client);
    g_bAutoCamera[client] = view_as<bool>(KvCamera.GetNum("IsAuto", 1));
    g_fCameraSpeed[client] = KvCamera.GetFloat("MoveSpeed", g_hFreeCamSpeed.FloatValue);

    delete KvCamera;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse,
    float vel[3], float angles[3], int& weapon, int& subtype,
    int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    int camera = g_iFreeCamera[client];
    if (g_bFreeCamera[client] && IsValidEntity(camera))
    {
        // When dance finish, kill camera
        if (!fnemotes_IsClientEmoting(client) && g_bIsDancing[client])
        {
            g_bIsDancing[client] = false;
            KillFreeCamera(client);
            return Plugin_Continue;
        }
        // Move camera
        MoveCamera(client, camera, buttons);
        TeleportEntity(camera, NULL_VECTOR, angles, NULL_VECTOR);
        // May be player needs to exit
        int btnscopy = buttons & ~IN_FORWARD &
            ~IN_BACK & ~IN_MOVELEFT & ~IN_MOVERIGHT & ~IN_SPEED;
        if (btnscopy) KillFreeCamera(client);
        vel[0] = vel[1] = vel[2] = 0.0;
    }

    return Plugin_Continue;
}

public void fnemotes_OnEmote(int client)
{
    if (IsSurvivor(client) && g_hFreeCamera.BoolValue)
    {
        g_bIsDancing[client] = true;
        if(g_bAutoCamera[client])
        {
            PrintToChat(client, "[FC] 聊天框输入/fcm设置自由相机属性");
            FreeCamera(client);
        }
    }
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

// #if HOST
// Action Movement_CallBack(int client, const char[] command, int argc)
// {
//     // PrintToChatAll("捕获到 %N 动作： %s", client, command);
//     // Sometimes player may be host, so 0 must be 1.
//     if (client == 0) client = 1;
//     if (!IsSurvivor(client))
//         return Plugin_Continue;

//     int camera = g_iFreeCamera[client];
//     if (!g_bFreeCamera[client] || !IsValidEntity(camera))
//         return Plugin_Continue;

//     // Record our virtual buttons.
//     // Forward
//     if (!strcmp(command, "+forward", false))
//         g_iCameraInput[client] |= IN_FORWARD;
//     if (!strcmp(command, "-forward", false))
//         g_iCameraInput[client] &= ~IN_FORWARD;
//     // BackWard
//     if (!strcmp(command, "+back", false))
//         g_iCameraInput[client] |= IN_BACK;
//     if (!strcmp(command, "-back", false))
//         g_iCameraInput[client] &= ~IN_BACK;
//     // MoveLeft
//     if (!strcmp(command, "+moveleft", false))
//         g_iCameraInput[client] |= IN_MOVELEFT;
//     if (!strcmp(command, "-moveleft", false))
//         g_iCameraInput[client] &= ~IN_MOVELEFT;
//     // MoveRight
//     if (!strcmp(command, "+moveright", false))
//         g_iCameraInput[client] |= IN_MOVERIGHT;
//     if (!strcmp(command, "-moveright", false))
//         g_iCameraInput[client] &= ~IN_MOVERIGHT;
//     // SpeedUp
//     if (!strcmp(command, "+speed", false))
//         g_iCameraInput[client] |= IN_SPEED;
//     if (!strcmp(command, "-speed", false))
//         g_iCameraInput[client] &= ~IN_SPEED;

//     // We need to prevent player's input, so handle it.
//     return Plugin_Handled;
// }
// #endif

Action Cmd_FreeCamera(int client, any args)
{
    if (g_hFreeCamera.BoolValue/* && g_hFreeCamSwitch.BoolValue*/)
        FreeCamera(client);
    return Plugin_Handled;
}

Action Cmd_KillFreeCamera(int client, any args)
{
    if (g_hFreeCamera.BoolValue/* && g_hFreeCamSwitch.BoolValue*/)
    {
        g_bIsDancing[client] = false;
        KillFreeCamera(client);
    }
    return Plugin_Handled;
}

Action Cmd_FreeCameraMenu(int client, any args)
{
    if(IsValidClient(client))
        Menu_FreeCameraSettings(client);
    return Plugin_Handled;
}

void Menu_FreeCameraSettings(int client)
{
    if(!IsValidClient(client)) return;
    KeyValues KvCamera = GetCameraKeyValue(client);

    char buffer[64];

    Menu menu = new Menu(Menu_ExecCameraSettings);
    menu.SetTitle("自由相机设置菜单");
    Format(buffer, sizeof(buffer), "跳舞自由视角: %s", g_bAutoCamera[client] ? "是" : "否");
    menu.AddItem("Auto detect", buffer);
    Format(buffer, sizeof(buffer), "自由视角移速: %.f", g_fCameraSpeed[client]);
    menu.AddItem("Move speed", buffer);

    menu.Pagination = MENU_NO_PAGINATION;
    menu.ExitButton = true;
    menu.Display(client, 20);

    delete KvCamera;
}

int Menu_ExecCameraSettings(Menu menu, MenuAction action, int client, int item)
{
    if (!IsSurvivor(client)) return 0;
    if (action != MenuAction_Select) return 0;

    // Get client camera settings
    KeyValues KvCamera = GetCameraKeyValue(client);

    if (item == 0)
    {
        g_bAutoCamera[client] = !view_as<bool>(KvCamera.GetNum("IsAuto", 1));
        KvCamera.SetNum("IsAuto", 1 - KvCamera.GetNum("IsAuto", 1));
        PrintToChat(client, "[FC] 跳舞时启动自由相机设置为: %s", g_bAutoCamera[client] ? "是" : "否");
        // KvCamera.SetFloat("MoveSpeed", KvCamera.GetFloat("MoveSpeed", g_hFreeCamSpeed.FloatValue));
    }
    if(item == 1)
    {
        g_bWaitSpeed[client] = true;
        PrintToChat(client, "[FC] 请在聊天框输入整数");
    }
    SaveCameraKeyValue(client, KvCamera);
    delete KvCamera;

    return 1;
}

Action Say_Callback(int client, const char[] command, int argc)
{
    // No need to block, continue
    if(!g_bWaitSpeed[client] || !IsValidClient(client))
        return Plugin_Continue;

    char buffer[4];
    GetCmdArg(1, buffer, sizeof(buffer));
    int speed = StringToInt(buffer);
    // NaN or 0 is invaild, let player input again
    if(speed < 1)
    {
        PrintToChat(client, "[FC] 速度应大于零，请重新输入");
        return Plugin_Handled;
    }

    g_bWaitSpeed[client] = false;
    g_fCameraSpeed[client] = speed * 1.0;
    KeyValues KvCamera = GetCameraKeyValue(client);
    // KvCamera.SetNum("IsAuto", 1 - KvCamera.GetNum("IsAuto", 1));
    KvCamera.SetFloat("MoveSpeed", g_fCameraSpeed[client]);
    SaveCameraKeyValue(client, KvCamera);
    PrintToChat(client, "[FC] 速度被设置为: %d", speed);
    delete KvCamera;

    return Plugin_Handled;
}

KeyValues GetCameraKeyValue(int client)
{
    char buffer[128];
    // Try get camera cookies
    g_hCameraCookies.Get(client, buffer, sizeof(buffer));

    KeyValues KvCamera = new KeyValues("FreeCamera");
    if(strlen(buffer) < 1)
    {
        // No data found, create new one;
        KvCamera.JumpToKey("Settings", true);
        KvCamera.SetNum("IsAuto", 1);
        KvCamera.SetFloat("MoveSpeed", g_hFreeCamSpeed.FloatValue);
        KvCamera.ExportToString(buffer, sizeof(buffer));
        g_hCameraCookies.Set(client, buffer);
    }
    else KvCamera.ImportFromString(buffer, "Try import camera settings");
    // KvCamera.Rewind();
    // KvCamera.JumpToKey("Settings", true);

    return KvCamera;
}

void SaveCameraKeyValue(int client, KeyValues KvCamera)
{
    if (!IsValidClient(client)) return;

    char buffer[64];
    KvCamera.ExportToString(buffer, sizeof(buffer));
    // Set camera cookies
    g_hCameraCookies.Set(client, buffer);
}

void FreeCamera(int client)
{
    if (!IsSurvivor(client))
        return;

    int camera = g_iFreeCamera[client];
    if (g_bFreeCamera[client] && IsValidEntity(camera))
        return;

    // Try get a 'camera'
    camera = CreateVirtualCamera(client);
    if (!IsValidEntity(camera))
        return;

    // Now we got our camera, let player view it.
    g_bFreeCamera[client] = true;
    g_iFreeCamera[client] = camera;
    SetClientViewEntity(client, camera);
}

void KillFreeCamera(int client)
{
    if (!IsSurvivor(client))
        return;

    int camera = g_iFreeCamera[client];
    // If she has a camera, kill it.
    if (IsValidEntity(camera))
    {
        AcceptEntityInput(camera, "Kill");
        RemoveEntity(camera);
    }
    // Let player view herself.
    if (IsValidClient(client) && IsClientInGame(client))
        SetClientViewEntity(client, client);
    g_bFreeCamera[client] = false;
    g_iFreeCamera[client] = -1;
}

int CreateVirtualCamera(int target)
{
    int camera;
    float origin[3], rotate[3], lookat[3];

    GetEntPropVector(target, Prop_Send, "m_vecOrigin", origin);
    GetEntPropVector(target, Prop_Send, "m_angRotation", rotate);

    // Only some ents like gift or rock or some projectiles can get velocity...(dont know why)
    // spitter_projectile : Not a choice because it may be hooked by other plugins...
    // tank_rock: Not a choice because it may be hooked by other plugins...
    // holiday_gift: Not a choice because it will auto destroy.
    // grenade_launcher_projectile : You could see smoke above.
    // molotov_projectile: You could see a fire ball above.
    // pipe_bomb_projectile : You could see red flash light.
    // vomitjar_projectile: : Seems a best choice, no particle, no flash, no effect,
    //              no auto destroy, wont be hooked...Perfect!!!
    camera = CreateEntityByName("vomitjar_projectile");
    if (!IsValidEntity(camera)) return -1;

    GetAngleVectors(rotate, lookat, NULL_VECTOR, NULL_VECTOR);
    NormalizeVector(lookat, lookat);
    ScaleVector(lookat, -50.0);
    AddVectors(lookat, origin, origin);
    rotate[0] = 30.0;
    origin[2] += 100.0;

    DispatchKeyValue(camera, "model", CAMERA_MODEL);
    DispatchKeyValueVector(camera, "origin", origin);
    DispatchKeyValueVector(camera, "angles", rotate);
    DispatchSpawn(camera);
    ActivateEntity(camera);
    // Vomit has no partice, so we no longer need this...
    // // Record when camera has create
    // float camtime = GetGameTime();

    AcceptEntityInput(camera, "DisableShadow");
    SetEntPropEnt(camera, Prop_Data, "m_hOwnerEntity", target);
    SetEntityRenderMode(camera, RENDER_TRANSCOLOR);
    SetEntityMoveType(camera, MOVETYPE_NOCLIP);
    SetEntityRenderColor(camera, 0, 0, 0, 0);
    SetEntProp(camera, Prop_Send, "m_CollisionGroup", 0);
    SetEntProp(camera, Prop_Send, "m_nSolidType", 0);

    // Vomit has no partice, so we no longer need this...
    // char name[64];
    // for (int i = 0; i <= MaxEnities; i++)
    // {
    //     if (!IsValidEntity(i)) continue;
    //     GetEntityClassname(i, name, sizeof(name));
    //     PrintToChatAll("%s", name);
    //     if (!strcmp(name, "info_particle_system", false))
    //     {
    //         // When particle create, kill it.(make sure player wont notice that she is a tank rock xD)
    //         float partime = GetEntPropFloat(i, Prop_Send, "m_flStartTime");
    //         // Make sure we
    //         if (partime - camtime <= 2.0)
    //             AcceptEntityInput(i, "Kill");
    //     }
    // }

    // Fix position
    float tpos[3], cpos[3];
    GetClientAbsOrigin(target, tpos);
    GetEntPropVector(camera, Prop_Send, "m_vecOrigin", cpos);
    float dis = GetVectorDistance(tpos, cpos);
    tpos[2] += 100;
    if (dis > 500)
        TeleportEntity(camera, tpos, NULL_VECTOR, NULL_VECTOR);

    return camera;
}
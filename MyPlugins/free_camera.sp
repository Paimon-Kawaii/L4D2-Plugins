/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-03-18 22:22:37
 * @Last Modified time: 2023-03-19 20:14:47
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <l4d2tools>
#include <sourcemod>

#define VERSION "2023.03.19"
#define DEBUG 0

#define CAMERA_MODEL "models/editor/camera.mdl"

int MaxEnities;

#if DEBUG
int g_iCameraInput[33] = {0, ...};
#endif
int g_iFreeCamera[33] = {-1, ...};


bool g_bFreeCamera[33] = {false, ...};

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
    MaxEnities = GetMaxEntities();

#if DEBUG
// Seems only client side command, server couldnt catch them...
// AddCommandListener is a better way to prevent input, if you are host player, I suggest you open DEBUG mode
    // Hook player movements.
    AddCommandListener(Movement_CallBack, "+back");
    AddCommandListener(Movement_CallBack, "-back");
    AddCommandListener(Movement_CallBack, "+forward");
    AddCommandListener(Movement_CallBack, "-forward");
    AddCommandListener(Movement_CallBack, "+moveleft");
    AddCommandListener(Movement_CallBack, "-moveleft");
    AddCommandListener(Movement_CallBack, "+moveright");
    AddCommandListener(Movement_CallBack, "-moveright");
    // Hook actions may interrupt dancing.
    AddCommandListener(Movement_CallBack, "+left");
    AddCommandListener(Movement_CallBack, "+right");
    AddCommandListener(Movement_CallBack, "+use");
    AddCommandListener(Movement_CallBack, "+duck");
    AddCommandListener(Movement_CallBack, "+jump");
    AddCommandListener(Movement_CallBack, "+reload");
    AddCommandListener(Movement_CallBack, "+ATTACK");
    AddCommandListener(Movement_CallBack, "+ATTACK2");
    // Hook shift key to allow 'camera' move faster.
    AddCommandListener(Movement_CallBack, "+speed");
    AddCommandListener(Movement_CallBack, "-speed");
#endif

    RegConsoleCmd("sm_fc", Cmd_FreeCamera, "Free Camera");
    RegConsoleCmd("sm_freecam", Cmd_FreeCamera, "Free Camera");
    RegConsoleCmd("sm_kfc", Cmd_KillFreeCamera, "Kill Free Camera");
    RegConsoleCmd("sm_killfreecam", Cmd_KillFreeCamera, "Kill Free Camera");
}

public void OnMapStart()
{
    if (!IsModelPrecached(CAMERA_MODEL))
        PrecacheModel(CAMERA_MODEL);
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse,
    float vel[3], float angles[3], int& weapon, int& subtype,
    int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    int camera = g_iFreeCamera[client];
    if(g_bFreeCamera[client] && IsValidEntity(camera))
    {
        MoveCamera(camera, buttons);
        TeleportEntity(camera, NULL_VECTOR, angles, NULL_VECTOR);
        int btnscopy = buttons & ~IN_FORWARD &
            ~IN_BACK & ~IN_MOVELEFT & ~IN_MOVERIGHT & ~IN_SPEED;
        if(btnscopy) FakeClientCommand(client, "sm_kfc");
        vel[0] = vel[1] = vel[2] = 0.0;
    }

    return Plugin_Continue;
}

void MoveCamera(int camera, int buttons)
{
#if DEBUG
    buttons = g_iCameraInput[client] ? g_iCameraInput[client] : buttons;
#endif
    float vel[3] = { 0.0, ... }, rotate[3];
    if(buttons & IN_FORWARD)
        vel[0] += 1;
    if(buttons & IN_BACK)
        vel[0] += -1;
    if(buttons & IN_MOVERIGHT)
        vel[1] += 1;
    if(buttons & IN_MOVELEFT)
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
    ScaleVector(result, 200 * ((buttons & IN_SPEED) ? 1.8 : 1.0));

    TeleportEntity(camera, NULL_VECTOR, NULL_VECTOR, result);
}

#if DEBUG
Action Movement_CallBack(int client, const char[] command, int argc)
{
    // PrintToChatAll("捕获到 %N 动作： %s", client, command);
    // Sometimes player may be host, so 0 must be 1.
    if(client == 0) client = 1;
    if(!IsSurvivor(client))
        return Plugin_Continue;

    int camera = g_iFreeCamera[client];
    if(!g_bFreeCamera[client] || !IsValidEntity(camera))
        return Plugin_Continue;

    // Record our virtual buttons.
    // Forward
    if(!strcmp(command, "+forward", false))
        g_iCameraInput[client] |= IN_FORWARD;
    if(!strcmp(command, "-forward", false))
        g_iCameraInput[client] &= ~IN_FORWARD;
    // BackWard
    if(!strcmp(command, "+back", false))
        g_iCameraInput[client] |= IN_BACK;
    if(!strcmp(command, "-back", false))
        g_iCameraInput[client] &= ~IN_BACK;
    // MoveLeft
    if(!strcmp(command, "+moveleft", false))
        g_iCameraInput[client] |= IN_MOVELEFT;
    if(!strcmp(command, "-moveleft", false))
        g_iCameraInput[client] &= ~IN_MOVELEFT;
    // MoveRight
    if(!strcmp(command, "+moveright", false))
        g_iCameraInput[client] |= IN_MOVERIGHT;
    if(!strcmp(command, "-moveright", false))
        g_iCameraInput[client] &= ~IN_MOVERIGHT;
    // SpeedUp
    if(!strcmp(command, "+speed", false))
        g_iCameraInput[client] |= IN_SPEED;
    if(!strcmp(command, "-speed", false))
        g_iCameraInput[client] &= ~IN_SPEED;

    // We need to prevent player's input, so handle it.
    return Plugin_Handled;
}
#endif

Action Cmd_FreeCamera(int client, any args)
{
    if(!IsSurvivor(client))
        return Plugin_Handled;

    int camera = g_iFreeCamera[client];
    if(g_bFreeCamera[client] && IsValidEntity(camera))
        return Plugin_Handled;

    // Try get a 'camera'
    camera = CreateVirtualCamera(client);
    if(!IsValidEntity(camera))
        return Plugin_Handled;

    // Now we got our camera, let player view it.
    g_bFreeCamera[client] = true;
    g_iFreeCamera[client] = camera;
    SetClientViewEntity(client, camera);

    return Plugin_Handled;
}

Action Cmd_KillFreeCamera(int client, any args)
{
    if(!IsSurvivor(client))
        return Plugin_Handled;

    int camera = g_iFreeCamera[client];
    // If she has a camera, kill it.
    if(IsValidEntity(camera))
    {
        AcceptEntityInput(camera, "Kill");
        RemoveEntity(camera);
    }
    // Let player view herself.
    SetClientViewEntity(client, client);
    g_bFreeCamera[client] = false;
    g_iFreeCamera[client] = -1;

    return Plugin_Handled;
}

int CreateVirtualCamera(int target)
{
    int camera;
    float origin[3];
    float rotate[3];
    float lookat[3];

    GetEntPropVector(target, Prop_Send, "m_vecOrigin", origin);
    GetEntPropVector(target, Prop_Send, "m_angRotation", rotate);

    // Only tank rock can get velocity...(dont know why)
    camera = CreateEntityByName("tank_rock");
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
    // Record when camera has create
    float camtime = GetGameTime();

    AcceptEntityInput(camera, "DisableShadow");
    SetEntPropEnt(camera, Prop_Data, "m_hOwnerEntity", target);
    SetEntityRenderMode(camera, RENDER_TRANSCOLOR);
    SetEntityMoveType(camera, MOVETYPE_NOCLIP);
    SetEntityRenderColor(camera, 0, 0, 0, 0);
    SetEntityCollisionGroup(camera, 0);

    char name[64];
    for(int i = 0; i <= MaxEnities; i++)
    {
        if(!IsValidEntity(i)) continue;
        GetEntityClassname(i, name, sizeof(name));
        if(!strcmp(name, "info_particle_system", false))
        {
            // When particle create, kill it.(make sure player wont notice that she is a tank rock xD)
            float partime = GetEntPropFloat(i, Prop_Send, "m_flStartTime");
            // Make sure we
            if(partime - camtime <= 2.0)
                AcceptEntityInput(i, "Kill");
        }
    }

    return camera;
}
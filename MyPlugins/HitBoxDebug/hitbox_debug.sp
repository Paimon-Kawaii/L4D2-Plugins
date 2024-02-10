/*
 * @Author:             我是派蒙啊
 * @Last Modified by: 我是派蒙啊
 * @Create Date:        2023-02-15 19:32:26
 * @Last Modified time: 2024-02-10 16:26:35
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sourcemod>
#include <paiutils>
#include <left4dhooks>

#define VERSION "2023.02.16"

const int
    g_iFrameMax = 20;    //帧间隔

int
    g_iInfected = 0;    // HitBox对象
// g_iFrameCounter = 0;//间隔帧CD

ConVar
    g_hDebug;

public Plugin myinfo =
{
    name = "DebugCore",
    author = "我是派蒙啊",
    description = "本地服测试专用",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins/MyPlugins"
};

public void OnPluginStart()
{
    HookEvent("player_death", Event_PlayerDeath);
    FindConVar("l4d2_addons_eclipse").AddChangeHook(CVarEvent_OnAddonsEclipse);
    FindConVar("l4d2_addons_eclipse").SetInt(1);

    g_hDebug = CreateConVar("l4d_debug_enable", "0", "");
    g_hDebug.AddChangeHook(CVarEvent_DebugModeChanged);

    RegConsoleCmd("sm_ts", Cmd_Test, "");
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (IsValidClient(client)) KickClient(client);
}

Action Cmd_Test(int client, any args)
{
    QueryClientConVar(client, "sv_minrate", QueryClientConVarCallBack);
    QueryClientConVar(client, "sv_maxrate", QueryClientConVarCallBack);
    QueryClientConVar(client, "sv_mincmdrate", QueryClientConVarCallBack);
    QueryClientConVar(client, "sv_maxcmdrate", QueryClientConVarCallBack);
    QueryClientConVar(client, "sv_minupdaterate", QueryClientConVarCallBack);
    QueryClientConVar(client, "sv_maxupdaterate", QueryClientConVarCallBack);

    SendConVarValue(client, FindConVar("sv_mincmdrate"), "30");
    SendConVarValue(client, FindConVar("sv_maxcmdrate"), "30");
    SendConVarValue(client, FindConVar("sv_minupdaterate"), "30");
    SendConVarValue(client, FindConVar("sv_maxupdaterate"), "30");
    SendConVarValue(client, FindConVar("sv_minrate"), "10000");
    SendConVarValue(client, FindConVar("sv_maxrate"), "10000");

    SetClientInfo(client, "cl_updaterate", "30");
    SetClientInfo(client, "cl_cmdrate", "30");

    PrintToChatAll("%d", GetClientDataRate(client));

    return Plugin_Handled;
}

void QueryClientConVarCallBack(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
    PrintToChatAll("%N 的 %s Cvar 值是 %s", client, cvarName, cvarValue);
}

public void CVarEvent_OnAddonsEclipse(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (StringToInt(newValue) != 1)
        convar.SetInt(1, true);
}

public void CVarEvent_DebugModeChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    FindConVar("sv_showonlyhitbox").SetInt(-1);
    // FindConVar("impact_vis").SetInt(convar.IntValue);
    FindConVar("sv_showhitboxes").SetInt(convar.IntValue);
    FindConVar("melee_show_swing").SetInt(convar.IntValue);
    FindConVar("sv_showlagcompensation").SetInt(convar.IntValue);
}

//替换特感类型
public Action L4D_OnSpawnSpecial(int &zombieClass, const float vecPos[3], const float vecAng[3])
{
    if (!g_hDebug.IntValue) return Plugin_Continue;

    if (zombieClass == ZC_Charger)
        FindConVar("sv_showonlyhitbox").SetInt(9);
    else if (zombieClass == ZC_Jockey || zombieClass == ZC_Spitter)
        FindConVar("sv_showonlyhitbox").SetInt(4);
    else FindConVar("sv_showonlyhitbox").SetInt(10);

    if (HasInfectedAlive())
        return Plugin_Handled;

    return Plugin_Continue;
}

public void OnGameFrame()
{
    // if(g_iFrameCounter == 0)
    if (g_hDebug.IntValue)
        ShowHitBox();

    for (int client = 1; client <= MaxClients && g_hDebug.BoolValue; client++)
        if (IsSurvivor(client) && IsPlayerAlive(client))
            SetEntPropFloat(client, Prop_Send, "m_flCycle", 1.0);

    //更新刷新帧
    // g_iFrameCounter = (g_iFrameCounter + 1) % g_iFrameMax;
}

void ShowHitBox()
{
    //显示HitBox
    for (int client = 1; client <= MaxClients; client++)
        if (IsInfected(client) && IsPlayerAlive(client) && g_iInfected < client && IsEntitySawThreats(client) && IsPlayerVisible(client))
        {
            g_iInfected = client;
            if (GetZombieClass(client) == ZC_Tank)
                FindConVar("sv_showonlyhitbox").SetInt(0);
            FindConVar("sv_showhitboxes").SetInt(client);
            break;
        }

    //如果选定目标后续还有特感
    for (int client = g_iInfected + 1; client <= MaxClients; client++)
        if (IsInfected(client)) return;

    g_iInfected = 0;
}

bool IsPlayerVisible(int target, int team = 2, int target_team = 3)
{
    float pos[3];
    GetClientAbsOrigin(target, pos);
    for (int i = 1; i <= MaxClients; i++)
        if (IsSurvivor(i) && IsPlayerAlive(i) && L4D2_IsVisibleToPlayer(i, team, target_team, 0, pos))
            return true;

    return false;
}
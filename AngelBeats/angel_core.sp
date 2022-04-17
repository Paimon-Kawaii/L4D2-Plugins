/*
 * @Author:             派蒙
 * @Last Modified by:   派蒙
 * @Create Date:        2022-03-23 12:42:32
 * @Last Modified time: 2022-04-17 10:53:51
 * @Github:             http://github.com/PaimonQwQ
 */

#pragma semicolon 1
#pragma newdecls required

#include <colors>
#include <sdktools>
#include <l4d2tools>
#include <sourcemod>
#include <left4dhooks>

#define MAXSIZE 33
#define VERSION "2022.04.15"

public Plugin myinfo =
{
    name = "AngelCore",
    author = "我是派蒙啊",
    description = "AngelServer的启动核心(P.S. 改自内鬼插件-anneserver.sp)",
    version = VERSION,
    url = "http://github.com/PaimonQwQ/L4D2-Plugins/AngelBeats"
};

enum Msgs
{
    Msg_Connecting = 0,
    Msg_Connected,
    Msg_DisConnected,
    Msg_PlayerSuicide,
    Msg_PlayerCanJoin,
    Msg_Error,
};//Message enums for message array(as an index)

char
    messages[][] =
    {
        "{olive}[天使] {default}提醒您：{blue}%N {default}将加入战线",
        "{olive}[天使] {default}提醒您：{blue}%N {default}加入了战线",
        "{olive}[天使] {default}提醒您：{blue}%N {default}离开了战线",
        "{olive}[天使] {default}提醒您：{blue}%N {default}心满意足的消失了",
        "{olive}[天使] {default}提醒您：{default}当前无生还Bot，请在开局前使用 {orange}!jg",
        "{olive}[天使] {default}提醒您：{red}#检测到未知错误，AngelPlayer即将重启",
    };//Messages for player to show

bool
    g_bIsGameStart;

float
    g_fLastDisconnectTime;

ConVar
    g_hServerMaxSurvivor;

//插件入口
public void OnPluginStart()
{
    HookEvent("round_start", Event_RoundStart, EventHookMode_Pre);
    HookEvent("player_death", Event_PlayerDead, EventHookMode_Pre);
    HookEvent("mission_lost", Event_MissionLost, EventHookMode_Pre);
    HookEvent("finale_win", Event_ResetSurvivors, EventHookMode_Pre);
    HookEvent("map_transition", Event_ResetSurvivors, EventHookMode_Pre);
    HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
    HookEvent("player_incapacitated", Event_PlayerIncapped, EventHookMode_Pre);

    g_hServerMaxSurvivor = FindConVar("survivor_limit");

    RegConsoleCmd("sm_ammo", Cmd_GiveAmmo, "Give survivor ammo");

    RegConsoleCmd("sm_jg", Cmd_JoinSurvivor, "Turn player to survivor");
    RegConsoleCmd("sm_join", Cmd_JoinSurvivor, "Turn player to survivor");

    RegConsoleCmd("sm_s", Cmd_JoinSpectator, "Turn player to spectator");
    RegConsoleCmd("sm_afk", Cmd_JoinSpectator, "Turn player to spectator");
    RegConsoleCmd("sm_spec", Cmd_JoinSpectator, "Turn player to spectator");
    RegConsoleCmd("sm_away", Cmd_JoinSpectator, "Turn player to spectator");

    RegConsoleCmd("sm_zs", Cmd_PlayerSuicide, "Player suicided");
    RegConsoleCmd("sm_kill", Cmd_PlayerSuicide, "Player suicided");
}

//地图加载
public void OnMapStart()
{
    RestoreHealth();
    ResetInventory();
    SetGodMode(true);

    g_bIsGameStart = false;
    FindConVar("mp_gamemode").SetString("coop");
}

//玩家正在连接
public void OnClientConnected(int client)
{
    if (GetSurvivorCount() > 4)
    {
        CPrintToChatAll(messages[Msg_Error]);
        CreateTimer(2.0, Timer_RestartMap, 0, TIMER_FLAG_NO_MAPCHANGE);
    }

    if (IsFakeClient(client)) return;

    CPrintToChatAll(messages[Msg_Connecting], client);
}

//玩家进入服务器
public void OnClientPutInServer(int client)
{
    if (IsFakeClient(client)) return;

    CPrintToChatAll(messages[Msg_Connected], client);
    g_hServerMaxSurvivor.SetInt(GetSurvivorPlayerCount());
}

//玩家断开连接
public void OnClientDisconnect(int client)
{
    if (!IsValidClient(client)) return;

    if (IsClientInGame(client) && IsFakeClient(client))
        return;

    float currenttime = GetGameTime();

    if (IsClientInGame(client))
        CPrintToChatAll(messages[Msg_DisConnected], client);

    if(!g_bIsGameStart)
        g_hServerMaxSurvivor.SetInt(GetSurvivorPlayerCount());

    if (g_fLastDisconnectTime == currenttime)
        return;

    CreateTimer(3.0, Timer_IsNobodyConnected, currenttime, TIMER_FLAG_NO_MAPCHANGE);
    g_fLastDisconnectTime = currenttime;
}

// 对抗计分面板出现前
public Action L4D2_OnEndVersusModeRound(bool countSurvivors)
{
    FindConVar("mp_gamemode").SetString("realism");
    return Plugin_Handled;
}

//玩家离开安全屋
public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
    SetGodMode(false);
    g_bIsGameStart = true;
    g_hServerMaxSurvivor.SetInt(GetSurvivorPlayerCount());
    CreateTimer(0.1, Timer_AutoGive, 0, TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Continue;
}

//回合开始事件
public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    RestoreHealth();
    ResetInventory();
    g_bIsGameStart = false;
    FindConVar("mp_gamemode").SetString("coop");
    g_hServerMaxSurvivor.SetInt(GetSurvivorPlayerCount());
    return Plugin_Continue;
}

//玩家死亡事件
public Action Event_PlayerDead(Event event, const char[] name, bool dont_broadcast)
{
    if (GetAliveSurvivorCount() == 0)
    {
        g_bIsGameStart = false;
        FindConVar("mp_gamemode").SetString("realism");
        g_hServerMaxSurvivor.SetInt(GetSurvivorPlayerCount());
        SetGodMode(true);
    }
    return Plugin_Continue;
}

//关卡结束
public Action Event_MissionLost(Event event, const char[] name, bool dont_broadcast)
{
    FindConVar("mp_gamemode").SetString("realism");
    if(!IsAllSurvivorPinned()) return Plugin_Continue;

    for(int i = 1; i < MaxClients; i++)
        if(IsSurvivor(i) && (IsPlayerIncap(i) || IsSurvivorPinned(i)))
            ForcePlayerSuicide(i);

    return Plugin_Continue;
}

//重置玩家信息
public Action Event_ResetSurvivors(Event event, const char[] name, bool dontBroadcast)
{
    RestoreHealth();
    ResetInventory();
    g_bIsGameStart = false;
    FindConVar("mp_gamemode").SetString("realism");
    g_hServerMaxSurvivor.SetInt(GetSurvivorPlayerCount());
    return Plugin_Continue;
}

//玩家均被制服时
public Action Event_PlayerIncapped(Event event, const char[] name, bool dontBroadcast)
{
    if(!IsAllSurvivorPinned()) return Plugin_Continue;

    for(int i = 1; i < MaxClients; i++)
        if(IsSurvivor(i) && (IsPlayerIncap(i) || IsSurvivorPinned(i)))
            ForcePlayerSuicide(i);

    return Plugin_Continue;
}

//玩家离开服务器
public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
    SetEventBroadcast(event, false);
    dontBroadcast = true;
    return Plugin_Handled;
}

//给予玩家子弹
public Action Cmd_GiveAmmo(int client, any args)
{
    if (IsValidClient(client) && IsSurvivor(client))
        BypassAndExecuteCommand(client, "give", "ammo");
    return Plugin_Handled;
}

//加入生还
public Action Cmd_JoinSurvivor(int client, any args)
{
    if (IsValidClient(client) && !IsSurvivor(client) && !IsFakeClient(client))
    {
        if(IsSurvivorTeamFull() && g_bIsGameStart)
        {
            CPrintToChat(client, messages[Msg_PlayerCanJoin]);
            return Plugin_Handled;
        }
        int survivorcount = (!IsSurvivorTeamFull() || g_hServerMaxSurvivor.IntValue >= 4) ? g_hServerMaxSurvivor.IntValue : g_hServerMaxSurvivor.IntValue + 1;
        g_hServerMaxSurvivor.SetInt(survivorcount);
        ClientCommand(client, "jointeam survivor");
        CreateTimer(0.1, Timer_NoWander, client, TIMER_REPEAT);
    }
    return Plugin_Handled;
}

//进入旁观（被控禁止旁观）
public Action Cmd_JoinSpectator(int client, any args)
{
    if (!IsValidClient(client)) return Plugin_Handled;

    if (!IsSurvivorPinned(client))
        CreateTimer(0.5, Timer_CheckAway, client, TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Handled;
}

//玩家自杀
public Action Cmd_PlayerSuicide(int client, any args)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client)) return Plugin_Handled;

    CPrintToChatAll(messages[Msg_PlayerSuicide], client);
    ForcePlayerSuicide(client);
    return Plugin_Handled;
}

//地图重启
public Action Timer_RestartMap(Handle timer, int client)
{
    CrashMap();
}

//服务器空置
public Action Timer_IsNobodyConnected(Handle timer, any timerDisconnectTime)
{
    if (g_fLastDisconnectTime != timerDisconnectTime)
        return Plugin_Stop;

    for (int i = 1; i <= MaxClients ;i++)
        if (IsValidClient(i) && !IsFakeClient(i))
            return Plugin_Stop;

    CrashServer();

    return Plugin_Continue;
}

//自动给予药品
public Action Timer_AutoGive(Handle timer)
{
    for (int client = 1; client <= MaxClients; client++)
        if (IsSurvivor(client) && !IsFakeClient(client))
        {
            if (!IsPlayerAlive(client)) L4D_RespawnPlayer(client);
            if(GetPlayerWeaponSlot(client, 4) == -1)
                BypassAndExecuteCommand(client, "give", "pain_pills");
            if(GetPlayerHealth(client) < 100)
                BypassAndExecuteCommand(client, "give", "health");
            SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
            SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
            SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
        }
    return Plugin_Continue;
}

//玩家旁观Timer
public Action Timer_CheckAway(Handle timer, int client)
{
    if (!IsValidClient(client) || IsFakeClient(client)) return Plugin_Stop;

    ChangeClientTeam(client, TEAM_SPECTATOR);
    return Plugin_Continue;
}

//取消玩家闲置
public Action Timer_NoWander(Handle timer, int client)
{
    if(IsSurvivorTeamFull()) return Plugin_Continue;

    int flags = GetCommandFlags("sb_takecontrol");
    SetCommandFlags("sb_takecontrol", flags & (~FCVAR_CHEAT));
    FakeClientCommand(client, "sb_takecontrol");
    SetCommandFlags("sb_takecontrol", flags);
    return Plugin_Stop;
}

//重置玩家血量
void RestoreHealth()
{
    for (int client = 1; client <= MaxClients; client++)
        if (IsSurvivor(client))
        {
            if(GetPlayerHealth(client) < 100)
                BypassAndExecuteCommand(client, "give", "health");
            SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
            SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
            SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
        }
}

//设置玩家状态
void SetGodMode(bool status)
{
    int flags = GetCommandFlags("god");
    SetCommandFlags("god", flags & (~FCVAR_NOTIFY));
    SetConVarInt(FindConVar("god"), status);
    SetCommandFlags("god", flags);
    SetConVarInt(FindConVar("sv_infinite_ammo"), status);
}

//重置玩家背包
void ResetInventory()
{
    for (int client = 1; client <= MaxClients; client++)
        if (IsSurvivor(client))
        {
            for (int i = 0; i < 5; i++)
                DeleteInventoryItem(client, i);

            BypassAndExecuteCommand(client, "give", "pistol");
        }
}

//删除背包物品
void DeleteInventoryItem(int client, int slot)
{
    if (!IsValidClient(client)) return;

    int item = GetPlayerWeaponSlot(client, slot);
    if (item > 0)
        RemovePlayerItem(client, item);
}

//重启地图
void CrashMap()
{
    char mapname[64];
    GetCurrentMap(mapname, 64);
    ServerCommand("changelevel %s", mapname);
}

//重启服务器
void CrashServer()
{
    SetCommandFlags("crash", GetCommandFlags("crash") & (~FCVAR_CHEAT));
    ServerCommand("crash");
}
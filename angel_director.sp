/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   派蒙
 * @Create Date:        2022-03-24 17:00:57
 * @Last Modified time: 2022-03-31 17:11:21
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
#define VERSION "2022.03.31"

public Plugin myinfo =
{
    name = "AngelDirector",
    author = "我是派蒙啊",
    description = "AngelServer的刷特导演",
    version = VERSION,
    url = "http://github.com/PaimonQwQ/AngelBeats/angel_director.sp",
};

int
    g_iSelfClearTimes[MAXSIZE];

bool
	g_bIsRoundOver,
	g_bIsSpawnable,
    g_bIsSelfCleared,
    g_bShowSaveMsg[MAXSIZE];

ConVar
    //对抗模式开关
    g_hAngelVersus,
	//导演刷特限制
    g_hHunterLimit,
    g_hBoomerLimit,
    g_hSmokerLimit,
    g_hJockeyLimit,
    g_hChargerLimit,
    g_hSpitterLimit,
    //插件刷特限制
    g_hSICountLimit,
    g_hSpawnInterval,
    g_hAngelHunterLimit,
    g_hAngelBoomerLimit,
    g_hAngelSmokerLimit,
    g_hAngelJockeyLimit,
    g_hAngelChargerLimit,
    g_hAngelSpitterLimit;

//插件入口
public void OnPluginStart()
{
    HookEvent("player_death", Event_PlayerDead);
    HookEvent("witch_killed", Event_WitchKilled);
    HookEvent("player_hurt", Event_PlayerHurted);
    HookEvent("tank_spawn", Event_TankSpawn, EventHookMode_Pre);
    HookEvent("player_team", Event_PlayerChangeTeam, EventHookMode_Pre);

    g_hHunterLimit = FindConVar("z_hunter_limit");
    g_hBoomerLimit = FindConVar("z_boomer_limit");
    g_hSmokerLimit = FindConVar("z_smoker_limit");
    g_hJockeyLimit = FindConVar("z_jockey_limit");
    g_hChargerLimit = FindConVar("z_charger_limit");
    g_hSpitterLimit = FindConVar("z_spitter_limit");

    g_hSICountLimit = CreateConVar("l4d_infected_limit", "6", "特感数量限制");
    g_hSpawnInterval = CreateConVar("versus_special_respawn_interval", "16", "复活时间限制");

    g_hAngelHunterLimit = CreateConVar("angel_hunter_limit", "1", "Hunter数量限制");
    g_hAngelBoomerLimit = CreateConVar("angel_boomer_limit", "1", "Boomer数量限制");
    g_hAngelSmokerLimit = CreateConVar("angel_smoker_limit", "1", "Smoker数量限制");
    g_hAngelJockeyLimit = CreateConVar("angel_jockey_limit", "1", "Jockey数量限制");
    g_hAngelChargerLimit = CreateConVar("angel_charger_limit", "1", "Charger数量限制");
    g_hAngelSpitterLimit = CreateConVar("angel_spitter_limit", "1", "Spitter数量限制");

    g_hHunterLimit.AddChangeHook(CvarEvent_LimitChanged);
    g_hBoomerLimit.AddChangeHook(CvarEvent_LimitChanged);
    g_hSmokerLimit.AddChangeHook(CvarEvent_LimitChanged);
    g_hJockeyLimit.AddChangeHook(CvarEvent_LimitChanged);
    g_hChargerLimit.AddChangeHook(CvarEvent_LimitChanged);
    g_hSpitterLimit.AddChangeHook(CvarEvent_LimitChanged);

    g_hSICountLimit.AddChangeHook(CvarEvent_InfectedChanged);
    g_hSpawnInterval.AddChangeHook(CvarEvent_InfectedChanged);

    g_hAngelVersus = CreateConVar("angel_versus", "0", "Angel对抗开关");

    RegConsoleCmd("sm_dc", Cmd_DirectorMsg, "Show director-manager information");
    RegConsoleCmd("sm_xx", Cmd_DirectorMsg, "Show director-manager information");
}

//地图加载
public void OnMapStart()
{
	InitLimit();
}

//玩家解控
public Action OnPlayerRunCmd(int client, int &buttons, int &impuls)
{
    //当生还存活并且未倒地，且仍被特感控制时，使用交互键并还有剩余解控次数，生还数量在2-3人时，判断是否可解控
    if (IsSurvivor(client) && IsPlayerAlive(client) && IsSurvivorPinned(client) && 
        !IsPlayerIncap(client) && (buttons & IN_USE) && g_iSelfClearTimes[client] > 0 && 
        GetSurvivorCount() < 4 && GetSurvivorCount() > 1)
    {
        int attacker = GetSurvivorPinner(client);
        //如果攻击者是特感，并且特感存活且仍在控制生还，若已展示解控提示，则进行解控
        if(IsInfected(attacker) && IsPlayerAlive(attacker) &&
         IsPinningASurvivor(attacker) && g_bShowSaveMsg[client])
        {
            int remain = GetClientHealth(attacker);
            g_iSelfClearTimes[client]--;
            g_bShowSaveMsg[client] = false;

            ForcePlayerSuicide(attacker);
            SetPlayerHealth(client, GetPlayerHealth(client) - 3);
            CreateTimer(0.1, Timer_CancelGetup, client, TIMER_FLAG_NO_MAPCHANGE);

            CPrintToChat(client, "[{olive}SSS团{default}] {default}剩余解控次数：{red}%d", g_iSelfClearTimes[client]);
            CPrintToChat(client, "[{olive}SSS团{default}] {red}%N{default} 还有 {olive}%d{default} 血!", attacker, remain);
        }
    }

    return Plugin_Continue;
}

//玩家断开连接
public void OnClientDisconnect(int client)
{
    g_bShowSaveMsg[client] = false;
    g_iSelfClearTimes[client] = GetSurvivorCount() <= 2 ? g_hSICountLimit.IntValue - 2 : 1;
}

//玩家特感进入灵魂状态
public void L4D_OnEnterGhostState(int client)
{
    //Angel对抗未开启，玩家进入特感灵魂时移动至旁观
    if(!g_hAngelVersus.BoolValue)
        ChangeClientTeam(client, TEAM_SPECTATOR);
}

//玩家离开安全屋
public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
    g_bIsSelfCleared = false;
    g_bIsRoundOver = g_bIsSpawnable = true;
    for(int i = 1; i < MaxClients; i++)
    {
        g_bShowSaveMsg[i] = false;
        g_iSelfClearTimes[i] = GetSurvivorCount() <= 2 ? g_hSICountLimit.IntValue - 2 : 1;
    }

    CreateTimer(0.5, Timer_FirstSpawn, 0, TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Continue;
}

//坦克生成事件
public Action Event_TankSpawn(Event event, const char[] name, bool dont_broadcast)
{
    int tank = GetClientOfUserId(event.GetInt("userid"));
    int heal = GetSurvivorCount() > 2 ? 1500 * GetSurvivorCount() : 1100 * GetSurvivorCount();
    SetPlayerHealth(tank, heal);
    return Plugin_Continue;
}

//特感死亡事件
public Action Event_PlayerDead(Event event, const char[] name, bool dont_broadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    return Plugin_Continue;
}

//秒妹回血
public Action Event_WitchKilled(Event event, const char[] name, bool dont_broadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (IsSurvivor(client) && IsPlayerAlive(client) && !IsPlayerIncap(client))
    {
        int iMaxHp = GetEntProp(client, Prop_Data, "m_iMaxHealth");
        int iTargetHealth = GetPlayerHealth(client) + 10;
        if (iTargetHealth > iMaxHp)
            iTargetHealth = iMaxHp;

        SetPlayerHealth(client, iTargetHealth);
    }
    return Plugin_Continue;
}

//非4人时进行解控
public Action Event_PlayerHurted(Event event, const char[] name, bool dont_broadcast)
{
    int damage = event.GetInt("dmg_health");
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int zclass = GetEntProp(attacker, Prop_Send, "m_zombieClass");
    int remain = GetClientHealth(attacker);

    if (!IsSurvivor(victim) || !IsInfected(attacker) || zclass == view_as<int>(ZC_Spitter) ||
        !IsSurvivorPinned(victim) || IsPlayerIncap(victim))
        return Plugin_Continue;

    if(GetSurvivorCount() == 1)
    {
        ForcePlayerSuicide(attacker);
        SetPlayerHealth(victim, GetPlayerHealth(victim) - (damage - 1));
        CreateTimer(0.1, Timer_CancelGetup, victim, TIMER_FLAG_NO_MAPCHANGE);
        CPrintToChat(victim, "{olive}[SSS团] {red}%N{default} 还有 {olive}%d{default} 血!", attacker, remain);
    }
    else if(GetSurvivorCount() < 4 && g_iSelfClearTimes[victim] > 0 && !g_bShowSaveMsg[victim])
    {
        g_bShowSaveMsg[victim] = true;
        PrintHintText(victim, "使用 E(交互)键 解控！");
    }

    return Plugin_Continue;
}

//玩家切换队伍时修正尸潮数量
public Action Event_PlayerChangeTeam(Event event, const char[] name, bool dont_broadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    int team = GetClientOfUserId(event.GetInt("team"));
    if(!IsValidClient(client) || IsFakeClient(client)) 
        return Plugin_Continue;

    CreateTimer(0.1, Timer_MobChange, 0, TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Continue;
}

//取消生还起身延迟
public Action Timer_CancelGetup(Handle timer, any client)
{
    if (IsValidClient(client))
        SetEntPropFloat(client, Prop_Send, "m_flCycle", 1.0);
    return Plugin_Continue;
}

//Angel第一次刷特
public Action Timer_FirstSpawn(Handle timer)
{
    g_bIsRoundOver = g_bIsSpawnable = false;

    StartSpawn(0);

    return Plugin_Continue;
}

//尸潮数量更改
public Action Timer_MobChange(Handle timer)
{
    FindConVar("z_common_limit").SetInt(4 * GetSurvivorCount());
    FindConVar("z_mega_mob_size").SetInt(6 * GetSurvivorCount());
    FindConVar("z_mob_spawn_min_size").SetInt(3 * GetSurvivorCount());
    FindConVar("z_mob_spawn_max_size").SetInt(4 * GetSurvivorCount());
}

//特感数量更改
public void CvarEvent_LimitChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    convar.SetInt(0, true);
}

//上限更改
public void CvarEvent_InfectedChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    // g_hAngelCountLimit.SetInt(g_hSICountLimit.IntValue);
    // g_hAngelSpawnInterval.SetInt(g_hSpawnInterval.IntValue);
}

public Action Cmd_DirectorMsg(int client, any args)
{
    //CPrintToChatAll("");
    return Plugin_Continue;
}

//禁止导演刷特
void InitLimit()
{
    g_hHunterLimit.SetInt(0, true);
    g_hBoomerLimit.SetInt(0, true);
    g_hSmokerLimit.SetInt(0, true);
    g_hJockeyLimit.SetInt(0, true);
    g_hChargerLimit.SetInt(0, true);
    g_hSpitterLimit.SetInt(0, true);
}

//开始刷特
void StartSpawn(int client)
{

}
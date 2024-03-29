/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-05-21 15:57:19
 * @Last Modified time: 2023-07-16 23:51:44
 * @Github:             https://github.com/Paimon-Kawaii
 */
#pragma semicolon 1
#pragma newdecls required

#include <sdkhooks>
#include <sdktools>
#include <paiutils>
#include <sourcemod>
#include <left4dhooks>

#define VERSION "2023.05.20"
#define MAXSIZE MAXPLAYERS + 1
#define DEBUG 0

ConVar
    g_hVersus,
    g_hPartyType;

public Plugin myinfo =
{
    name = "Single Versus",
    author = "我是派蒙啊",
    description = "特感训练",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins/MyPlugins"
};

public void OnPluginStart()
{
    //初始化ConVar
    InitCVars();
    HookEvent("round_start", Event_RoundStart);
    AddCommandListener(Noclip_Callback, "noclip");
}

Action Noclip_Callback(int client, const char[] command, int argc)
{
    if(FindConVar("sv_cheats").BoolValue) return Plugin_Continue;
    MoveType movetype = GetEntityMoveType(client);
    if(movetype != MOVETYPE_NOCLIP)
        SetEntityMoveType(client, MOVETYPE_NOCLIP);
    else SetEntityMoveType(client, MOVETYPE_WALK);

    return Plugin_Handled;
}

//创建ConVar
void InitCVars()
{
    //开关
    g_hVersus = CreateConVar("single_versus", "1", "对抗开关");
    g_hPartyType = CreateConVar("psv_party", "3", "训练类型");

    FindConVar("z_hunter_limit").SetInt(0);
    FindConVar("z_jockey_limit").SetInt(0);
    FindConVar("z_smoker_limit").SetInt(0);
    FindConVar("z_boomer_limit").SetInt(0);
    FindConVar("z_spitter_limit").SetInt(0);
    FindConVar("z_charger_limit").SetInt(0);
    FindConVar("l4d2_addons_eclipse").SetInt(1);
    FindConVar("mp_gamemode").SetString("versus");
    // FindConVar("sv_cheats").AddChangeHook(CVarEvent_CVChanged);
    // FindConVar("z_hunter_limit").AddChangeHook(CVarEvent_CVChanged);
    // FindConVar("z_jockey_limit").AddChangeHook(CVarEvent_CVChanged);
    // FindConVar("z_smoker_limit").AddChangeHook(CVarEvent_CVChanged);
    // FindConVar("z_boomer_limit").AddChangeHook(CVarEvent_CVChanged);
    // FindConVar("z_spitter_limit").AddChangeHook(CVarEvent_CVChanged);
    // FindConVar("z_charger_limit").AddChangeHook(CVarEvent_CVChanged);
    FindConVar("l4d2_addons_eclipse").AddChangeHook(CVarEvent_CVChanged);

    int flags = GetCommandFlags("noclip");
    SetCommandFlags("noclip", flags & ~FCVAR_CHEAT);
    FindConVar("sv_cheats").Flags &= ~FCVAR_CHEAT;
    FindConVar("god").Flags &= ~FCVAR_CHEAT;

    // FindConVar("survivor_limit").SetBounds(ConVarBound_Lower, true, 0.0);
    // FindConVar("survivor_limit").SetInt(4);
    FindConVar("sv_cheats").SetInt(1);
    FindConVar("sb_stop").SetInt(1);
    FindConVar("god").SetInt(1);
    FindConVar("sv_pausable").SetInt(0);
    FindConVar("mp_autoteambalance").SetInt(0);
    FindConVar("z_max_player_zombies").SetInt(32);
    FindConVar("vs_max_team_switches").SetInt(999);
    FindConVar("nb_update_frequency").SetFloat(0.014);
    FindConVar("versus_force_start_time").SetInt(1);
    FindConVar("director_no_survivor_bots").SetInt(0);
    FindConVar("sb_all_bot_game").SetInt(1);
    FindConVar("allow_all_bot_survivor_team").SetInt(1);
    
    FindConVar("z_mob_spawn_min_interval_normal").SetInt(10000);
    FindConVar("z_mob_spawn_max_interval_normal").SetInt(10000);
    FindConVar("versus_special_respawn_interval").SetInt(0);
    FindConVar("z_mob_spawn_min_size").SetInt(0);
    FindConVar("z_mob_spawn_max_size").SetInt(0);
    FindConVar("z_ghost_delay_min").SetInt(0);
    FindConVar("z_ghost_delay_max").SetInt(0);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    int door = L4D_GetCheckpointFirst();
    if(!IsValidEntity(door)) return;
    AcceptEntityInput(door, "Kill");
    RemoveEdict(door);

    FindConVar("z_hunter_limit").SetInt(0);
    FindConVar("z_jockey_limit").SetInt(0);
    FindConVar("z_smoker_limit").SetInt(0);
    FindConVar("z_boomer_limit").SetInt(0);
    FindConVar("z_spitter_limit").SetInt(0);
    FindConVar("z_charger_limit").SetInt(0);
    // FindConVar("l4d2_addons_eclipse").SetInt(0);
    FindConVar("mp_gamemode").SetString("versus");
    // FindConVar("sv_cheats").AddChangeHook(CVarEvent_CVChanged);
    // FindConVar("z_hunter_limit").AddChangeHook(CVarEvent_CVChanged);
    // FindConVar("z_jockey_limit").AddChangeHook(CVarEvent_CVChanged);
    // FindConVar("z_smoker_limit").AddChangeHook(CVarEvent_CVChanged);
    // FindConVar("z_boomer_limit").AddChangeHook(CVarEvent_CVChanged);
    // FindConVar("z_spitter_limit").AddChangeHook(CVarEvent_CVChanged);
    // FindConVar("z_charger_limit").AddChangeHook(CVarEvent_CVChanged);
    // FindConVar("l4d2_addons_eclipse").AddChangeHook(CVarEvent_CVChanged);

    int flags = GetCommandFlags("noclip");
    SetCommandFlags("noclip", flags & ~FCVAR_CHEAT);
    flags = GetCommandFlags("director_stop");
    SetCommandFlags("director_start", flags & ~FCVAR_CHEAT);
    flags = GetCommandFlags("director_start");
    SetCommandFlags("director_stop", flags & ~FCVAR_CHEAT);
    FindConVar("sv_cheats").Flags &= ~FCVAR_CHEAT;
    FindConVar("god").Flags &= ~FCVAR_CHEAT;
    ServerCommand("director_stop");

    // FindConVar("survivor_limit").SetBounds(ConVarBound_Lower, true, 0.0);
    // FindConVar("survivor_limit").SetInt(4);
    FindConVar("sv_cheats").SetInt(1);
    FindConVar("sb_stop").SetInt(1);
    FindConVar("god").SetInt(1);
    FindConVar("sv_pausable").SetInt(0);
    FindConVar("mp_autoteambalance").SetInt(0);
    FindConVar("z_max_player_zombies").SetInt(32);
    FindConVar("vs_max_team_switches").SetInt(999);
    FindConVar("nb_update_frequency").SetFloat(0.014);
    FindConVar("versus_force_start_time").SetInt(1);
    FindConVar("director_no_survivor_bots").SetInt(0);
    FindConVar("sb_all_bot_game").SetInt(1);
    FindConVar("allow_all_bot_survivor_team").SetInt(1);
    
    FindConVar("z_mob_spawn_min_interval_normal").SetInt(10000);
    FindConVar("z_mob_spawn_max_interval_normal").SetInt(10000);
    FindConVar("versus_special_respawn_interval").SetInt(0);
    FindConVar("z_mob_spawn_min_size").SetInt(0);
    FindConVar("z_mob_spawn_max_size").SetInt(0);
    FindConVar("z_ghost_delay_min").SetInt(0);
    FindConVar("z_ghost_delay_max").SetInt(0);
}

//Convar值改变
void CVarEvent_CVChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if(convar == FindConVar("l4d2_addons_eclipse"))
    {
        if(convar.IntValue != 1)
            convar.SetInt(1, true);
    }
    else if(convar == FindConVar("sv_cheats"))
    {
        if(convar.IntValue != 1)
            convar.SetInt(1, true);
    }
    else convar.SetInt(0, true);
}

//玩家特感进入灵魂状态
public void L4D_OnEnterGhostState(int client)
{
    if (!IsValidClient(client) || IsFakeClient(client) ||
        g_hPartyType.IntValue < 0 || !g_hVersus.BoolValue) return;
    L4D_SetClass(client, g_hPartyType.IntValue);
    SetEntProp(client, Prop_Send, "m_isGhost", 0);
}

// //地图加载
// public void OnMapStart()
// {
// }

//玩家进入服务器
public void OnClientPutInServer(int client)
{
    if((client != 0 && !IsValidClient(client)) || IsFakeClient(client) || !g_hVersus.BoolValue) return;

    ChangeClientTeam(client, TEAM_INFECTED);
}
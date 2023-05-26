/*
 * @Author:             派蒙
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2022-05-09 11:54:17
 * @Last Modified time: 2023-03-30 22:52:09
 * @Github:             http://github.com/PaimonQwQ
 */

#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <l4d2tools>
#include <sourcemod>
#include <left4dhooks>
#include <colors>
#undef REQUIRE_PLUGIN
#include <readyup>

#define MAXSIZE 33
#define VERSION "2022.05.09"

public Plugin myinfo =
{
    name = "AngelHuntGame",
    author = "我是派蒙啊",
    description = "AngelServer的躲猫猫模式",
    version = VERSION,
    url = "http://github.com/PaimonQwQ/L4D2-Plugins/AngelBeats"
};

int
    g_iCountDown;//插件的倒计时变量

bool
    g_bIsReadyUpSupport;//是否加载ReadyUp依赖

ConVar
    g_hAngelHunt,//躲猫猫CVar
    g_hCountDown;//倒计时CVar

public void OnPluginStart()
{
    g_hAngelHunt = CreateConVar("angel_hunt", "0", "躲猫猫开关");
    g_hCountDown = CreateConVar("angel_count", "35", "躲藏时长");//游戏中更改倒计时
    g_hCountDown.AddChangeHook(CvarEvent_CountDownChanged);

    HookEvent("player_spawn", Event_PlayerSpawn);

    RegConsoleCmd("sm_inf", Cmd_JoinInfected, "Turn player to infected");
}

public void OnAllPluginsLoaded()
{
    g_bIsReadyUpSupport = LibraryExists("readyup");
}

public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, "readyup")) g_bIsReadyUpSupport = false;
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "readyup")) g_bIsReadyUpSupport = true;
}

public void OnMapStart()
{
    if(!(g_hAngelHunt.BoolValue && g_bIsReadyUpSupport))
        return;

    // char name[64];
    for(int i = 1; i < GetMaxEntities(); i++)
        if(IsValidEntity(i) && !IsValidClient(i))
        {
            AcceptEntityInput(i, "Kill");
            RemoveEntity(i);
        }

    FindConVar("director_no_specials").SetInt(1);
    FindConVar("sv_infinite_ammo").SetInt(1);
    FindConVar("z_common_limit").SetInt(0);
}

public void OnRoundIsLive()
{
    if(!(g_hAngelHunt.BoolValue && g_bIsReadyUpSupport))
        return;

    SetSurvivors(MOVETYPE_NONE, true);
    CreateTimer(1.0, Timer_StartCountDown, _, TIMER_REPEAT);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impuls)
{
    if(!(g_hAngelHunt.BoolValue && g_bIsReadyUpSupport))
        return Plugin_Continue;

    if(!IsInfected(client))
        return Plugin_Continue;

    if(buttons & IN_DUCK)
        buttons &= ~IN_DUCK;
    if(buttons & IN_ATTACK)
        buttons &= ~IN_ATTACK;
    if(buttons & IN_ATTACK2)
        buttons &= ~IN_ATTACK2;
    if(buttons & IN_ATTACK3)
        buttons &= ~IN_ATTACK3;


    return Plugin_Continue;
}

public Action L4D_OnFirstSurvivorLeftSafeArea()
{
    if(!g_hAngelHunt.BoolValue)
        return Plugin_Handled;

    if(!g_bIsReadyUpSupport)
    {
        CPrintToChatAll("{red}ReadyUp依赖未加载，游戏将不能正常开始！");
        return Plugin_Handled;
    }

    return Plugin_Handled;
}

Action Cmd_JoinInfected(int client, any args)
{
    if(!(g_hAngelHunt.BoolValue && g_bIsReadyUpSupport))
        return Plugin_Handled;

    if (!IsValidClient(client) || !IsInReady())
        return Plugin_Handled;

    ChangeClientTeam(client, TEAM_INFECTED);
    L4D_RespawnPlayer(client);
    L4D_SetClass(client, 3);
    PrintHintText(client, "使用E随机物体，使用R使用技能！");

    return Plugin_Handled;
}

Action Timer_StartCountDown(Handle timer)
{
    if(!(g_hAngelHunt.BoolValue && g_bIsReadyUpSupport))
        return Plugin_Stop;

    if(g_iCountDown <= 0)
    {
        SetSurvivors(MOVETYPE_WALK, false);
        PrintHintTextToAll("游戏开始！");
        g_iCountDown = g_hCountDown.IntValue;
        return Plugin_Stop;
    }
    PrintHintTextToAll("躲藏时间剩余 %d 秒", g_iCountDown--);

    return Plugin_Continue;
}

void CvarEvent_CountDownChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_iCountDown = convar.IntValue;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    // int client = GetClientOfUserId(event.GetInt("userid"));
    // if(IsInfected(client))
}

void SetSurvivors(MoveType movetype, bool blind)
{
    for(int i = 1; i <= MaxClients; i++)
        if(IsSurvivor(i))
        {
            SetPlayerBlind(i, blind);
            SetEntityMoveType(i, movetype);
            for (int v = 0; v < 5; v++)
                RemovePlayerItem(i, v);

            BypassAndExecuteCommand(i, "give", "health");
            BypassAndExecuteCommand(i, "give", "pistol_magnum");
        }
}

//致盲玩家
void SetPlayerBlind(int client, bool blind)
{
    PerformBlind(client, view_as<int>(blind) * 255);
}

void PerformBlind(int target, int amount)
{
    int targets[1];
    targets[0] = target;

    int duration = 1536;
    int holdtime = 1536;
    int flags;
    if (amount == 0)
        flags = (0x0001 | 0x0010);
    else flags = (0x0002 | 0x0008);

    int color[4] = { 0, 0, 0, 0 };
    color[3] = amount;

    Handle message = StartMessageEx(INVALID_MESSAGE_ID, targets, 1);
    if (GetUserMessageType() == UM_Protobuf)
    {
        Protobuf pb = UserMessageToProtobuf(message);
        pb.SetInt("duration", duration);
        pb.SetInt("hold_time", holdtime);
        pb.SetInt("flags", flags);
        pb.SetColor("clr", color);
    }
    else
    {
        BfWrite bf = UserMessageToBfWrite(message);
        bf.WriteShort(duration);
        bf.WriteShort(holdtime);
        bf.WriteShort(flags);       
        bf.WriteByte(color[0]);
        bf.WriteByte(color[1]);
        bf.WriteByte(color[2]);
        bf.WriteByte(color[3]);
    }

    EndMessage();
}
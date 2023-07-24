/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-06-28 11:09:52
 * @Last Modified time: 2023-07-14 23:12:17
 * @Github:             https://github.com/Paimon-Kawaii
 */
#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <paiutils>
#include <sourcemod>
#include <builtinvotes>

#define VERSION "2023.06.28"

#define MAXSIZE MAXPLAYERS + 1

ConVar
    g_hSvPausable,
    g_hSvPauseNoclip;

public Plugin myinfo =
{
    name = "Ready & Pause",
    author = "我是派蒙啊",
    description = "准备与暂停游戏插件",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins"
}

public void OnPluginStart()
{
    g_hSvPausable = FindConVar("sv_pausable");
    g_hSvPauseNoclip = FindConVar("sv_noclipduringpause");
}

void SetPaused(bool flag)
{
    g_hSvPauseNoclip.BoolValue = flag;
    g_hSvPausable.BoolValue = flag;
    ServerCommand(flag ? "pause" : "unpause");
    g_hSvPausable.BoolValue = ~flag;
}
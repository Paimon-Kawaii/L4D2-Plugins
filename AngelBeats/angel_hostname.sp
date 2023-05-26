/*
 * @Author:             派蒙
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2022-05-23 13:49:33
 * @Last Modified time: 2023-03-02 20:59:08
 * @Github:             http://github.com/PaimonQwQ
 */
#pragma semicolon 1
#pragma newdecls required

#include <sdkhooks>
#include <sourcemod>
#include <keyvalues>
#include <SteamWorks>
#define VERSION "2022.06.19"

char
    g_sHostPath[256],
    g_sHostName[256];

ConVar
    g_hAngelSpawnLimit,
    g_hAngelSpawnInterval;

public Plugin myinfo =
{
    name = "AngelName",
    author = "我是派蒙啊",
    description = "AngelServer的名称管理",
    version = VERSION,
    url = "http://github.com/PaimonQwQ/L4D2-Plugins/AngelBeats"
};

public void OnPluginStart()
{
    g_hAngelSpawnLimit = FindConVar("angel_infected_limit");
    g_hAngelSpawnLimit.AddChangeHook(CVarEvent_OnDirectorChanged);
    g_hAngelSpawnInterval = FindConVar("angel_special_respawn_interval");
    g_hAngelSpawnInterval.AddChangeHook(CVarEvent_OnDirectorChanged);
    BuildPath(Path_SM, g_sHostPath, sizeof(g_sHostPath), "configs/AngelName.txt");

    ChangeHostName();
}

public void OnGameFrame()
{
    SteamWorks_SetGameDescription("[Angel Beats!]");
}

public void CVarEvent_OnDirectorChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    ChangeHostName();
}

void ChangeHostName()
{
    char name[256];
    GetHostName();
    Format(name, 256, "%s[%d特/%d秒]", g_sHostName,
        g_hAngelSpawnLimit.IntValue, g_hAngelSpawnInterval.IntValue);
    FindConVar("hostname").SetString(name);
}

void GetHostName()
{
    char port[6];
    Format(port, sizeof(port), "%d", FindConVar("hostport").IntValue);

    KeyValues HostName = new KeyValues("AngelBeats");
    HostName.ImportFromFile(g_sHostPath);

    if (!HostName.JumpToKey(port))
    {
        delete HostName;
        strcopy(g_sHostName, sizeof(g_sHostName), "Angel Beats!");
        return;
    }

    HostName.GetString("ServerName", g_sHostName, sizeof(g_sHostName));
    delete HostName;
}

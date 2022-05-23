/*
 * @Author:             派蒙
 * @Last Modified by:   派蒙
 * @Create Date:        2022-05-23 13:49:33
 * @Last Modified time: 2022-05-23 14:12:20
 * @Github:             http://github.com/PaimonQwQ
 */
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#define VERSION "2022.05.23"

char
    g_sHostName[256];

ConVar
    g_hAngelSpawnLimit,
    g_hAngelSpawnInterval;

public Plugin myinfo =
{
    name = "AngelHostName",
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

    ChangeHostName();
}

public void CVarEvent_OnDirectorChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    ChangeHostName();
}

void ChangeHostName()
{
    char name[256];
    GetHostName();
    Format(name, 256, "%s[%d特/%d秒][AngelBeats!]", g_sHostName,
        g_hAngelSpawnLimit.IntValue, g_hAngelSpawnInterval.IntValue);
    FindConVar("hostname").SetString(name);
}

void GetHostName()
{
    char hostFile[256];
    BuildPath(Path_SM, hostFile, 256, "configs/hostname/l4d2_hostname.txt");
    Handle file = OpenFile(hostFile, "rb");
    if (file)
    {
        while (!IsEndOfFile(file))
            ReadFileLine(file, g_sHostName, 256);

        CloseHandle(file);
    }
}
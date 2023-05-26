/*
 * @Author:             派蒙
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2022-06-21 14:54:54
 * @Last Modified time: 2023-02-16 12:52:12
 * @Github:             http://github.com/PaimonQwQ
 */

#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sourcemod>
#include <left4dhooks>

#define MAXSIZE 33
#define VERSION "2022.06.21"

public Plugin myinfo =
{
    name = "RunCore",
    author = "我是派蒙啊",
    description = "SpeedRun",
    version = VERSION,
    url = "http://github.com/PaimonQwQ/L4D2-Plugins/SpeedRun"
};

public void OnPluginStart()
{
    FindConVar("l4d2_addons_eclipse").SetInt(0);
    FindConVar("l4d2_addons_eclipse").AddChangeHook(CVarEvent_OnAddonsEclipse);
}

public void CVarEvent_OnAddonsEclipse(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if(StringToInt(newValue) != 0)
        convar.SetInt(0, true);
}
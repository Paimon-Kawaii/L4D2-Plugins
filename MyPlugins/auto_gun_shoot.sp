/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-11-24 15:25:25
 * @Last Modified time: 2023-11-29 21:13:03
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <sdkhooks>
#include <sdktools>
#include <paiutils>
#include <sourcemod>

#define VERSION "2023.11.27"
#define DEBUG 0

#define MAXSIZE MAXPLAYERS + 1

char
    g_sMinigunName[][] = 
    {
        "prop_minigun",
        "prop_minigun_l4d1",
    },
    g_sname[][] = //0-15
    {
        "weapon_molotov",
        "weapon_vomitjar",
        "weapon_pipe_bomb",
        "weapon_first_aid_kit",
        "weapon_defibrillator",
        "weapon_chainsaw",
        "weapon_gascan",
        "weapon_propanetank",
        "weapon_oxygentank",
        "weapon_ammo_pack",
        "weapon_gnome",
        "weapon_cola_bottles",
        "weapon_fireworkcrate",
        "weapon_upgradepack_incendiary",
        "weapon_upgradepack_explosive",
        "weapon_ammo_spawn",
    };

ArrayList
    g_alMingunList;

float
    g_fShootPressTime[MAXSIZE];

public Plugin myinfo =
{
    name = "AutoShoot",
    author = "我是派蒙啊",
    description = "全自动武器",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins/MyPlugins"
};

public void OnPluginStart()
{
    g_alMingunList = new ArrayList();
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
    if(!IsSurvivor(client)) return Plugin_Continue;

    if(!(buttons & IN_ATTACK))
    {
        g_fShootPressTime[client] = GetGameTime();
        return Plugin_Continue;
    }

    if((buttons & IN_ATTACK) && GetGameTime() - g_fShootPressTime[client] < 0.2)
        return Plugin_Continue;

    char name[64];

    int minigun = GetEntPropEnt(client, Prop_Send, "m_hUseEntity");
    if(IsValidEntity(minigun))
    {
        GetEntityClassname(minigun, name, sizeof(name));
        for(int i = 0; i < 2; i++)
            if(!strcmp(name, g_sMinigunName[i]))
            {
                if(g_alMingunList.FindValue(minigun) == -1)
                {
                    g_alMingunList.Push(minigun);
                    SDKHook(minigun, SDKHook_ThinkPost, OnThinkPost);
                }
                SetEntProp(minigun, Prop_Send, "m_overheated", 0);
                SetEntPropFloat(minigun, Prop_Send, "m_flCycle", 0.01); 
                if(GetEntPropFloat(minigun, Prop_Send, "m_heat") >= 0.99)
                    SetEntPropFloat(minigun, Prop_Send, "m_heat", 0.99);

                return Plugin_Continue;
            }
    }

    int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if(!IsValidEntity(weapon)) return Plugin_Continue;
    GetEntityClassname(weapon, name, sizeof(name));

    for(int i = 0; i < 16; i++)
        if(!strcmp(name, g_sname[i]))
            return Plugin_Continue;

    int oldbtns = GetEntProp(client, Prop_Data, "m_nOldButtons");
    if ((oldbtns & IN_ATTACK) && (buttons & IN_ATTACK))
        buttons &= ~IN_ATTACK;

    return Plugin_Changed;
}

// public void OnEntityCreated(int entity, const char[] classname)
// {
//     for(int i = 0; i < 2; i++)
//         if(!strcmp(classname, g_sMinigunName[i]))
//         {
//             break;
//         }
// }

void OnThinkPost(int entity)
{
    if(!IsValidEntity(entity))
    {
        g_alMingunList.Erase(g_alMingunList.FindValue(entity));
        SDKUnhook(entity, SDKHook_ThinkPost, OnThinkPost);
        return;
    }

    float scale = 1 + GetEntPropFloat(entity, Prop_Send, "m_heat");
    SetEntPropFloat(entity, Prop_Send, "m_flModelScale", scale);
}
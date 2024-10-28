/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-06-01 14:25:29
 * @Last Modified time: 2024-09-15 01:05:17
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <paiutils>
#include <left4dhooks>

// int carried[MAXPLAYERS + 1];
public Plugin myinfo =
{
    name = "Test",
    author = "我是派蒙啊",
    description = "",
    version = "",
    url = ""
};

// public void OnPluginStart()
// {
//     RegConsoleCmd("sm_esc", Cmd_ESC);
// }

stock Action Cmd_ESC(int client, int args)
{
    for (int i = 1; i <= MaxClients; i++)
        if (IsSurvivor(i))
            SetEntProp(i, Prop_Send, "m_CollisionGroup", 17);

    return Plugin_Continue;
}

public void OnPlayerRunCmdPre(int client, int buttons)
{
    if (!IsSurvivor(client)) return;

    if (!(buttons & IN_ATTACK)) return;

    for (int i = 0; i <= 2048; i++)
    {
        if (!IsValidEntity(i)) continue;

        bool is_viewmodel = HasEntProp(i, Prop_Send, "m_hWeapon");
        if (!is_viewmodel) continue;

        // static char cls_name[32];
        // GetEntityClassname(i, cls_name, sizeof(cls_name));
        // PrintToChatAll("%s", cls_name);

        int weapon = GetEntPropEnt(i, Prop_Send, "m_hWeapon");
        if (!IsValidEntity(weapon)) continue;
        SetEntProp(weapon, Prop_Data, "m_bLagCompensate", 0);
        SetEntProp(client, Prop_Data, "m_bLagCompensate", 0);
        SetEntProp(client, Prop_Data, "m_bPredictWeapons", 0);
        SetEntProp(i, Prop_Data, "m_bLagCompensate", 0);
    }
}

#include <left4dhooks>
stock bool IsWeaponReadyToFire(int weapon)
{
    float game_time = GetGameTime();
    float atk_time = GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack");
    float interval = atk_time - game_time;

    static char weapon_name[32];
    GetEntityClassname(weapon, weapon_name, sizeof(weapon_name));
    float cycle = L4D2_GetFloatWeaponAttribute(weapon_name, L4D2FWA_CycleTime);
    bool is_ready_to_fire = interval <= cycle;

    // PrintToChatAll("%.2f %.2f %.2f %.2f %d", game_time, atk_time, interval, cycle, is_ready_to_fire);

    return is_ready_to_fire;
}
ConVar PrimarySlot;

static char weapons_cls[17][32] = {
    "weapon_smg",
    "weapon_smg_silenced",
    "weapon_smg_mp5",
    "weapon_shotgun_chrome",
    "weapon_pumpshotgun",
    "weapon_rifle_ak47",
    "weapon_rifle_desert",
    "weapon_rifle_m60",
    "weapon_rifle_sg552",
    "weapon_rifle",
    "weapon_sniper_awp",
    "weapon_sniper_scout",
    "weapon_sniper_military",
    "weapon_hunting_rifle",
    "weapon_autoshotgun",
    "weapon_shotgun_spas",
    "weapon_grenade_launcher",
};

stock void GiveRandomWeapon(int client)
{
    static char weapon_char[64];
    GetConVarString(PrimarySlot, weapon_char, sizeof(weapon_char));
    if (strcmp(weapon_char, "random") != 0) return;
    if (HaveGLorM60(client)) return;

    int current_weapon = GetPlayerWeaponSlot(client, 0);
    if (current_weapon > -1)
        RemovePlayerItem(client, current_weapon);

    int idx = GetRandomInt(0, 16);
    ExecuteCommand(client, "give %s", weapons_cls[idx]);
}

stock bool HaveGLorM60(int client)
{
    char weapon_name[32];
    int weapon = GetPlayerWeaponSlot(client, 0);    // Get weapon ID in primary slot

    if (weapon == -1) return false;
    GetEntityClassname(weapon, weapon_name, sizeof(weapon_name));    // Get weapon class name

    return strcmp(weapon_name, "weapon_rifle_m60") == 0 || strcmp(weapon_name, "weapon_grenade_launcher") == 0;
}

static char target_str[1];

#include <regex>
Regex g_hMyRegex;

public void OnPluginStart()
{
    g_hMyRegex = new Regex("^STEAM_[0-5]:[01]:\\d+$");
}

stock void RegexTest()
{
    // firstly, check if available or not
    if (g_hMyRegex == null) return;

    int result = g_hMyRegex.MatchAll(target_str);
    switch (result)
    {
        case -1:
            PrintToServer("Failed to match");
        case 0:
            PrintToServer("No match found");
        default:
            PrintToServer("Found %d matches", result);
    }

    // if you decide that you will never use it again, remember to delete it otherwise it will case memory leak.
    // delete g_hMyRegex;
}
/*
 * @Author:             派蒙
 * @Last Modified by:   派蒙
 * @Create Date:        2022-04-17 13:12:08
 * @Last Modified time: 2022-04-20 12:48:05
 * @Github:             http://github.com/PaimonQwQ
 */

#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <l4d2tools>
#include <sourcemod>

#define VERSION "2022.04.18"

int
    g_iOffsetAmmo;

StringMap
    g_hWeaponOffsets;

ConVar
    g_hAutoRefill;

public Plugin myinfo =
{
    name = "AutoRefill",
    author = "我是派蒙啊",
    description = "AngelServer的自动装填",
    version = VERSION,
    url = "http://github.com/PaimonQwQ/L4D2-Plugins/AngelBeats"
};

public void OnPluginStart()
{
    HookEvent("weapon_fire", Event_WeaponFire);

    g_hAutoRefill = CreateConVar("angel_autorefill", "0", "开关自动装填");

    g_iOffsetAmmo = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");

    g_hWeaponOffsets = new StringMap();
    g_hWeaponOffsets.SetValue("weapon_rifle", 12);
    g_hWeaponOffsets.SetValue("weapon_smg", 20);
    g_hWeaponOffsets.SetValue("weapon_pumpshotgun", 28);
    g_hWeaponOffsets.SetValue("weapon_shotgun_chrome", 28);
    g_hWeaponOffsets.SetValue("weapon_autoshotgun", 32);
    g_hWeaponOffsets.SetValue("weapon_hunting_rifle", 36);

    //Left4dead2
    g_hWeaponOffsets.SetValue("weapon_rifle_sg552", 12);
    g_hWeaponOffsets.SetValue("weapon_rifle_desert", 12);
    g_hWeaponOffsets.SetValue("weapon_rifle_ak47", 12);
    g_hWeaponOffsets.SetValue("weapon_smg_silenced", 20);
    g_hWeaponOffsets.SetValue("weapon_smg_mp5", 20);
    g_hWeaponOffsets.SetValue("weapon_shotgun_spas", 32);
    g_hWeaponOffsets.SetValue("weapon_sniper_scout", 40);
    g_hWeaponOffsets.SetValue("weapon_sniper_military", 40);
    g_hWeaponOffsets.SetValue("weapon_sniper_awp", 40);
    g_hWeaponOffsets.SetValue("weapon_grenade_launcher", 68);
}

public Action Event_WeaponFire(Event event, const char[] name, bool dont_broadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(!IsSurvivor(client) || IsFakeClient(client) ||
        !IsPlayerAlive(client) || !view_as<bool>(g_hAutoRefill.IntValue))
        return Plugin_Continue;
    if(IsSurvivor(client) && FindConVar("sv_infinite_ammo").IntValue == 0)
    {
        int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        int clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
        int ammo = GetOrSetPlayerAmmo(client, weapon);
        if(ammo > 5)
        {
            SetEntProp(weapon, Prop_Send, "m_iClip1", clip + 1);
            GetOrSetPlayerAmmo(client, weapon, ammo - 1);
        }
    }
    return Plugin_Continue;
}

int GetOrSetPlayerAmmo(int client, int iWeapon, int iAmmo = -1)
{
    static char sWeapon[32];
    GetEdictClassname(iWeapon, sWeapon, sizeof(sWeapon));

    int offset;
    g_hWeaponOffsets.GetValue(sWeapon, offset);

    if( offset )
    {
        if( iAmmo != -1 ) SetEntData(client, g_iOffsetAmmo + offset, iAmmo);
        else return GetEntData(client, g_iOffsetAmmo + offset);
    }

    return 0;
}
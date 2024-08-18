/**
 * @Author: 我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date: 2024-08-11 20:26:27
 * @Last Modified time: 2024-08-16 20:53:29
 * @Github: https://github.com/Paimon-Kawaii
 */
#pragma semicolon 1
#pragma newdecls required

#define DEBUG         1

#define VERSION       "2024.08.11#1"

#define GAMEDATA_FILE "weapon_upgrade"

// #include <dhooks>
#include <sdktools>
#include <sourcemod>

#include <paiutils>

public Plugin myinfo =
{
    name = "Weapon Upgrade",
    author = "我是派蒙啊",
    description = "Weapon Upgrade",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins"
};

Handle g_hSDK_CTerrorGun_AddUpgrade;

public void OnPluginStart()
{
    PrepareSDKCalls();
}

public void OnPlayerRunCmdPre(int client, int buttons)
{
    int old_btns = GetEntProp(client, Prop_Data, "m_nOldButtons");
    if (!IsSurvivor(client) || !(buttons & IN_USE) || (old_btns & IN_USE)) return;

    int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (!IsValidEntity(weapon)) return;
    char name[64];
    GetEntityClassname(weapon, name, sizeof(name));

    // for (int i = 0; i < 3; i++)
    // {
    //     bool r = CTerrorGun_AddUpgrade(weapon, i);
    //     PrintToChatAll("%s, %d: %d", name, i, r);
    // }
    int i = 2;
    bool r = CTerrorGun_AddUpgrade(weapon, i);
    PrintToChatAll("%s, %d: %d", name, i, r);
}

void PrepareSDKCalls()
{
    GameData gameData = new GameData(GAMEDATA_FILE);
    StartPrepSDKCall(SDKCall_Entity);
    if (PrepSDKCall_SetFromConf(gameData, SDKConf_Signature, "CTerrorGun::AddUpgrade"))
    {
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
        PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
        g_hSDK_CTerrorGun_AddUpgrade = EndPrepSDKCall();
        if (g_hSDK_CTerrorGun_AddUpgrade == null)
            LogError("Failed to create SDKCall: \"CTerrorGun::AddUpgrade\"");
    }
    else LogError("Failed to find signature: \"CTerrorGun::AddUpgrade\"");

    delete gameData;
}

// 燃烧：0x001
// 高爆：0x010
// 激光：0x100
bool CTerrorGun_AddUpgrade(int weapon, int upgradeType)
{
    return SDKCall(g_hSDK_CTerrorGun_AddUpgrade, weapon, upgradeType);
}
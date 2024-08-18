/**
 * @Author: 我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date: 2024-08-17 10:25:50
 * @Last Modified time: 2024-08-17 13:54:11
 * @Github: https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#define DEBUG 0

#include <paiutils>

#define VERSION ""

public Plugin myinfo =
{
    name = "wpnapi_test",
    author = "我是派蒙啊",
    description = "",
    version = VERSION,
    url = "https://github.com/Paimon-Kawaii"
};

#define MAXSIZE MaxPlayers + 1

#undef REQUIRE_PLUGIN
#include <weapon_action_api>

public void OnPluginStart()
{
    RegConsoleCmd("sm_ttt", TTT_callback);
}

Action TTT_callback(int client, int params)
{
    int weapon = CreateEntityByName("weapon_rifle");
    DispatchSpawn(weapon);
    float pos[3];
    GetClientEyePosition(client, pos);
    TeleportEntity(weapon, pos);
    int r = EquipPlayerWeapon(client, weapon);
    PrintToChatAll("%N %d", client, r);
    r = Player_SwitchToWeapon(client, 1);
    PrintToChatAll("%N %d", client, r);

    return Plugin_Handled;
}

public Action Player_OnSwitchToWeapon(int client, int weapon, int param)
{
    PrintToChatAll("Switch detect");
    return Plugin_Continue;

    char buffer1[32], buffer2[32];
    int equip = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (IsValidEdict(equip) && IsValidEdict(weapon))
    {
        GetEntityClassname(equip, buffer1, sizeof(buffer1));
        GetEntityClassname(weapon, buffer2, sizeof(buffer2));
    }
    else return Plugin_Continue;

    PrintToChatAll("%N switch %s to %s", client, buffer1, buffer2);
    PrintToChatAll("Handled");

    return Plugin_Handled;
}
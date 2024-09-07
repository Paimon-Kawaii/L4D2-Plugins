/*
 * @Author: 我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date: 2024-08-13 12:46:49
 * @Last Modified time: 2024-08-22 13:37:11
 * @Github: https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#define DEBUG 0

#include <paiutils>

#define VERSION "2024.08.18#23"

public Plugin myinfo =
{
    name = "8+ Players Menu",
    author = "我是派蒙啊",
    description = "8+ Players Menu",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins"
};

#define MAXSIZE       MAXPLAYERS + 1
#define GAMEDATA_FILE "8+PlayersMenu"

#undef REQUIRE_PLUGIN
#include <readyup>

Handle
    g_hSDK_CCSPlayer_Weapon_Switch;

#if DEBUG
DynamicDetour
    g_ddWeaponSwitch;
#endif

bool
    g_bReadyUpAvailable,
    g_bShowPanel[MAXSIZE] = { true, ... };

Panel
    g_hPanel;

public void OnPluginStart()
{
    PrepareSDKCalls();

    HookEvent("player_hurt", Event_OnTrigger);
    HookEvent("player_death", Event_OnTrigger);

    HookEvent("pills_used", Event_OnTrigger);
    HookEvent("heal_success", Event_OnTrigger);
    HookEvent("adrenaline_used", Event_OnTrigger);
    HookEvent("defibrillator_used", Event_OnTrigger);

    HookEvent("player_first_spawn", Event_OnTrigger);
    AddCommandListener(Vote_Callback, "Vote");
}

void Event_OnTrigger(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsSurvivor(client)) return;

    RequestFrame(UpdatePanel);
}

Action Vote_Callback(int client, const char[] command, int argc)
{
    if (g_bReadyUpAvailable && IsInReady())
        return Plugin_Continue;

    char sArg[8];
    GetCmdArg(1, sArg, sizeof(sArg));
    if (strcmp(sArg, "Yes", false) == 0)
        g_bShowPanel[client] = true;
    else if (strcmp(sArg, "No", false) == 0)
        g_bShowPanel[client] = false;

    if (g_bShowPanel[client])
        g_hPanel.Send(client, Panel_SwitchWeaponHandler, MENU_TIME_FOREVER);

    return Plugin_Continue;
}

void UpdatePanel()
{
    if (g_bReadyUpAvailable && IsInReady()) return;

    delete g_hPanel;
    static char hint[64];
    static char buffer[2048];
    g_hPanel = new Panel(GetMenuStyleHandle(MenuStyle_Radio));
    Format(buffer, sizeof(buffer), "▼ 玩家列表: (%d/%d)", GetTeamClientCount(TEAM_SURVIVOR), FindConVar("sv_maxplayers").IntValue);
    g_hPanel.DrawText(buffer);
    g_hPanel.DrawText(" ▶ 使用 F1/F2 开/关面板");
    int count = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsSurvivor(i)) continue;
        GetClientName(i, buffer, sizeof(buffer));
        if (IsPlayerAlive(i))
        {
            Format(hint, sizeof(hint), " %03d HP ", GetPlayerHealth(i, _, true));
            if (IsPlayerIncap(i))
                Format(buffer, sizeof(buffer), "%s(已经躺好了)", buffer);
            else if (IsPlayerOnThirdStrike(i))
                Format(buffer, sizeof(buffer), "%s(即将登机)", buffer);
        }
        else strcopy(hint, sizeof(hint), " 已抵达天国 ");
        Format(buffer, sizeof(buffer), " ▶ [%s] %s", hint, buffer);
        g_hPanel.DrawText(buffer);
        if (++count >= 15) break;
    }
    for (int i = 1; i <= MaxClients; i++)
        if (IsValidClient(i) && !IsFakeClient(i) && g_bShowPanel[i])
            g_hPanel.Send(i, Panel_SwitchWeaponHandler, MENU_TIME_FOREVER);
}

int Panel_SwitchWeaponHandler(Handle panel, MenuAction action, int client, int select)
{
    if (g_bShowPanel[client] && IsValidClient(client))
        g_hPanel.Send(client, Panel_SwitchWeaponHandler, MENU_TIME_FOREVER);
    if (select > 5 || select < 1 || action == MenuAction_Cancel) return 1;
    int weapon = GetPlayerWeaponSlot(client, select - 1);
#if DEBUG
    PrintToChatAll("%d %d", weapon, IsValidEdict(weapon));
#endif
    int equip = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (!IsValidEdict(weapon) || weapon == equip) return 1;
    CCSPlayer_Weapon_Switch(client, weapon);

    return 1;
}

public void OnAllPluginsLoaded()
{
    g_bReadyUpAvailable = LibraryExists("readyup");
}

public void OnLibraryAdded(const char[] name)
{
    if (!strcmp(name, "readyup", false))
        g_bReadyUpAvailable = true;
}

public void OnLibraryRemoved(const char[] name)
{
    if (!strcmp(name, "readyup", false))
        g_bReadyUpAvailable = false;
}

void PrepareSDKCalls()
{
    GameData gameData = new GameData(GAMEDATA_FILE);
    StartPrepSDKCall(SDKCall_Player);
    if (PrepSDKCall_SetFromConf(gameData, SDKConf_Signature, "CCSPlayer::Weapon_Switch"))
    {
        PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
        PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
        g_hSDK_CCSPlayer_Weapon_Switch = EndPrepSDKCall();
        if (g_hSDK_CCSPlayer_Weapon_Switch == null)
            LogError("Failed to create SDKCall: \"CCSPlayer::Weapon_Switch\"");
    }
    else LogError("Failed to find signature: \"CCSPlayer::Weapon_Switch\"");

#if DEBUG
    CreateDetour(gameData, g_ddWeaponSwitch, DTR_CCSPlayer_Weapon_Switch, "L4D2::CCSPlayer::Weapon_Switch", true);
#endif
    delete gameData;
}

#if DEBUG
MRESReturn DTR_CCSPlayer_Weapon_Switch(int pThis, DHookReturn hReturn, DHookParam hParams)
{
    PrintToChatAll("Switch detected %N", pThis);
    PrintToChatAll("%d", hParams.Get(1));
    PrintToChatAll("%d", hParams.Get(2));
    PrintToChatAll("%d", hReturn.Value);

    return MRES_Ignored;
}
#endif

int CCSPlayer_Weapon_Switch(int player, int weapon)
{
    return SDKCall(g_hSDK_CCSPlayer_Weapon_Switch, player, weapon, 0);
}
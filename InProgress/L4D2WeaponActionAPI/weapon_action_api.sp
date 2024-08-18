/**
 * @Author: 我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date: 2024-08-17 08:32:04
 * @Last Modified time: 2024-08-17 14:18:25
 * @Github: https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <dhooks>
#include <sourcemod>

#define GAMEDATA_FILE "weapon_action_api"
#define VERSION       "2024.08.17#37"

public Plugin myinfo =
{
    name = "L4D2 Weapon Action API",
    author = "我是派蒙啊",
    description = "L4D2 Weapon Action API",
    version = VERSION,
    url = "https://github.com/Paimon-Kawaii"
};

public void OnPluginStart()
{
    PrepareSDKCalls();
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("weapon_action_api");
    CreateNativesForwards();
    return APLRes_Success;
}

GlobalForward
    g_fwdOnSwitchToWeapon,
    g_fwdOnSwitchToWeapon_Post;

void CreateNativesForwards()
{
    CreateNative("Player_SwitchToWeapon", NTV_SwitchToWeapon);
    g_fwdOnSwitchToWeapon = new GlobalForward("Player_OnSwitchToWeapon", ET_Event, Param_Cell, Param_Cell, Param_Cell);
    g_fwdOnSwitchToWeapon_Post = new GlobalForward("Player_OnSwitchToWeapon_Post", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
}

int NTV_SwitchToWeapon(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    int slot = GetNativeCell(2);
    int weapon = GetPlayerWeaponSlot(client, slot);
    if (!IsValidEdict(weapon)) return 0;

    return CCSPlayer_Weapon_Switch(client, weapon);
}

Handle
    g_hSDK_CCSPlayer_Weapon_Switch;

DynamicDetour
    g_ddWeaponSwitch_Pre,
    g_ddWeaponSwitch_Post;

void PrepareSDKCalls()
{
    GameData gameData = new GameData(GAMEDATA_FILE);
    StartPrepSDKCall(SDKCall_Player);
    if (PrepSDKCall_SetFromConf(gameData, SDKConf_Signature, "CCSPlayer::Weapon_Switch"))
    {
        PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
        PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
        g_hSDK_CCSPlayer_Weapon_Switch = EndPrepSDKCall();
        if (g_hSDK_CCSPlayer_Weapon_Switch == null)
            LogError("Failed to create SDKCall: \"CCSPlayer::Weapon_Switch\"");
    }
    else LogError("Failed to find signature: \"CCSPlayer::Weapon_Switch\"");

    CreateDetour(gameData, g_ddWeaponSwitch_Pre, DTR_CCSPlayer_Weapon_Switch_Pre, "L4D2::CCSPlayer::Weapon_Switch");
    CreateDetour(gameData, g_ddWeaponSwitch_Post, DTR_CCSPlayer_Weapon_Switch_Post, "L4D2::CCSPlayer::Weapon_Switch", true);

    delete gameData;
}

void CreateDetour(GameData gamedata, DynamicDetour &detour, DHookCallback callback, const char[] name, bool post = false)
{
    detour = DynamicDetour.FromConf(gamedata, name);
    if (!detour) LogError("Failed to load detour \"%s\" signature.", name);

    if (callback != INVALID_FUNCTION && !detour.Enable(post ? Hook_Post : Hook_Pre, callback))
        LogError("Failed to detour \"%s\".", name);
}

MRESReturn DTR_CCSPlayer_Weapon_Switch_Pre(int pThis, DHookReturn hReturn, DHookParam hParams)
{
    Action result = Plugin_Continue;
    Call_StartForward(g_fwdOnSwitchToWeapon);
    Call_PushCell(pThis);
    Call_PushCell(hParams.Get(1));
    Call_PushCell(hParams.Get(2));
    Call_Finish(result);
    if (result != Plugin_Continue && result != Plugin_Changed)
    {
        hReturn.Value = false;
        return MRES_Supercede;
    }
    return MRES_Ignored;
}

MRESReturn DTR_CCSPlayer_Weapon_Switch_Post(int pThis, DHookReturn hReturn, DHookParam hParams)
{
    Call_StartForward(g_fwdOnSwitchToWeapon_Post);
    Call_PushCell(pThis);
    Call_PushCell(hParams.Get(1));
    Call_PushCell(hParams.Get(2));
    Call_Finish();

    return MRES_Ignored;
}

int CCSPlayer_Weapon_Switch(int player, int weapon)
{
    return SDKCall(g_hSDK_CCSPlayer_Weapon_Switch, player, weapon, 0);
}
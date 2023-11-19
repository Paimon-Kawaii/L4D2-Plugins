/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-11-09 12:31:00
 * @Last Modified time: 2023-11-19 22:59:50
 * @Github:             https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#include <dhooks>
#include <sdktools>
#include <paiutils>
#include <sourcemod>
#include <clientprefs>

#define VERSION "2023.11.19"
#define DEBUG 0

#define PunchV 0
#define PunchH 1

ConVar
    g_cvGunPunchV,
    g_cvGunPunchH,
    g_cvControllerEnable;

Handle
    g_hSDK_GetWeaponInfo;

Cookie
    g_ckPunchV,
    g_ckPunchH;

DynamicDetour
    g_ddSetPunchAngle;

StringMap
    g_smWeaponPtrs,
    g_smWeaponIDs;

int
    g_iPunchOffsets[2];

public Plugin myinfo =
{
    name = "ClientViewPunchController",
    author = "我是派蒙啊",
    description = "开枪抖动控制器",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins/MyPlugins"
};


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();
    if(engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

//插件入口
public void OnPluginStart()
{
    RegConsoleCmd("sm_pc", Cmd_PunchMenu, "Punch Menu");
    RegConsoleCmd("sm_punch", Cmd_PunchMenu, "Punch Menu");

    InitValues();
    InitCookie();
    InitConVars();
    InitGameData();

    // Translations
    LoadTranslations("punchcontroller.phrases");
    // Execute cfg
    AutoExecConfig(true, "punch_controller");
}

Action Cmd_PunchMenu(int client, any args)
{
    if(!IsValidClient(client))
        return Plugin_Continue;

    ShowCookieMenu(client);
    return Plugin_Handled;
}

// From Left4DHooks
void InitValues()
{
    // Weapon IDs
    g_smWeaponPtrs = new StringMap();
    g_smWeaponIDs = new StringMap();

    g_smWeaponIDs.SetValue("weapon_none",                        0);
    g_smWeaponIDs.SetValue("weapon_pistol",                      1);
    g_smWeaponIDs.SetValue("weapon_smg",                         2);
    g_smWeaponIDs.SetValue("weapon_pumpshotgun",                 3);
    g_smWeaponIDs.SetValue("weapon_autoshotgun",                 4);
    g_smWeaponIDs.SetValue("weapon_rifle",                       5);
    g_smWeaponIDs.SetValue("weapon_hunting_rifle",               6);
    g_smWeaponIDs.SetValue("weapon_smg_silenced",                7);
    g_smWeaponIDs.SetValue("weapon_shotgun_chrome",              8);
    g_smWeaponIDs.SetValue("weapon_rifle_desert",                9);
    g_smWeaponIDs.SetValue("weapon_sniper_military",             10);
    g_smWeaponIDs.SetValue("weapon_shotgun_spas",                11);
    g_smWeaponIDs.SetValue("weapon_first_aid_kit",               12);
    g_smWeaponIDs.SetValue("weapon_molotov",                     13);
    g_smWeaponIDs.SetValue("weapon_pipe_bomb",                   14);
    g_smWeaponIDs.SetValue("weapon_pain_pills",                  15);
    g_smWeaponIDs.SetValue("weapon_gascan",                      16);
    g_smWeaponIDs.SetValue("weapon_propanetank",                 17);
    g_smWeaponIDs.SetValue("weapon_oxygentank",                  18);
    g_smWeaponIDs.SetValue("weapon_melee",                       19);
    g_smWeaponIDs.SetValue("weapon_chainsaw",                    20);
    g_smWeaponIDs.SetValue("weapon_grenade_launcher",            21);
    // g_smWeaponIDs.SetValue("weapon_ammo_pack",                22); // Unavailable
    g_smWeaponIDs.SetValue("weapon_adrenaline",                  23);
    g_smWeaponIDs.SetValue("weapon_defibrillator",               24);
    g_smWeaponIDs.SetValue("weapon_vomitjar",                    25);
    g_smWeaponIDs.SetValue("weapon_rifle_ak47",                  26);
    g_smWeaponIDs.SetValue("weapon_gnome",                       27);
    g_smWeaponIDs.SetValue("weapon_cola_bottles",                28);
    g_smWeaponIDs.SetValue("weapon_fireworkcrate",               29);
    g_smWeaponIDs.SetValue("weapon_upgradepack_incendiary",      30);
    g_smWeaponIDs.SetValue("weapon_upgradepack_explosive",       31);
    g_smWeaponIDs.SetValue("weapon_pistol_magnum",               32);
    g_smWeaponIDs.SetValue("weapon_smg_mp5",                     33);
    g_smWeaponIDs.SetValue("weapon_rifle_sg552",                 34);
    g_smWeaponIDs.SetValue("weapon_sniper_awp",                  35);
    g_smWeaponIDs.SetValue("weapon_sniper_scout",                36);
    g_smWeaponIDs.SetValue("weapon_rifle_m60",                   37);
    g_smWeaponIDs.SetValue("weapon_tank_claw",                   38);
    g_smWeaponIDs.SetValue("weapon_hunter_claw",                 39);
    g_smWeaponIDs.SetValue("weapon_charger_claw",                40);
    g_smWeaponIDs.SetValue("weapon_boomer_claw",                 41);
    g_smWeaponIDs.SetValue("weapon_smoker_claw",                 42);
    g_smWeaponIDs.SetValue("weapon_spitter_claw",                43);
    g_smWeaponIDs.SetValue("weapon_jockey_claw",                 44);
    g_smWeaponIDs.SetValue("weapon_ammo_spawn",                  54);
}

void InitCookie()
{
    g_ckPunchV = new Cookie("PunchVCookie", "PunchV Settings", CookieAccess_Public);
    g_ckPunchV.SetPrefabMenu(CookieMenu_OnOff_Int, "PUNCH_V", Punch_CookieMenuHandler);
    g_ckPunchH = new Cookie("PunchHCookie", "PunchH Settings", CookieAccess_Public);
    g_ckPunchH.SetPrefabMenu(CookieMenu_OnOff_Int, "PUNCH_H", Punch_CookieMenuHandler);
}

void Punch_CookieMenuHandler(int client, CookieMenuAction action, any info, char[] title, int maxlen)
{
    Format(title, maxlen, "%T", title, client);
}

void InitConVars()
{
    g_cvGunPunchH = FindConVar("z_gun_horiz_punch");
    g_cvGunPunchV = FindConVar("z_gun_vertical_punch");
    g_cvGunPunchH.SetBool(false);
    g_cvGunPunchV.SetBool(false);

    g_cvControllerEnable = CreateConVar("punch_controller_enable", "1", "是否启用开枪抖动控制", FCVAR_NONE, true, 0.0, true, 1.0);

    g_cvGunPunchV.AddChangeHook(ConVarChanged_PunchEnable);
    g_cvGunPunchH.AddChangeHook(ConVarChanged_PunchEnable);
    g_cvControllerEnable.AddChangeHook(ConVarChanged_PunchEnable);
}

void ConVarChanged_PunchEnable(ConVar convar, const char[] oldValue, const char[] newValue)
{
    bool enable = view_as<bool>(StringToInt(newValue));
    if(convar == g_cvControllerEnable)
    {
        g_cvGunPunchH.SetBool(false);
        g_cvGunPunchV.SetBool(!enable);
        DetourSwitch(g_ddSetPunchAngle, DTR_CBasePlayer_SetPunchAngle, enable);
    }
    else if(g_cvControllerEnable.BoolValue && enable)
    {
        g_cvGunPunchV.SetBool(false);
        g_cvGunPunchH.SetBool(false);
    }
}

void InitGameData()
{
    GameData gamedata = new GameData("view_punch");
    if (gamedata == null)
        SetFailState("Gamedata not found: \"view_punch.txt\".");

    // From Left4DHooks
    StartPrepSDKCall(SDKCall_Static);
    if(PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "GetWeaponInfo") == false)
    {
        LogError("Failed to find signature: \"GetWeaponInfo\"");
    }
    else
    {
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
        PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
        g_hSDK_GetWeaponInfo = EndPrepSDKCall();
        if(g_hSDK_GetWeaponInfo == null)
            LogError("Failed to create SDKCall: \"GetWeaponInfo\"");
    }

    CreateDetour(gamedata, DTR_CBasePlayer_SetPunchAngle, "L4D2::CBasePlayer::SetPunchAngle");
    // CreateDetour(gamedata, DTR_CTerrorGun_DoViewPunch, "L4D2::CTerrorGun::DoViewPunch");

    g_iPunchOffsets[0] = gamedata.GetOffset("L4D2FloatWeapon_VerticalPunch");
    g_iPunchOffsets[1] = gamedata.GetOffset("L4D2FloatWeapon_HorizontalPunch");

    delete gamedata;
}

void CreateDetour(GameData gamedata, DHookCallback callback, const char[] name, bool post = false)
{
    g_ddSetPunchAngle = DynamicDetour.FromConf(gamedata, name);
    if(!g_ddSetPunchAngle) LogError("Failed to load detour \"%s\" signature.", name);
    
    if(callback != INVALID_FUNCTION &&
        !g_ddSetPunchAngle.Enable(post ? Hook_Post : Hook_Pre, DTR_CBasePlayer_SetPunchAngle))
        LogError("Failed to detour \"%s\".", name);
}

bool DetourSwitch(DynamicDetour detour, DHookCallback callback, bool enable, bool post = false)
{
    bool result = false;
    if(enable) result = detour.Enable(post ? Hook_Post : Hook_Pre, callback);
    else result = detour.Disable(post ? Hook_Post : Hook_Pre, callback);

    return result;
}

MRESReturn DTR_CBasePlayer_SetPunchAngle(int pThis, DHookParam params)
{
    float ang[3];
#if DEBUG
    DHookGetParamVector(params, 1, ang);
    PrintToChatAll("%N %.2f %.2f %.2f", pThis, ang[0], ang[1], ang[2]);
#endif

    bool venable = view_as<bool>(g_ckPunchV.GetInt(pThis));
    bool henable = view_as<bool>(g_ckPunchH.GetInt(pThis));

    if(!venable && !henable) return MRES_Ignored;

    int weapon = GetEntPropEnt(pThis, Prop_Send, "m_hActiveWeapon");
    char weaponName[64];
    GetEntityClassname(weapon, weaponName, sizeof(weaponName));
    if(venable) ang[0] = GetFloatWeaponPunch(weaponName, PunchV);
    if(henable) ang[1] = GetFloatWeaponPunch(weaponName, PunchH);
    DHookSetParamVector(params, 1, ang);

    return MRES_ChangedHandled;
}

// MRESReturn DTR_CTerrorGun_DoViewPunch(int pThis, DHookParam hParams)
// {
// #if DEBUG
//     char name[64];
//     GetEntityClassname(pThis, name, sizeof(name));
//     int client = DHookGetParam(hParams, 1);
//     PrintToChatAll("%N: %s", client, name);
// #endif

//     return MRES_Supercede;
// }

// From Left4DHooks
float GetFloatWeaponPunch(const char[] weaponName, int index)
{
    int ptr = GetWeaponPointer(weaponName);
    if( ptr != -1 )
    {
        int attr = g_iPunchOffsets[index]; // Offset
        ptr = LoadFromAddress(view_as<Address>(ptr + attr), NumberType_Int32);
    }

    return view_as<float>(ptr);
}

// From Left4DHooks
int GetWeaponPointer(const char[] weaponName)
{
    int ptr;
    if(g_smWeaponPtrs.GetValue(weaponName, ptr) == false)
    {
        if(g_smWeaponIDs.GetValue(weaponName, ptr) == false)
        {
            LogError("Invalid weapon name (%s) or weapon unavailable (%d)", weaponName, ptr);
            return -1;
        }

        //PrintToServer("#### CALL g_hSDK_GetWeaponInfo");
        if(ptr) ptr = SDKCall(g_hSDK_GetWeaponInfo, ptr);
        if(ptr) g_smWeaponPtrs.SetValue(weaponName, ptr);
    }

    if(ptr) return ptr;
    return -1;
}
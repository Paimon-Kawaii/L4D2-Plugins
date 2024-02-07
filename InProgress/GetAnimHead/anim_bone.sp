/*
 * @Author: 我是派蒙啊
 * @Last Modified by: 我是派蒙啊
 * @Create Date: 2024-02-06 15:18:34
 * @Last Modified time: 2024-02-07 17:04:20
 * @Github: https://github.com/Paimon-Kawaii
 */

#include <paiutils>
#include <sdktools>
#include <sourcemod>
#include <anim_bone>

#define GAMEDATA_FILE "anim_bone"

#define DEBUG         0
#define VERSION       "2024-02-07"

public Plugin myinfo =
{
    name = "AnimationBone",
    author = "我是派蒙啊",
    description = "Get animation bone",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins"
};

#if DEBUG
    #include <dhooks>
#endif

static const int
    g_iZombieBones[][] = {
        {14,  13, 12, 18, 22, 0, 1,  5,  3,  7 }, // Smoker
        { 14, 13, 12, 18, 22, 0, 1,  5,  3,  7 }, // Boomer
        { 14, 13, 12, 18, 22, 0, 1,  5,  3,  7 }, // Hunter
        { 7,  5,  2,  19, 38, 0, 58, 63, 59, 64}, // Spitter
        { 7,  5,  2,  11, 30, 0, 47, 51, 48, 52}, // Jockey
        { 15, 5,  2,  19, 8,  0, 10, 13, 11, 14}  // Charger
}

int GetZombieBone(int zombie, Bone_Type bone_type)
{
    if (!IsInfected(zombie))
        return INVALID_BONE;

    int zclass = GetZombieClass(zombie);
    if (zclass > ZC_CHARGER) return INVALID_BONE;
    int type = view_as<int>(bone_type);

    return g_iZombieBones[zclass - 1][type];
}

Handle
    g_hCBaseAnimating_LookupBone,
    g_hCBaseAnimating_GetBonePosition;

#if DEBUG
DynamicDetour g_ddLookupBone;
#endif

public void OnPluginStart()
{
    GameData gamedata = new GameData(GAMEDATA_FILE);

    StartPrepSDKCall(SDKCall_Entity);
    if (PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CBaseAnimating::LookupBone"))
    {
        PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);

        PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

        g_hCBaseAnimating_LookupBone = EndPrepSDKCall();
    }
    else ThrowError("Failed to load signature: \"CBaseAnimating::LookupBone\"");

    StartPrepSDKCall(SDKCall_Entity);
    if (PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CBaseAnimating::GetBonePosition"))
    {
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
        PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
        PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);

        PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

        g_hCBaseAnimating_GetBonePosition = EndPrepSDKCall();
    }
    else ThrowError("Failed to load signature: \"CBaseAnimating::GetBonePosition\"");

#if DEBUG
    CreateDetour(gamedata, g_ddLookupBone, DTR_CBaseAnimating_LookupBone, "L4D2::CBaseAnimating::LookupBone", true);
#endif

    delete gamedata;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("anim_bone");
    CreateNative("L4D_GetZombieBone", Native_GetZombieBone);
    CreateNative("L4D_GetBoneByName", Native_GetBoneByName);
    CreateNative("L4D_GetBonePosition", Native_GetBonePosition);

    return APLRes_Success;
}

// 注册Native
int Native_GetZombieBone(Handle plugin, int numParams)
{
    return GetZombieBone(GetNativeCell(1), view_as<Bone_Type>(GetNativeCell(2)));
}

int Native_GetBoneByName(Handle plugin, int numParams)
{
    int client = GetNativeCell(1), length;
    int result = GetNativeStringLength(2, length);
    if (result != SP_ERROR_NONE) length = 32;
    char[] buffer = new char[length];
    GetNativeString(2, buffer, length);

    return SDKCall_CBaseAnimating_LookupBone(client, buffer);
}

int Native_GetBonePosition(Handle plugin, int numParams)
{
    int client = GetNativeCell(1), bone = GetNativeCell(2);

    static float origin[3], angle[3];
    SDKCall_CBaseAnimating_GetBonePosition(client, bone, origin, angle);
    if (!IsNativeParamNullVector(3)) SetNativeArray(3, origin, 3);
    if (!IsNativeParamNullVector(4)) SetNativeArray(3, angle, 3);

    return 0;
}

/* bone_name, only worked on linux server
 ValveBiped.Bip01_Pelvis - Root
 ValveBiped.Bip01_L_Thigh - 左腿
 ValveBiped.Bip01_R_Thigh - 右腿
 ValveBiped.Bip01_L_Foot - 左脚
 ValveBiped.Bip01_R_Foot - 右脚
 ValveBiped.Bip01_L_Hand - 左手
 ValveBiped.Bip01_R_Hand - 右手
 ValveBiped.Bip01_Head1 - 头
 ValveBiped.Bip01_Neck1 - 脖子
*/
// Only worked on linux server...
int SDKCall_CBaseAnimating_LookupBone(int client, const char[] bone_name)
{
    return SDKCall(g_hCBaseAnimating_LookupBone, client, bone_name);
}

void SDKCall_CBaseAnimating_GetBonePosition(int client, int bone, float origin[3], float angle[3])
{
    SDKCall(g_hCBaseAnimating_GetBonePosition, client, bone, origin, angle);
}

#if DEBUG
MRESReturn DTR_CBaseAnimating_LookupBone(int pThis, DHookReturn hReturn, DHookParam hParams)
{
    static char a1[128];
    hParams.GetString(1, a1, sizeof(a1));
    LogMessage("dtr: %d %d %s", pThis, hReturn.Value, a1);
    PrintToChatAll("dtr: %d %d %s", pThis, hReturn.Value, a1);

    return MRES_Ignored;
}

void CreateDetour(GameData gamedata, DynamicDetour &detour, DHookCallback callback, const char[] name, bool post = false)
{
    detour = DynamicDetour.FromConf(gamedata, name);
    if (!detour) LogError("Failed to load detour \"%s\" signature.", name);

    if (callback != INVALID_FUNCTION && !detour.Enable(post ? Hook_Post : Hook_Pre, callback))
        LogError("Failed to detour \"%s\".", name);
}
#endif
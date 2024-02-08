/*
 * @Author: 我是派蒙啊
 * @Last Modified by: 我是派蒙啊
 * @Create Date: 2024-02-06 15:18:34
 * @Last Modified time: 2024-02-08 13:33:23
 * @Github: https://github.com/Paimon-Kawaii
 */

#include <sdktools>
#include <sourcemod>

#include <paiutils>
#include <l4d_anim>

#define LIBRARY_NAME  "l4d_anim"
#define GAMEDATA_FILE "l4d_anim"

#define DEBUG         0
#define VERSION       "2024.02.08"

public Plugin myinfo =
{
    name = "L4D Animation",
    author = "我是派蒙啊",
    description = "L4D animation functions",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins"
};

#if DEBUG
    #include <dhooks>
#endif

// 1-LFoot, 2-RFoot, 3-Mouth, 4-Eyes SMOKER
// 1-Mouth, 2-Eyes,  3-LFoot, 4-RFoot BOOMER
// 1-Chest, 2-LFoot, 3-RFoot, 4-LHand, 5-RHand, 6-Eyes HUNTER
// 1-LFoot, 2-RFoot, 3-RHand?, 4-RHand?, 5-Mouth, 6-Eyes SPITTER
// 1-Eyes, 2-LFoot, 3-RFoot,  4-RHand, 5-RHand? JOCKEY
// 1-LFoot, 2-RFoot, 3-RHand, 4-RHand?, 5-Body, 6-Eyes CHARGER
static const int
    g_iZombieAttachments[][] = {
        {4,  3, 0, 0, 0, 0, 1, 2}, // Smoker
        { 2, 1, 0, 0, 0, 0, 3, 4}, // Boomer
        { 6, 0, 1, 4, 5, 0, 2, 3}, // Hunter
        { 6, 5, 0, 0, 3, 0, 1, 2}, // Spitter
        { 1, 0, 0, 0, 4, 0, 2, 3}, // Jockey
        { 6, 0, 0, 0, 3, 5, 1, 2}  // Charger
},
    g_iZombieBones[][] = {
        { 14, 13, 12, 18, 22, 0, 1, 5, 3, 7 },     // Smoker
        { 14, 13, 12, 18, 22, 0, 1, 5, 3, 7 },     // Boomer
        { 14, 13, 12, 18, 22, 0, 1, 5, 3, 7 },     // Hunter
        { 7, 5, 2, 19, 38, 0, 58, 63, 59, 64 },    // Spitter
        { 7, 5, 2, 11, 30, 0, 47, 51, 48, 52 },    // Jockey
        { 15, 5, 2, 19, 8, 0, 10, 13, 11, 14 }     // Charger
    };

int GetZombieBone(int zombie, Bone_Type bone_type)
{
    if (!IsInfected(zombie))
        return INVALID_BONE;

    int zclass = GetZombieClass(zombie);
    if (zclass > ZC_CHARGER) return INVALID_BONE;
    int type = view_as<int>(bone_type);

    return g_iZombieBones[zclass - 1][type];
}

int GetZombieAttachment(int zombie, Attachment_Type attach_type)
{
    if (!IsInfected(zombie))
        return INVALID_ATTACHMENT;

    int zclass = GetZombieClass(zombie);
    if (zclass > ZC_CHARGER) return INVALID_ATTACHMENT;
    int type = view_as<int>(attach_type);

    return g_iZombieAttachments[zclass - 1][type];
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
    RegPluginLibrary(LIBRARY_NAME);
    CreateNative("L4D_GetZombieBone", Native_GetZombieBone);
    CreateNative("L4D_GetBoneByName", Native_GetBoneByName);
    CreateNative("L4D_GetBonePosition", Native_GetBonePosition);
    CreateNative("L4D_GetZombieAttachment", Native_GetZombieAttachment);

    return APLRes_Success;
}

// 注册Native
int Native_GetZombieBone(Handle plugin, int numParams)
{
    return GetZombieBone(GetNativeCell(1), view_as<Bone_Type>(GetNativeCell(2)));
}

int Native_GetZombieAttachment(Handle plugin, int numParams)
{
    return GetZombieAttachment(GetNativeCell(1), view_as<Attachment_Type>(GetNativeCell(2)));
}

int Native_GetBoneByName(Handle plugin, int numParams)
{
    int entity = GetNativeCell(1);
    if (!IsValidEntity(entity)) return INVALID_BONE;

    int length, result = GetNativeStringLength(2, length);
    if (result != SP_ERROR_NONE) length = 32;

    char[] buffer = new char[length];
    GetNativeString(2, buffer, length);

    return SDKCall_CBaseAnimating_LookupBone(entity, buffer);
}

int Native_GetBonePosition(Handle plugin, int numParams)
{
    int client = GetNativeCell(1), bone = GetNativeCell(2);
    if (!IsValidClient(client) || bone == INVALID_BONE) return 0;

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
/*
 * @Author: 我是派蒙啊
 * @Last Modified by: 我是派蒙啊
 * @Create Date: 2024-02-17 11:15:10
 * @Last Modified time: 2024-03-26 11:58:40
 * @Github: https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#define DEBUG 1
#if DEBUG
    #define LOGFILE "addons/sourcemod/logs/si_pool_log.txt"
#endif

#define VERSION       "2024.03.26#101"

#define LIBRARY_NAME  "si_pool"
#define GAMEDATA_FILE "si_pool"

#include <si_pool>

#include <sdktools>
#include <sourcemod>

#include <paiutils>

public Plugin myinfo =
{
    name = "Special Infected Bot Client Pool",
    author = "我是派蒙啊",
    description = "A Client Pool for SI Bots, used to avoid lots of CreateFakeClient() operation",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins"
};

#define MAXSIZE MAXPLAYERS + 1

static char g_sZombieClass[][] = {
    "Smoker",
    "Boomer",
    "Hunter",
    "Spitter",
    "Jockey",
    "Charger",
    "Witch",
    "Tank",
};

#define DEAD 1
void ResetDeadZombie(int client)
{
    SetStateTransition(client, STATE_ACTIVE);
    SetEntProp(client, Prop_Send, "m_isGhost", true);
    SetEntProp(client, Prop_Send, "deadflag", DEAD);
    SetEntProp(client, Prop_Send, "m_lifeState", DEAD);
    SetEntProp(client, Prop_Send, "m_iPlayerState", DEAD);
    SetEntProp(client, Prop_Send, "m_zombieState", DEAD);
    SetEntProp(client, Prop_Send, "m_iObserverMode", DEAD);
    SetEntProp(client, Prop_Send, "movetype", MOVETYPE_NOCLIP);
}

#define ALIVE                0
#define FSOLID_NOT_STANDABLE 0x10
void InitializeSpecial(int ent, const float vPos[3] = NULL_VECTOR, const float vAng[3] = NULL_VECTOR, bool bSpawn = false)
{
    if (bSpawn) DispatchSpawn(ent);
    else RespawnPlayer(ent);

    if (GetClientTeam(ent) != TEAM_INFECTED) ChangeClientTeam(ent, TEAM_INFECTED);
    SetEntProp(ent, Prop_Send, "m_usSolidFlags", FSOLID_NOT_STANDABLE);
    SetEntProp(ent, Prop_Send, "movetype", MOVETYPE_WALK);
    SetEntProp(ent, Prop_Send, "deadflag", ALIVE);
    SetEntProp(ent, Prop_Send, "m_lifeState", ALIVE);
    SetEntProp(ent, Prop_Send, "m_iObserverMode", ALIVE);
    SetEntProp(ent, Prop_Send, "m_iPlayerState", ALIVE);
    SetEntProp(ent, Prop_Send, "m_zombieState", ALIVE);
    SetEntProp(ent, Prop_Send, "m_isGhost", false);
    TeleportEntity(ent, vPos, vAng, NULL_VECTOR);
}

#define ZC_COUNT 6
Handle
    // g_hSDK_CTerrorPlayer_SetClass,
    g_hSDK_CBaseAbility_CreateForPlayer,
    g_hSDK_CCSPlayer_State_Transition,
    g_hSDK_CTerrorPlayer_RoundRespawn,
    g_hSDK_NextBotCreatePlayerBot[ZC_COUNT];

static SIPool g_hSIPool;
static int g_iLastDeadTypeIdx = -1;
static int g_iPoolSize[ZC_COUNT] = { 0, ... };
static int g_iPoolArray[ZC_COUNT][MAXSIZE] = {
    {-1,  ...},
    { -1, ...},
    { -1, ...},
    { -1, ...},
    { -1, ...},
    { -1, ...},
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary(LIBRARY_NAME);
    g_hSIPool = view_as<SIPool>(myself);

    return APLRes_Success;
}

public void OnPluginStart()
{
    CreateNatives();

    HookEvents();
    PrepareSDKCalls();
}

public bool OnClientConnect(int client)
{
    if (IsFakeClient(client)) return true;
    if (g_iLastDeadTypeIdx == -1) return true;

    int size = g_iPoolSize[g_iLastDeadTypeIdx];
    if (size > 0)
    {
        KickClient(g_iPoolArray[g_iLastDeadTypeIdx][size - 1]);
        OnPoolSizeChanged(size, size - 1, g_iLastDeadTypeIdx);
        g_iPoolSize[g_iLastDeadTypeIdx]--;
    }

    return true;
}

void CreateNatives()
{
    CreateNative("SIPool.Instance", Native_SIPool_Instance_get);

    CreateNative("SIPool.RequestSIBot", Native_SIPool_RequestSIBot);
    CreateNative("SIPool.ReturnSIBot", Native_SIPool_ReturnSIBot);
}

any Native_SIPool_Instance_get(Handle plugin, int numParams)
{
    return g_hSIPool;
}

any Native_SIPool_RequestSIBot(Handle plugin, int numParams)
{
    int zclass_idx = GetNativeCell(2) - 1;
    int size = g_iPoolSize[zclass_idx];
    if (size < 1)
    {
#if DEBUG
        static bool log = false;
        if (!log)
        {
            LogToFile(LOGFILE, "[SIPool] Pool empty or not sized !");
            LogToFile(LOGFILE, "[SIPool] SIPool will auto set size to 1 !");
            LogToFile(LOGFILE, "[SIPool] This log only showed once.");
            log = true;
        }
#endif
        OnPoolSizeChanged(0, 1, zclass_idx);
        g_iPoolSize[zclass_idx] = 1;
    }

    int index = 1;
    size = g_iPoolSize[zclass_idx];
    int bot = g_iPoolArray[zclass_idx][size - index];
    while (!(IsValidClient(bot) && IsFakeClient(bot) && IsGhost(bot)) && ++index <= size)
        bot = g_iPoolArray[zclass_idx][size - index];
    if (index > size && !(IsValidClient(bot) && IsFakeClient(bot) && IsGhost(bot)))
    {
#if DEBUG
        LogToFile(LOGFILE, "[SIPool] No SI available !");
#endif
        OnPoolSizeChanged(size, 0, zclass_idx);
        g_iPoolSize[zclass_idx] = 0;

        return -1;
    }

    static float origin[3], angle[3];
    bool bPos = !IsNativeParamNullVector(3), bAngle = !IsNativeParamNullVector(4);
    if (bPos) GetNativeArray(3, origin, 3);
    if (bAngle) GetNativeArray(4, angle, 3);

    if (bPos && bAngle) InitializeSpecial(bot, origin, angle);
    else if (bPos) InitializeSpecial(bot, origin);
    else if (bAngle) InitializeSpecial(bot, _, angle);
    else InitializeSpecial(bot);
    // SetClass(bot, zclass_idx + 1);
    SetClientName(bot, g_sZombieClass[zclass_idx]);

    Event event = CreateEvent("player_spawn", true);
    if (event != INVALID_HANDLE)
    {
        event.SetInt("userid", GetClientUserId(bot));
        event.Fire();
    }

    OnPoolSizeChanged(size, size - index, zclass_idx);
    g_iPoolSize[zclass_idx] -= index;

#if DEBUG
    LogToFile(LOGFILE, "[SIPool] SI request: %d, type: %d", bot, zclass_idx + 1);
#endif

    return bot;
}

any Native_SIPool_ReturnSIBot(Handle plugin, int numParams)
{
    int bot = GetNativeCell(2);
    if (!(IsInfected(bot) && IsFakeClient(bot) && IsPlayerAlive(bot)))
    {
#if DEBUG
        LogToFile(LOGFILE, "[SIPool] SI is not available!");
#endif
        return false;
    }
    ForcePlayerSuicide(bot);

    return true;
}

void OnPoolSizeChanged(int iOldPoolSize, int iNewPoolSize, int zclass_idx)
{
    if (GetClientCount(false) >= MaxClients) return;

#if DEBUG
    LogToFile(LOGFILE, "[SIPool] SI size change: %d -> %d of %d pool", iOldPoolSize, iNewPoolSize, zclass_idx);
#endif

    bool add;
    int idx_min, idx_max;
    if (iOldPoolSize < iNewPoolSize)
    {
        idx_min = iOldPoolSize;
        idx_max = iNewPoolSize;
        add = true;
    }
    if (!add) return;

    for (int i = idx_min; i < idx_max; i++)
    {
        int bot = CreateSIBot(zclass_idx);
        if (bot == -1)
        {
            int max_count_class = 0;
            for (int v = 0, count = 0; v < ZC_COUNT; v++)
                if (count < g_iPoolSize[v])
                {
                    count = g_iPoolSize[v];
                    max_count_class = v;
                }
            KickClient(g_iPoolArray[max_count_class][g_iPoolSize[max_count_class]--], "Kicked because client full.");

            bot = CreateSIBot(zclass_idx);
            if (bot == -1)
            {
                LogError("[SIPool] SI create failed for the unknow reason ?!");
                break;
            }
        }
        g_iPoolArray[zclass_idx][i] = bot;
        InitializeSpecial(bot, _, _, true);
        ResetDeadZombie(bot);
#if DEBUG
        LogToFile(LOGFILE, "[SIPool] SI create: %d", bot);
#endif
    }
}

void HookEvents()
{
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("round_start", Event_RoundStart);
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!(IsInfected(client) && IsFakeClient(client)) || IsTank(client)) return;

#if DEBUG
    LogToFile(LOGFILE, "[SIPool] SI dead: %d", client);
#endif

    // Return bot;
    g_iLastDeadTypeIdx = GetZombieClass(client) - 1;
    g_iPoolArray[g_iLastDeadTypeIdx][g_iPoolSize[g_iLastDeadTypeIdx]++] = client;
    ResetDeadZombie(client);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    for (int i = 0; i < ZC_COUNT; i++)
    {
        g_iPoolSize[i] = 0;
        for (int v = 0; v < MAXSIZE; v++)
            g_iPoolArray[i][v] = -1;
    }
    g_iLastDeadTypeIdx = -1;
}

void PrepareSDKCalls()
{
    GameData hGameData = new GameData(GAMEDATA_FILE);
    Address pReplaceWithBot = hGameData.GetAddress("NextBotCreatePlayerBot.jumptable");
    if (pReplaceWithBot != Address_Null && LoadFromAddress(pReplaceWithBot, NumberType_Int8) == 0x68)
        PrepWindowsCreateBotCalls(pReplaceWithBot);
    else
        PrepLinuxCreateBotCalls(hGameData);

    // StartPrepSDKCall(SDKCall_Player);
    // if (PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::SetClass"))
    // {
    //     PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    //     g_hSDK_CTerrorPlayer_SetClass = EndPrepSDKCall();
    //     if (g_hSDK_CTerrorPlayer_SetClass == null)
    //         LogError("Failed to create SDKCall: \"CTerrorPlayer::SetClass\"");
    // }
    // else LogError("Failed to find signature: \"CTerrorPlayer::SetClass\"");

    StartPrepSDKCall(SDKCall_Static);
    if (PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CBaseAbility::CreateForPlayer"))
    {
        PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
        PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
        g_hSDK_CBaseAbility_CreateForPlayer = EndPrepSDKCall();
        if (g_hSDK_CBaseAbility_CreateForPlayer == null)
            LogError("Failed to create SDKCall: \"CBaseAbility::CreateForPlayer\"");
    }
    else LogError("Failed to find signature: \"CBaseAbility::CreateForPlayer\"");

    StartPrepSDKCall(SDKCall_Player);
    if (PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CCSPlayer::State_Transition"))
    {
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
        g_hSDK_CCSPlayer_State_Transition = EndPrepSDKCall();
        if (g_hSDK_CCSPlayer_State_Transition == null)
            LogError("Failed to create SDKCall: \"CCSPlayer::State_Transition\"");
    }
    else LogError("Failed to find signature: \"CCSPlayer::State_Transition\"");

    StartPrepSDKCall(SDKCall_Player);
    if (PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::RoundRespawn"))
    {
        g_hSDK_CTerrorPlayer_RoundRespawn = EndPrepSDKCall();
        if (g_hSDK_CTerrorPlayer_RoundRespawn == null)
            LogError("Failed to create SDKCall: \"CTerrorPlayer::RoundRespawn\"");
    }
    else LogError("Failed to find signature: \"CTerrorPlayer::RoundRespawn\"");

    delete hGameData;
}

// #define HUNTER_ADDR  0
// #define JOCKEY_ADDR  12
// #define SPITTER_ADDR 24
// #define CHARGER_ADDR 36
// #define SMOKER_ADDR  48
// #define BOOMER_ADDR  60
// #define TANK_ADDR    72
static int g_iZombieAddr[ZC_COUNT] = {
    48, 60, 0, 24, 12, 36
};
void PrepWindowsCreateBotCalls(Address pBaseAddr)
{
#if DEBUG
    TestName(pBaseAddr);
#endif
    for (int i = 0; i < ZC_COUNT; i++)
    {
        Address pJumpAddr = pBaseAddr + view_as<Address>(g_iZombieAddr[i]);
        Address pFuncRefAddr = pJumpAddr + view_as<Address>(6);
        int funcRelOffset = LoadFromAddress(pFuncRefAddr, NumberType_Int32);
        Address pCallOffsetBase = pJumpAddr + view_as<Address>(10);
        Address pNextBotCreatePlayerBotTAddr = pCallOffsetBase + view_as<Address>(funcRelOffset);

        StartPrepSDKCall(SDKCall_Static);
        if (!PrepSDKCall_SetAddress(pNextBotCreatePlayerBotTAddr))
            SetFailState("Unable to find NextBotCreatePlayer<Jockey> address in memory.");
        PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
        PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
        g_hSDK_NextBotCreatePlayerBot[i] = EndPrepSDKCall();
    }
}

void PrepLinuxCreateBotCalls(GameData hGameData = null)
{
    static char signature_name[32];
    for (int i = 0; i < ZC_COUNT; i++)
    {
        Format(signature_name, sizeof(signature_name), "NextBotCreatePlayerBot<%s>", g_sZombieClass[i]);
        StartPrepSDKCall(SDKCall_Static);
        if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, signature_name))
            SetFailState("Failed to find signature: %s", signature_name);
        PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
        PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
        g_hSDK_NextBotCreatePlayerBot[i] = EndPrepSDKCall();
    }
}

#if DEBUG
void TestName(Address pBaseAddr)
{
    for (int i = 0; i < 7; i++)
    {
        Address pCaseBase = pBaseAddr + view_as<Address>(i * 12);
        Address pSIStringAddr = view_as<Address>(LoadFromAddress(pCaseBase + view_as<Address>(1), NumberType_Int32));
        static char SIName[32];
        LoadStringFromAddress(pSIStringAddr, SIName, sizeof(SIName));
        LogToFile(LOGFILE, "[SIPool] Found \"%s\"(%d) in memory.", SIName, i);
    }
}

void LoadStringFromAddress(Address pAddr, char[] buffer, int maxlength)
{
    int i;
    char val;
    while (i < maxlength)
    {
        val = LoadFromAddress(pAddr + view_as<Address>(i), NumberType_Int8);
        if (val == 0)
        {
            buffer[i] = '\0';
            break;
        }
        buffer[i++] = val;
    }
    buffer[maxlength - 1] = '\0';
}
#endif

// #define ABILITY_TRYTIMES 3
// void SetClass(int client, int zombieClass)
// {
//     int weapon = GetPlayerWeaponSlot(client, 0);
//     if (weapon != -1)
//     {
//         RemovePlayerItem(client, weapon);
//         RemoveEntity(weapon);
//     }

//     int ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
//     if (ability != -1) RemoveEntity(ability);
//     ability = -1;

//     SDKCall(g_hSDK_CTerrorPlayer_SetClass, client, zombieClass);

//     for (int count = 0; count < ABILITY_TRYTIMES && ability == -1; count++)
//         ability = SDKCall(g_hSDK_CBaseAbility_CreateForPlayer, client);

//     if (ability != -1) SetEntPropEnt(client, Prop_Send, "m_customAbility", ability);
//     else LogToFile(LOGFILE, "[SIPool] Failed to create ability for %N after %d times tried.", client, ABILITY_TRYTIMES);
// }

void SetStateTransition(int client, int state)
{
    SDKCall(g_hSDK_CCSPlayer_State_Transition, client, state);
}

void RespawnPlayer(int client)
{
    SDKCall(g_hSDK_CTerrorPlayer_RoundRespawn, client);
}

int CreateSIBot(int zclass_idx)
{
    return SDKCall(g_hSDK_NextBotCreatePlayerBot[zclass_idx], g_sZombieClass[zclass_idx]);
}
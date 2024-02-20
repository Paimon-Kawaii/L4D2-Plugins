/*
 * @Author: 我是派蒙啊
 * @Last Modified by: 我是派蒙啊
 * @Create Date: 2024-02-17 11:15:10
 * @Last Modified time: 2024-02-20 14:42:17
 * @Github: https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#define DEBUG         0

#define VERSION       "2024.02.20#12"

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

void ResetDeadZombie(int client)
{
    SetStateTransition(client, STATE_ACTIVE);
    CreateTimer(0.1, Timer_RestDeadZombie, client, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_RestDeadZombie(Handle timer, int client)
{
    if (!IsValidClient(client)) return Plugin_Stop;

    RespawnPlayer(client);
    SetEntProp(client, Prop_Send, "m_isGhost", true);
    SetEntProp(client, Prop_Send, "m_lifeState", true);
    SetEntProp(client, Prop_Send, "movetype", MOVETYPE_NOCLIP);

#if DEBUG
    LogMessage("[SIPool] Dead SI(%d) reset, is alive: %d", client, IsPlayerAlive(client));
#endif

    return Plugin_Stop;
}

#define FSOLID_NOT_STANDABLE 0x10
void InitializeSpecial(int ent, const float vPos[3] = NULL_VECTOR, const float vAng[3] = NULL_VECTOR, bool bSpawn = false)
{
    ChangeClientTeam(ent, TEAM_INFECTED);
    SetEntProp(ent, Prop_Send, "m_usSolidFlags", FSOLID_NOT_STANDABLE);
    SetEntProp(ent, Prop_Send, "movetype", MOVETYPE_WALK);
    SetEntProp(ent, Prop_Send, "deadflag", false);
    SetEntProp(ent, Prop_Send, "m_lifeState", false);
    SetEntProp(ent, Prop_Send, "m_iObserverMode", false);
    SetEntProp(ent, Prop_Send, "m_iPlayerState", false);
    SetEntProp(ent, Prop_Send, "m_zombieState", false);
    SetEntProp(ent, Prop_Send, "m_isGhost", false);
    if (bSpawn) DispatchSpawn(ent);
    TeleportEntity(ent, vPos, vAng, NULL_VECTOR);
}

Handle
    g_hSDK_CTerrorPlayer_SetClass,
    g_hSDK_CBaseAbility_CreateForPlayer,
    g_hSDK_CCSPlayer_State_Transition,
    g_hSDK_CTerrorPlayer_RoundRespawn,
    g_hSDK_NextBotCreatePlayerBot_Hunter;

static SIPool g_hSIPool;
static int g_iPoolSize;
static int g_iPoolArray[MAXSIZE] = { -1, ... };

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
    if (g_iPoolSize && g_iPoolSize + GetClientCount() >= MaxClients)
    {
        KickClient(g_iPoolArray[g_iPoolSize - 1]);
        OnPoolSizeChanged(g_iPoolSize, g_iPoolSize - 1);
        g_iPoolSize--;
    }

    return true;
}

public void OnClientDisconnect(int client)
{
    if (IsFakeClient(client)) return;

    OnPoolSizeChanged(g_iPoolSize, g_iPoolSize + 1);
    g_iPoolSize++;
}

void RecoverSIPool()
{
    OnPoolSizeChanged(0, g_iPoolSize);
}

void CreateNatives()
{
    // CreateNative("SIPool.Instance.get", Native_SIPool_Instance_get);
    CreateNative("SIPool.Instance", Native_SIPool_Instance_get);
    CreateNative("SIPool.Size.get", Native_SIPool_Size_get);

#if SIZABLE
    CreateNative("SIPool.Narrow", Native_SIPool_Narrow);
    CreateNative("SIPool.Expand", Native_SIPool_Expand);
    CreateNative("SIPool.Resize", Native_SIPool_Resize);
#endif

    CreateNative("SIPool.RequestSIBot", Native_SIPool_RequestSIBot);
    CreateNative("SIPool.ReturnSIBot", Native_SIPool_ReturnSIBot);
}

any Native_SIPool_Instance_get(Handle plugin, int numParams)
{
    return g_hSIPool;
}

any Native_SIPool_Size_get(Handle plugin, int numParams)
{
    return g_iPoolSize;
}

#if SIZABLE
any Native_SIPool_Narrow(Handle plugin, int numParams)
{
    int narrow = GetNativeCell(2);
    if (narrow < 1)
    {
        LogMessage("[SIPool] Narrow size must greater than 1 !");
        return 0;
    }
    int size = g_iPoolSize - narrow;

    size = size > 0 ? size : 0;
    OnPoolSizeChanged(g_iPoolSize, size);
    g_iPoolSize = size;

    return 0;
}

any Native_SIPool_Expand(Handle plugin, int numParams)
{
    int expand = GetNativeCell(2);
    if (expand < 1)
    {
        LogMessage("[SIPool] Expand size must greater than 1 !");
        return 0;
    }

    int size = g_iPoolSize + expand;

    if (size > MaxClients)
    {
        LogMessage("[SIPool] Size too much !");
        return 0;
    }

    OnPoolSizeChanged(g_iPoolSize, size);
    g_iPoolSize = size;

    return 0;
}

any Native_SIPool_Resize(Handle plugin, int numParams)
{
    int size = GetNativeCell(2);
    if (size < 0)
    {
        LogMessage("[SIPool] Resize must greater than 0 !");
        return 0;
    }

    if (size > MAXSIZE)
    {
        LogMessage("[SIPool] Size too much ! %d", size);
        return 0;
    }

    OnPoolSizeChanged(g_iPoolSize, size);
    g_iPoolSize = size;

    return 0;
}
#endif

any Native_SIPool_RequestSIBot(Handle plugin, int numParams)
{
    static bool log = false;
    if (g_iPoolSize < 1)
    {
        if (!log)
        {
            LogMessage("[SIPool] Pool empty or not sized !");
            LogMessage("[SIPool] SIPool will auto set size to 1 !");
            LogMessage("[SIPool] This log only showed once.");
            log = true;
        }
        OnPoolSizeChanged(g_iPoolSize, g_iPoolSize + 1);
        g_iPoolSize++;
    }

    int index = 1;
    int zclass = GetNativeCell(2);
    int bot = g_iPoolArray[g_iPoolSize - index];
    while (!(IsValidClient(bot) && IsFakeClient(bot)) && ++index <= g_iPoolSize)
        bot = g_iPoolArray[g_iPoolSize - index];
    if (index > g_iPoolSize && !(IsValidClient(bot) && IsFakeClient(bot)))
    {
        // LogMessage("[SIPool] No SI available !");
        OnPoolSizeChanged(g_iPoolSize, 0);
        g_iPoolSize = 0;

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
    SetClass(bot, zclass);
    SetClientName(bot, g_sZombieClass[zclass - 1]);

    Event event = CreateEvent("player_spawn");
    if (event != INVALID_HANDLE)
    {
        event.SetInt("userid", GetClientUserId(bot));
        FireEvent(event);
    }

#if DEBUG
    LogMessage("[SIPool] SI request: %d", bot);
#endif

    OnPoolSizeChanged(g_iPoolSize, g_iPoolSize - index);
    g_iPoolSize -= index;

    return bot;
}

any Native_SIPool_ReturnSIBot(Handle plugin, int numParams)
{
    int bot = GetNativeCell(2);
    if (!(IsInfected(bot) && IsFakeClient(bot)))
    {
        LogMessage("[SIPool] SI is not available!");
        return false;
    }

    ResetDeadZombie(bot);
    g_iPoolArray[g_iPoolSize++] = bot;

    // Return bot dont need to resize...
    // OnPoolSizeChanged(g_iPoolSize, g_iPoolSize + 1);
    // g_iPoolSize++;

    return true;
}

void OnPoolSizeChanged(int iOldPoolSize, int iNewPoolSize)
{
    if (GetClientCount(false) >= MaxClients) return;

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
        int bot = CreateSIBot();
        if (bot == -1)
        {
            LogMessage("[SIPool] SI create failed, maybe too many...");
            break;
        }
        g_iPoolArray[i] = bot;
        InitializeSpecial(bot, _, _, true);
#if DEBUG
        LogMessage("[SIPool] SI create: %d", bot);
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
    if (!(IsInfected(client) && IsFakeClient(client))) return;

#if DEBUG
    LogMessage("[SIPool] SI dead: %d", client);
#endif

    // Return bot;
    ResetDeadZombie(client);
    g_iPoolArray[g_iPoolSize++] = client;
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    RecoverSIPool();
}

void PrepareSDKCalls()
{
    GameData hGameData = new GameData(GAMEDATA_FILE);
    Address pReplaceWithBot = hGameData.GetAddress("NextBotCreatePlayerBot.jumptable");
    if (pReplaceWithBot != Address_Null && LoadFromAddress(pReplaceWithBot, NumberType_Int8) == 0x68)
        PrepWindowsCreateBotCalls(pReplaceWithBot);
    else
        PrepLinuxCreateBotCalls(hGameData);

    StartPrepSDKCall(SDKCall_Player);
    if (PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::SetClass"))
    {
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
        g_hSDK_CTerrorPlayer_SetClass = EndPrepSDKCall();
        if (g_hSDK_CTerrorPlayer_SetClass == null)
            LogError("Failed to create SDKCall: \"CTerrorPlayer::SetClass\"");
    }
    else LogError("Failed to find signature: \"CTerrorPlayer::SetClass\"");

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

void PrepWindowsCreateBotCalls(Address pBaseAddr)
{
    Address pFuncRefAddr = pBaseAddr + view_as<Address>(6);
    int funcRelOffset = LoadFromAddress(pFuncRefAddr, NumberType_Int32);
    Address pCallOffsetBase = pBaseAddr + view_as<Address>(10);
    Address pNextBotCreatePlayerBotTAddr = pCallOffsetBase + view_as<Address>(funcRelOffset);

    StartPrepSDKCall(SDKCall_Static);
    if (!PrepSDKCall_SetAddress(pNextBotCreatePlayerBotTAddr))
        SetFailState("Unable to find NextBotCreatePlayer<Hunter> address in memory.");
    PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
    PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
    g_hSDK_NextBotCreatePlayerBot_Hunter = EndPrepSDKCall();
}

void PrepLinuxCreateBotCalls(GameData hGameData = null)
{
    StartPrepSDKCall(SDKCall_Static);
    if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "NextBotCreatePlayerBot<Hunter>"))
        SetFailState("Failed to find signature: %s", "NextBotCreatePlayerBot<Hunter>");
    PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
    PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
    g_hSDK_NextBotCreatePlayerBot_Hunter = EndPrepSDKCall();
}

void SetClass(int client, int zombieClass)
{
    int weapon = GetPlayerWeaponSlot(client, 0);
    if (weapon != -1)
    {
        RemovePlayerItem(client, weapon);
        RemoveEntity(weapon);
    }

    int ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
    if (ability != -1) RemoveEntity(ability);

    SDKCall(g_hSDK_CTerrorPlayer_SetClass, client, zombieClass);

    ability = SDKCall(g_hSDK_CBaseAbility_CreateForPlayer, client);
    if (ability != -1) SetEntPropEnt(client, Prop_Send, "m_customAbility", ability);
}

void SetStateTransition(int client, int state)
{
    SDKCall(g_hSDK_CCSPlayer_State_Transition, client, state);
}

void RespawnPlayer(int client)
{
    SDKCall(g_hSDK_CTerrorPlayer_RoundRespawn, client);
}

int CreateSIBot()
{
    return SDKCall(g_hSDK_NextBotCreatePlayerBot_Hunter, "Hunter");
}
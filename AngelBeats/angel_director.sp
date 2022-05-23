/*
 * @Author:             派蒙
 * @Last Modified by:   派蒙
 * @Create Date:        2022-03-24 17:00:57
 * @Last Modified time: 2022-05-23 14:08:02
 * @Github:             http://github.com/PaimonQwQ
 */

#pragma semicolon 1
#pragma newdecls required

#include <colors>
#include <sdktools>
#include <l4d2tools>
#include <sourcemod>
#include <left4dhooks>

#define MAXSIZE 33
#define VERSION "2022.05.23"

public Plugin myinfo =
{
    name = "AngelDirector",
    author = "我是派蒙啊",
    description = "AngelServer的刷特导演",
    version = VERSION,
    url = "http://github.com/PaimonQwQ/L4D2-Plugins/AngelBeats"
};

bool
    g_bIsGameStart,
    g_bIsSpawnCounting;

float
    g_fLastFlowPercent;

ConVar
    //模式开关
    g_hAngelVersus,
    //导演刷特限制
    g_hHunterLimit,
    g_hBoomerLimit,
    g_hSmokerLimit,
    g_hJockeyLimit,
    g_hChargerLimit,
    g_hSpitterLimit,
    //插件刷特限制
    g_hSICountLimit,
    g_hAngelSpawnFlow,
    g_hAngelDelayDistance,
    g_hAngelDirectorDebug,
    g_hAngelSpawnInterval,
    g_hAngelJockeyLimit,
    g_hAngelHunterLimit,
    g_hAngelSpitterLimit,
    g_hAngelBoomerLimit,
    g_hAngelSmokerLimit,
    g_hAngelChargerLimit;

//插件入口
public void OnPluginStart()
{
    HookEvent("round_start", Event_RoundStart);
    HookEvent("witch_killed", Event_WitchKilled);
    HookEvent("mission_lost", Event_MissionLost);
    HookEvent("tank_spawn", Event_TankSpawn, EventHookMode_Pre);
    HookEvent("player_team", Event_PlayerChangeTeam, EventHookMode_Pre);

    g_hHunterLimit = FindConVar("z_hunter_limit");
    g_hBoomerLimit = FindConVar("z_boomer_limit");
    g_hSmokerLimit = FindConVar("z_smoker_limit");
    g_hJockeyLimit = FindConVar("z_jockey_limit");
    g_hChargerLimit = FindConVar("z_charger_limit");
    g_hSpitterLimit = FindConVar("z_spitter_limit");

    CreateConVar("angel_infected_limit", "6", "特感上限显示");
    g_hSICountLimit = CreateConVar("l4d_infected_limit", "31", "特感数量上限");

    g_hAngelDirectorDebug = CreateConVar("angel_director_debug", "0", "输出测试信息");
    g_hAngelSpawnFlow = CreateConVar("angel_spawn_flow", "5", "生还进程影响刷特的权重");
    //路程刷特方式：若 当前生还最高路程 - 上次刷特特感最高路程 >= 权重 * (40 - 当前刷特秒数) / 20 时，进行计时
    g_hAngelDelayDistance = CreateConVar("angel_special_delay_ditance", "520", "特感落后传送距离");
    g_hAngelSpawnInterval = CreateConVar("angel_special_respawn_interval", "16", "复活时间限制");
    g_hAngelJockeyLimit = CreateConVar("angel_jockey_limit", "1", "Jockey数量限制");
    g_hAngelHunterLimit = CreateConVar("angel_hunter_limit", "1", "Hunter数量限制");
    g_hAngelSpitterLimit = CreateConVar("angel_spitter_limit", "1", "Spitter数量限制");
    g_hAngelBoomerLimit = CreateConVar("angel_boomer_limit", "1", "Boomer数量限制");
    g_hAngelSmokerLimit = CreateConVar("angel_smoker_limit", "1", "Smoker数量限制");
    g_hAngelChargerLimit = CreateConVar("angel_charger_limit", "1", "Charger数量限制");

    g_hSICountLimit.AddChangeHook(CvarEvent_LimitChanged);
    g_hHunterLimit.AddChangeHook(CvarEvent_LimitChanged);
    g_hBoomerLimit.AddChangeHook(CvarEvent_LimitChanged);
    g_hSmokerLimit.AddChangeHook(CvarEvent_LimitChanged);
    g_hJockeyLimit.AddChangeHook(CvarEvent_LimitChanged);
    g_hChargerLimit.AddChangeHook(CvarEvent_LimitChanged);
    g_hSpitterLimit.AddChangeHook(CvarEvent_LimitChanged);

    g_hAngelJockeyLimit.AddChangeHook(CvarEvent_AngelLimitChanged);
    g_hAngelHunterLimit.AddChangeHook(CvarEvent_AngelLimitChanged);
    g_hAngelSpitterLimit.AddChangeHook(CvarEvent_AngelLimitChanged);
    g_hAngelBoomerLimit.AddChangeHook(CvarEvent_AngelLimitChanged);
    g_hAngelSmokerLimit.AddChangeHook(CvarEvent_AngelLimitChanged);
    g_hAngelChargerLimit.AddChangeHook(CvarEvent_AngelLimitChanged);

    g_hAngelVersus = CreateConVar("angel_versus", "0", "Angel对抗开关");

    RegConsoleCmd("sm_dc", Cmd_DirectorMsg, "Show director-manager information");
    RegConsoleCmd("sm_xx", Cmd_DirectorMsg, "Show director-manager information");
}

//玩家进入服务器
public void OnClientPutInServer(int client)
{
    if (IsFakeClient(client)) return;

    CPrintToChat(client, "{olive}插件{default}[{blue}Angel{default}] {olive}状态{default}[{blue}%d特/%d秒{default}] {olive}版本{default}[{blue}%s{default}]",
        GetInfectedLimit(), g_hAngelSpawnInterval.IntValue, VERSION);
}

//地图加载
public void OnMapStart()
{
    g_bIsGameStart = false;
    g_bIsSpawnCounting = true;
}

//玩家解控
public Action OnPlayerRunCmd(int client, int &buttons, int &impuls)
{
    float flow = L4D2_GetFurthestSurvivorFlow() / L4D2Direct_GetMapMaxFlowDistance() * 100;
    if((IsAllKillersDown() || GetAliveInfectedCount() <= GetInfectedLimit() / 4 * 2 ||
        flow - g_fLastFlowPercent >= g_hAngelSpawnFlow.FloatValue * (40 - g_hAngelSpawnInterval.FloatValue) / 20) && !g_bIsSpawnCounting)
    {
        if(g_hAngelDirectorDebug.BoolValue)
            CPrintToChatAll("counting--%d %d %f", IsAllKillersDown(), GetAliveInfectedCount() <= GetInfectedLimit() / 4 * 2, flow - g_fLastFlowPercent);
        float time = g_hAngelSpawnInterval.FloatValue + 1;
        g_bIsSpawnCounting = true;
        CreateTimer(time, Timer_Prepare2Spawn, 0, TIMER_FLAG_NO_MAPCHANGE);
    }

    return Plugin_Continue;
}

//玩家特感进入灵魂状态
public void L4D_OnEnterGhostState(int client)
{
    //Angel对抗或躲猫猫未开启，玩家进入特感灵魂时移动至旁观
    if (!g_hAngelVersus.BoolValue || !FindConVar("z_hunter_limit").BoolValue)
        ChangeClientTeam(client, TEAM_SPECTATOR);

    L4D_SetClass(client, FindConVar("angel_party").IntValue);
}

//玩家离开安全屋
public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
    CPrintToChatAll("{olive}插件{default}[{blue}Angel{default}] {olive}状态{default}[{blue}%d特/%d秒{default}] {olive}版本{default}[{blue}%s{default}]",
        GetInfectedLimit(), g_hAngelSpawnInterval.IntValue, VERSION);

    g_bIsGameStart = true;
    CreateTimer(0.5, Timer_Prepare2Spawn, 0, TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer((g_hAngelSpawnInterval.FloatValue + 1) / 2, Timer_DelaySIDealed, 0, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);

    return Plugin_Continue;
}

//回合开始事件
public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    g_bIsGameStart = false;
    g_bIsSpawnCounting = true;
    CPrintToChatAll("{olive}插件{default}[{blue}Angel{default}] {olive}状态{default}[{blue}%d特/%d秒{default}] {olive}版本{default}[{blue}%s{default}]",
        GetInfectedLimit(), g_hAngelSpawnInterval.IntValue, VERSION);
    return Plugin_Continue;
}

//关卡失败
public Action Event_MissionLost(Event event, const char[] name, bool dont_broadcast)
{
    g_bIsGameStart = false;
    g_bIsSpawnCounting = true;
    return Plugin_Continue;
}

//坦克生成事件
public Action Event_TankSpawn(Event event, const char[] name, bool dont_broadcast)
{
    int tank = GetClientOfUserId(event.GetInt("userid"));
    int heal = GetSurvivorCount() > 2 ? 1500 * GetSurvivorCount() : 1100 * GetSurvivorCount();
    SetPlayerHealth(tank, heal);
    return Plugin_Continue;
}

//秒妹回血
public Action Event_WitchKilled(Event event, const char[] name, bool dont_broadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (IsSurvivor(client) && IsPlayerAlive(client) && !IsPlayerIncap(client))
    {
        int iMaxHp = GetEntProp(client, Prop_Data, "m_iMaxHealth");
        int iTargetHealth = GetPlayerHealth(client) + 10;
        if (iTargetHealth > iMaxHp)
            iTargetHealth = iMaxHp;

        SetPlayerHealth(client, iTargetHealth);
    }
    return Plugin_Continue;
}

//玩家切换队伍时修正尸潮数量
public Action Event_PlayerChangeTeam(Event event, const char[] name, bool dont_broadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsValidClient(client) || IsFakeClient(client))
        return Plugin_Continue;

    CreateTimer(0.1, Timer_MobChange, 0, TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Continue;
}

//尸潮数量更改
public Action Timer_MobChange(Handle timer)
{
    FindConVar("z_common_limit").SetInt(4 * GetSurvivorCount());
    FindConVar("z_mega_mob_size").SetInt(6 * GetSurvivorCount());
    FindConVar("z_mob_spawn_min_size").SetInt(3 * GetSurvivorCount());
    FindConVar("z_mob_spawn_max_size").SetInt(4 * GetSurvivorCount());
}

//特感生成准备
public Action Timer_Prepare2Spawn(Handle timer)
{
    StartSpawn();
    if(g_hAngelDirectorDebug.BoolValue)
            CPrintToChatAll("started");
}

//延后特感传送
public Action Timer_DelaySIDealed(Handle timer)
{
    if(!g_bIsGameStart) return Plugin_Stop;
    for(int i = 1; i < MaxClients; i++)
        if(IsInfected(i) && IsFakeClient(i) && IsPlayerAlive(i) &&
            !CanPlayerSeeThreats(i) && !IsTank(i) && !IsPinningASurvivor(i))
        {
                float pos[3];
                float keyPos[3];
                int keySurvivor = L4D_GetHighestFlowSurvivor();

                GetClientAbsOrigin(i, pos);
                GetClientAbsOrigin(keySurvivor, keyPos);
                if(L4D2Direct_GetFlowDistance(i) < L4D2Direct_GetFlowDistance(keySurvivor) &&
                    !L4D2_VScriptWrapper_NavAreaBuildPath(pos, keyPos, g_hAngelDelayDistance.FloatValue, false, false, TEAM_INFECTED, false))
                {
                    L4D_GetRandomPZSpawnPosition(keySurvivor, GetInfectedClass(i), 2, pos);
                    TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR);
                    if(g_hAngelDirectorDebug.BoolValue)
                        CPrintToChatAll("%N tped to %N",i, keySurvivor);
                }
        }
    return Plugin_Continue;
}

//特感数量更改
public void CvarEvent_LimitChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if(convar != g_hSICountLimit)
        convar.SetInt(0, true);
    else convar.SetInt(31, true);
    //请勿更改，否则会出现卡特现象(特感刷不出来)
}

//刷特数量更改
public void CvarEvent_AngelLimitChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    FindConVar("angel_infected_limit").SetInt(GetInfectedLimit(), true);
}

//插件信息
public Action Cmd_DirectorMsg(int client, any args)
{
    CPrintToChat(client, "{olive}插件{default}[{blue}Angel{default}] {olive}状态{default}[{blue}%d特/%d秒{default}] {olive}版本{default}[{blue}%s{default}]",
        GetInfectedLimit(), g_hAngelSpawnInterval.IntValue, VERSION);
    return Plugin_Handled;
}

//是否存在非克、舌头、口水、胖子存活
bool IsAllKillersDown()
{
    for(int client = 1; client <= MaxClients; client++)
        if(IsInfected(client) && !IsTank(client) && IsPlayerAlive(client) && IsFakeClient(client))
            if(GetInfectedClass(client) != view_as<int>(ZC_Spitter) &&
                GetInfectedClass(client) != view_as<int>(ZC_Smoker) &&
                GetInfectedClass(client) != view_as<int>(ZC_Boomer))
                return false;

    return true;
}

//开始刷特
void StartSpawn()
{
    if(!g_bIsGameStart) return;

    float pos[3];
    float keyPos[3];
    int typeLimit[6];
    int keySurvivor = L4D_GetHighestFlowSurvivor();
    GetClientAbsOrigin(keySurvivor, keyPos);
    typeLimit[0] = g_hAngelSmokerLimit.IntValue;
    typeLimit[1] = g_hAngelBoomerLimit.IntValue;
    typeLimit[2] = g_hAngelHunterLimit.IntValue;
    typeLimit[3] = g_hAngelSpitterLimit.IntValue;
    typeLimit[4] = g_hAngelJockeyLimit.IntValue;
    typeLimit[5] = g_hAngelChargerLimit.IntValue;

    for(int i = 1; i < 7; i++)
    {
        for(int v = GetAliveInfectedCountByClass(i); v < typeLimit[i - 1]; v++)
        {
            if(GetAliveInfectedCount() >= GetInfectedLimit() &&
                FindConVar("angel_party").IntValue > 0)
                break;

            int times = 2;
            float tarPos[3];
            int target = GetInfectedClientBeyondLimit();
            int zclass = FindConVar("angel_party").IntValue ? FindConVar("angel_party").IntValue : i;
            if(IsInfected(target) && IsPlayerAlive(target))
                GetClientAbsOrigin(target, tarPos);

            L4D_GetRandomPZSpawnPosition(keySurvivor, zclass, times--, pos);
            while((L4D2Direct_GetTerrorNavArea(pos) == Address_Null ||
                L4D2_NavAreaTravelDistance(pos, keyPos, true) <= 0) && times > 0)
                L4D_GetRandomPZSpawnPosition(keySurvivor, zclass, times--, pos);

            if(!IsInfected(target))
                L4D2_SpawnSpecial(zclass, pos, NULL_VECTOR);
            else if(!IsPinningASurvivor(target) &&
                L4D2Direct_GetFlowDistance(target) < L4D2Direct_GetFlowDistance(keySurvivor) &&
                !L4D2_VScriptWrapper_NavAreaBuildPath(tarPos, keyPos, g_hAngelDelayDistance.FloatValue, false, false, TEAM_INFECTED, false))
            {
                L4D_SetClass(target, zclass);
                TeleportEntity(target, pos, NULL_VECTOR, NULL_VECTOR);
            }
        }
    }

    g_fLastFlowPercent = GetFurthestInfectedFlow() / L4D2Direct_GetMapMaxFlowDistance() * 100;
    g_bIsSpawnCounting = false;
}

int GetInfectedLimit()
{
    return g_hAngelSmokerLimit.IntValue + g_hAngelSpitterLimit.IntValue +
        g_hAngelBoomerLimit.IntValue + g_hAngelHunterLimit.IntValue +
        g_hAngelJockeyLimit.IntValue + g_hAngelChargerLimit.IntValue;
}

int GetAliveInfectedCountByClass(int zclass)
{
    int count = 0;
    for(int i = 1; i < MaxClients; i++)
        if(IsInfected(i) && IsPlayerAlive(i) && GetInfectedClass(i) == zclass)
            count++;

    return count;
}

float GetFurthestInfectedFlow()
{
    float farFlowDis = 0.0;
    for(int i = 1; i < MaxClients; i++)
        if(IsInfected(i) && IsPlayerAlive(i) && farFlowDis < L4D2Direct_GetFlowDistance(i))
            farFlowDis = L4D2Direct_GetFlowDistance(i);

    return farFlowDis;
}

int GetInfectedClientBeyondLimit()
{
    int typeLimit[6];
    typeLimit[0] = g_hAngelSmokerLimit.IntValue;
    typeLimit[1] = g_hAngelBoomerLimit.IntValue;
    typeLimit[2] = g_hAngelHunterLimit.IntValue;
    typeLimit[3] = g_hAngelSpitterLimit.IntValue;
    typeLimit[4] = g_hAngelJockeyLimit.IntValue;
    typeLimit[5] = g_hAngelChargerLimit.IntValue;
    for(int i = 1; i < 7; i++)
    {
        int count = 0;
        for(int v = 1; v <= MaxClients; v++)
            if(IsInfected(v) && IsPlayerAlive(v) && IsFakeClient(v) && !IsTank(v) &&
                GetInfectedClass(v) == i && !CanPlayerSeeThreats(v) && !IsPinningASurvivor(v))
            {
                count++;
                if(count > typeLimit[i - 1])
                    return v;
            }
    }
    return 0;
}
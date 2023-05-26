#include <left4dhooks>
#include <sourcemod>
#include <sdktools>

new ConVar:infectedLimitConvar;
new ConVar:infectedSpawnTypeConvar;
new ConVar:infectedSpawnIntervalConvar;

new Handle:spawnHandle;
new Handle:selfKillHandle;
new Handle:awaytankHandle;
new bool:isSpawnable = true;
new bool:isRoundOver = true;
new bool:isTankAlive = false;
new bool:isPlayerLeft = false;

new infectedLimit;
new infectedSpawnType;
new Float:infectedSpawnInterval;
new Float:infectedSpawnTime = 0.5;

new tankClient;

public Plugin:myinfo = 
{
    name = "Infected Party",
    author = "我是派蒙啊",
    description = "控制特感生成",
    version = "1.0.8",
    url = "http://www.paimeng.ltd/"
}

public void OnPluginStart()
{
    HookEvent("player_death", OnInfectedDeath, EventHookMode_Post);
    HookEvent("tank_spawn", OnTankSpawn, EventHookMode_Post);
    HookEvent("tank_killed", OnTankDead, EventHookMode_Post);
    HookEvent("finale_win", OnMissionOver, EventHookMode_Post);
    HookEvent("map_transition", OnMissionOver, EventHookMode_Post);
    HookEvent("mission_lost", OnMissionOver, EventHookMode_Post);
    HookEvent("triggered_car_alarm", OnCarWarning, EventHookMode_Post);
    HookEvent("jockey_ride_end", OnRideStopped, EventHookMode_Post);
    HookEvent("tongue_pull_stopped", OnPullStopped, EventHookMode_Post);
    infectedSpawnTypeConvar = CreateConVar("l4d2_infected_type", "6", "1=Smoker, 2=Boomer, 3=Hunter, 4=Spitter, 5=Jockey, 6=Charger 8=Tank", 0, false, 0.0, false, 0.0);
    infectedLimitConvar = CreateConVar("l4d_infected_limit", "3", "", 0, false, 0.0, false, 0.0);
    infectedSpawnIntervalConvar = CreateConVar("versus_special_respawn_interval", "16.0", "", 0, false, 0.0, false, 0.0);

    GetConVars();
    infectedSpawnTypeConvar.AddChangeHook(OnConVarChanged);
    infectedLimitConvar.AddChangeHook(OnConVarChanged);
    infectedSpawnIntervalConvar.AddChangeHook(OnConVarChanged);

    RegAdminCmd("sm_spawn", CmdSpawn, ADMFLAG_CHEATS);
    RegAdminCmd("sm_sptank", CmdTank, ADMFLAG_CHEATS);
}

//******Action****

public Action:L4D_OnFirstSurvivorLeftSafeArea(int client)
{
    char playerName[256];
    GetClientName(client, playerName, 256);
    PrintHintTextToAll("%s 离开安全屋", playerName);

    isPlayerLeft = isSpawnable = isRoundOver = true;

    spawnHandle = CreateTimer(0.1, PrepareToSpawn, 0, 0);
}

public void OnInfectedDeath(Event:event, String:name[], bool:dont_broadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid", 0));
    if(IsClientInTeam(client, 3))
    {
        CreateTimer(0.1, KickBotClient, client);
        CreateTimer(0.2, CheckSpawnable, 0, 0);
        CreateTimer(0.3, CheckRoundOver, 0, 0);
    }
}

public void OnTankSpawn(Event:event, String:name[], bool:dont_broadcast)
{
    isTankAlive = true;
    tankClient = GetClientOfUserId(GetEventInt(event, "userid", 0));
    awaytankHandle = CreateTimer(60.0, CheckPlayerAwayTank, 0, 0);
}

public void OnTankDead(Event:event, String:name[], bool:dont_broadcast)
{
    isTankAlive = false;
    if(awaytankHandle)
        CloseHandle(awaytankHandle);
}

public void OnMissionOver(Event:event, String:name[], bool:dont_broadcast)
{
    CreateTimer(4.0, PrintFinal, 0, 0);

    isPlayerLeft = isSpawnable = isRoundOver = isTankAlive = false;

    if(spawnHandle)
        CloseHandle(spawnHandle);
    //if(selfKillHandle)
        //CloseHandle(selfKillHandle);
    if(awaytankHandle)
        CloseHandle(awaytankHandle);
}

public void OnCarWarning(Event:event, String:name[], bool:dont_broadcast)
{
    float vPos[3] = 0.0;
    float vAng[3] = 0.0;
    L4D_GetRandomPZSpawnPosition(0, 1, 1, vPos);
    //L4D2_SpawnTank(vPos, vAng);
    //PrintToChatAll("\x04喜欢打车是吧!!!");
}

public void OnRideStopped(Event:event, String:name[], bool:dont_broadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid", 0));
    ForcePlayerSuicide(client);
}

public void OnPullStopped(Event event, String:name[], bool:dont_broadcast)
{
    if(GetEventInt(event, "release_type", 0) == CUT_SLASH)
    {

        char weapon[32];
        GetClientWeapon( attacker, weapon, 32 );

        // this doesn't count the chainsaw, but that's no-skill anyway
        if ( StrEqual(weapon, "weapon_melee", false) )
        {
            int client = GetClientOfUserId(GetEventInt(event, "smoker", 0));
            ForcePlayerSuicide(client);
        }

    }
}

public void OnConVarChanged(ConVar:convar, String:oldValue[], String:newValue[])
{
    GetConVars();

    isSpawnable = isRoundOver = true;
    isTankAlive = false;

    if(isPlayerLeft)
    {
        if(spawnHandle)
            CloseHandle(spawnHandle);
        spawnHandle = CreateTimer(1.0, PrepareToSpawn, 0, 0);
    }
}

public Action:PrintFinal(Handle:timer)
{
    char finish[256];
    int random = GetRandomInt(0, 9);
    switch(random)
    {
        case 1:
        {
            finish = "啊，噗通...";
        }
        case 2:
        {
            finish = "辜负了...期待...";
        }
        case 3:
        {
            finish = "太不甘心了...";
        }
        case 4:
        {
            finish = "时机...不对...";
        }
        case 5:
        {
            finish = "雷鸣...将歇...";
        }
        case 6:
        {
            finish = "无念...无执...";
        }
        case 7:
        {
            finish = "略感疲惫...";
        }
        default:
        {
            finish = "世界...拒绝了我...";
        }
    }
    PrintToChatAll("\x05结束了吗...\x04%s", finish);
}

public Action:CheckSpawnable(Handle:timer)
{
    if(GetTeamClientCount(3) <= infectedLimit / 2 && !isSpawnable)
        CreateTimer(infectedSpawnInterval, WaitForSpawn, 0 ,0);
}

public Action:WaitForSpawn(Handle:timer)
{
    isSpawnable = true;

    //if(roundOverHandle)
        //CloseHandle(roundOverHandle);
    //roundOverHandle =
    CreateTimer(12.0, SetRoundOver, 0 ,0);
}

public Action:CheckRoundOver(Handle:timer)
{
    isRoundOver = (!HasInfectedAlive() || IsOnlyTankAlive());
}

public Action:SetRoundOver(Handle:timer)
{
    if(GetTeamClientCount(3) == 1)
        for(int client = 1; client < MaxClients; client++)
            if(IsClientInTeam(client, 3) && client != tankClient)
                if(!IsPinningSurvivor(client))
                    ForcePlayerSuicide(client);

    if(!isRoundOver)
        isRoundOver = true;
}

public Action:PrepareToSpawn(Handle:timer)
{
    if(isSpawnable && isRoundOver)
        CreateTimer(infectedSpawnTime, StartSpwan, 0, 0);
    spawnHandle = CreateTimer(infectedSpawnTime + 0.5, PrepareToSpawn, 0, 0);
}

public Action:StartSpwan(Handle:timer)
{
    CreateInfected();
    //selfKillHandle = CreateTimer(120.0, SelfKill, 0, 0);
}

public Action:SelfKill(Handle:timer)
{
    if(selfKillHandle)
        CloseHandle(selfKillHandle);

    for(int client = 1; client < MaxClients; client++)
        if(IsClientInTeam(client, 3) && client != tankClient)
            if(!IsPinningSurvivor(client))
                ForcePlayerSuicide(client);
            //else selfKillHandle = CreateTimer(120.0, SelfKill, 0, 0);

    isRoundOver = true;
    isSpawnable = true;
}

public Action:CheckPlayerAwayTank(Handle:timer)
{
    if(awaytankHandle)
        CloseHandle(awaytankHandle);

    new maxDistance = 0;
    new Float:tankPos[3] = 0.0;
    new Float:survivorPos[3] = 0.0;
    int survivors[4] = 0;
    int selectSurvivor = 32;
    GetSurvivors(survivors);
    for(int index = 0; index < 4; index++)
    {
        if(!IsPlayerAlive(survivors[index])) continue;
        GetEntPropVector(survivors[index], Prop_Send, "m_vecOrigin", survivorPos, 0);
        if(maxDistance < GetVectorDistance(tankPos, survivorPos, false))
        {
            maxDistance = RoundToNearest(GetVectorDistance(tankPos, survivorPos, false));
            selectSurvivor = survivors[index];
        }
    }
    if(selectSurvivor != 32 && maxDistance >= 16000)
    {
        survivorPos[0] += 200;
        survivorPos[1] += 200;
        survivorPos[2] += 500;
        TeleportEntity(tankClient, survivorPos, NULL_VECTOR, NULL_VECTOR);
        PrintToChatAll("\x04喜欢克局跑分是吧!!");
    }

    awaytankHandle = CreateTimer(60.0, CheckPlayerAwayTank, 0, 0);
}

public Action:CmdSpawn(any:client, any:args)
{
    CreateInfected();
}

public Action:CmdTank(any:client, any:args)
{
    float vPos[3] = 0.0;
    float vAng[3] = 0.0;
    L4D_GetRandomPZSpawnPosition(0, 1, 1, vPos);
    L4D2_SpawnTank(vPos, vAng);
}

public Action:KickBotClient(Handle:timer, any:client)
{
    if (IsClientInGame(client) && (!IsClientInKickQueue(client)))
        if (IsFakeClient(client))
            KickClient(client);
}

//******Tools****

public void GetConVars()
{
    infectedLimit = infectedLimitConvar.IntValue;
    infectedSpawnType = infectedSpawnTypeConvar.IntValue;
    infectedSpawnInterval = infectedSpawnIntervalConvar.FloatValue;
}

public bool:HasInfectedAlive()
{
    new bool:flag = false;
    if(GetTeamClientCount(3) > 0)
        for(int client = 1; client <= MaxClients; client++)
            if(IsClientInTeam(client, 3) && client != tankClient)
                if(IsPinningSurvivor(client))
                    continue;
                else { flag = true; break; }
    return flag;
}

public int CreateValidFakeClientCount()
{
    new count = 0;
    for (int client = 1;client <= MaxClients; client++)
        if(IsValidClient(client)) count++;
    return count;
}

public void GetSurvivors(int survivors[4])
{
    int index = 0;
    for(int client = 1; client <= MaxClients; client++)
        if(IsClientInTeam(client, 2) && index < 4) survivors[index++] = client;
}

public bool:IsOnlyTankAlive()
{
    return (isTankAlive && GetTeamClientCount(3) == 1);
}

public bool:IsClientInTeam(any:client, int team)
{
    return (IsValidClient(client) && GetClientTeam(client) == team);
}

public bool:IsValidClient(any:client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

public void CreateInfected()
{
    SpawnInfected(infectedLimit);
}

public void SpawnInfected(int num)
{
    float vPos[3] = 0.0;
    float vAng[3] = 0.0;
    new survivors[4];
    GetSurvivors(survivors);
    for(int i = GetTeamClientCount(3); i < num; i = GetTeamClientCount(3))
    {
        L4D_GetRandomPZSpawnPosition(survivors[GetRandomInt(0,3)], infectedSpawnType, 2, vPos);
        L4D2_SpawnSpecial(infectedSpawnType, vPos, vAng);
    }

    isRoundOver = isSpawnable = false;
}

public bool:IsPinningSurvivor(client)
{
    new bool:isPinning;
    if (IsClientInTeam(client, 3) && IsPlayerAlive(client))
    {
        if (0 < GetEntPropEnt(client, PropType:0, "m_tongueVictim", 0))
        {
            isPinning = true;
        }
        if (0 < GetEntPropEnt(client, PropType:0, "m_pounceVictim", 0))
        {
            isPinning = true;
        }
        if (0 < GetEntPropEnt(client, PropType:0, "m_carryVictim", 0))
        {
            isPinning = true;
        }
        if (0 < GetEntPropEnt(client, PropType:0, "m_pummelVictim", 0))
        {
            isPinning = true;
        }
        if (0 < GetEntPropEnt(client, PropType:0, "m_jockeyVictim", 0))
        {
            isPinning = true;
        }
    }
    return isPinning;
}
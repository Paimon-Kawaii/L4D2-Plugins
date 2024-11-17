/*
 * @Author: 我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date: 2024-09-06 22:30:02
 * @Last Modified time: 2024-09-18 00:32:10
 * @Github: https://github.com/Paimon-Kawaii
 */

#define DEBUG      0

#define PL_NAME    "Server Mix"
#define PL_AUTHOR  "我是派蒙啊"
#define PL_DESC    " "
#define PL_VERSION "0.0.1.5194"
#define PL_URL     "https://github.com/Paimon-Kawaii"

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name = PL_NAME,
    author = PL_AUTHOR,
    description = PL_DESC,
    version = PL_VERSION,
    url = PL_URL
};

#include <paiutils>
#define MAXSIZE MAXPLAYERS + 1

public void OnPluginStart()
{
    RegConsoleCmd("sm_ttsb", CMD_TTSB);
}

Action CMD_TTSB(int client, int args)
{
    static const char entcls[] = "prop_physics_multiplayer";
    PrintToChatAll("%s", entcls);
    int ent = CreateEntityByName(entcls);

    static char model[128];
    GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
    DispatchKeyValueFloat(ent, "physdamagescale", 0.0);
    DispatchKeyValueInt(ent, "Damagetype", 0);
    DispatchKeyValueInt(ent, "nodamageforces", 1);
    DispatchKeyValueFloat(ent, "inertiascale", 0.0);
    DispatchKeyValueInt(ent, "PerformanceMode", 1);
    DispatchKeyValue(ent, "model", model);

    DispatchSpawn(ent);

    static float pos[3], speed[3] = { 100.0, 100.0, 100.0 };
    GetClientAbsOrigin(client, pos);
    TeleportEntity(ent, pos, _, speed);
#define COLLISION_GROUP_PLAYER 5
#define SOLID_BBOX             2
#define FSOLID_VOLUME_CONTENTS 16
#define EFL_DONTBLOCKLOS       (1 << 25)
    SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
    SetEntityCollisionGroup(ent, COLLISION_GROUP_PLAYER);

    SetEntityMoveType(ent, MOVETYPE_NOCLIP);
    SetEntProp(ent, Prop_Data, "m_nSolidType", SOLID_BBOX);
    SetEntProp(ent, Prop_Data, "m_usSolidFlags", FSOLID_VOLUME_CONTENTS);

    int iFlags = GetEntProp(ent, Prop_Data, "m_iEFlags");
    iFlags = iFlags |= EFL_DONTBLOCKLOS;    // you never know with this game.
    SetEntProp(ent, Prop_Data, "m_iEFlags", iFlags);

    SetEntProp(ent, Prop_Send, "m_bClientSideAnimation", 1, 1);

    DataPack dp = new DataPack();
    dp.WriteCell(ent);
    dp.WriteCell(client);
    dp.Reset();
    RequestFrame(TestFollow, dp);
    int r = LookupEntityAttachment(ent, "eye");
    // LocalAngles || BodyTarget || AimHead || SetClientLookatTarget
    PrintToChatAll("%d", r);

    SDKHook(ent, SDKHook_OnTakeDamage, OnTakeDamage);

    return Plugin_Handled;
}

void TestFollow(DataPack dp)
{
    static int ent, client;
    static float pos[3], ang[3];
    ent = dp.ReadCell();
    client = dp.ReadCell();
    dp.Reset();

    GetClientAbsOrigin(client, pos);
    GetClientAbsAngles(client, ang);
    pos[0] += 50;

    TeleportEntity(ent, pos, ang);

    SetEntPropFloat(ent, Prop_Send, "m_flPlaybackRate", GetEntPropFloat(client, Prop_Send, "m_flPlaybackRate"));
    SetEntProp(ent, Prop_Send, "m_nSequence", CheckAnimation(client, GetEntProp(client, Prop_Send, "m_nSequence", 2)), 2);

    SetEntPropFloat(ent, Prop_Send, "m_flCycle", GetEntPropFloat(client, Prop_Send, "m_flCycle"));
    static int i;
    for (i = 0; i < 23; i++)
    {
        switch (i)
        {
            case 0, 2:
                SetEntPropFloat(ent, Prop_Send, "m_flPoseParameter", 0.0, i);
            default:
                SetEntPropFloat(ent, Prop_Send, "m_flPoseParameter", GetEntPropFloat(client, Prop_Send, "m_flPoseParameter", i), i);    // credit to death chaos for animating legs
        }
    }

    RequestFrame(TestFollow, dp);
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    PrintToChatAll("%d %d %.2f", victim, attacker, damage);

    return Plugin_Continue;
}

float g_fLimpHP;
static int CheckAnimation(int iClient, int iSequence)
{
    static char sModel[31];
    GetEntPropString(iClient, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

    int health = GetClientHealth(iClient);
    float healthBuffer = GetClientHealthBuffer(iClient);

    bool isCalm = view_as<bool>(GetEntProp(iClient, Prop_Send, "m_isCalm"));
    bool isLimping = view_as<bool>((health + healthBuffer) < g_fLimpHP);

    int buttons = GetClientButtons(iClient);

    // detect via netprops or m_nButtons instead of replacing sequences to fix crouching anims being delayed
    // AND reduce shitload of work individually checking for every single sequence
    bool isWalking = view_as<bool>(buttons & IN_SPEED) || GetEntProp(iClient, Prop_Send, "m_isGoingToDie") && health == 1 && healthBuffer == 0.0;

    float vel[3];
    GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", vel);
    bool isMoving = view_as<bool>(vel[0] != 0.0 || vel[1] != 0.0 || vel[2] != 0.0);

    bool duckedVar = view_as<bool>(GetEntProp(iClient, Prop_Send, "m_bDucked"));
    bool duckingVar = view_as<bool>(GetEntProp(iClient, Prop_Send, "m_bDucking"));

    if (view_as<bool>(GetEntProp(iClient, Prop_Send, "m_fFlags") & FL_ONGROUND))    // is on ground
    {
        if ((duckedVar && !duckingVar) || (!duckedVar && duckingVar))    // this fix was entirely discovered by accident
        {
            if (isMoving)    // is moving while ducked
            {
                switch (sModel[29])
                {
                    case 'b':
                    {
                        return 190;
                    }    // CrouchWalk_SMG				ACT_RUN_CROUCH_SMG
                    case 'd', 'w':
                    {
                        return 202;
                    }    // CrouchWalk_SMG				ACT_RUN_CROUCH_SMG
                    case 'c':
                    {
                        return 162;
                    }    // CrouchWalk_Sniper				ACT_RUN_CROUCH_SNIPER
                    case 'h':
                    {
                        return 187;
                    }    // CrouchWalk_Sniper				ACT_RUN_CROUCH_SNIPER
                    case 'v':
                    {
                        return 164;
                    }    // CrouchWalk_SMG				ACT_RUN_CROUCH_SMG
                    case 'n':
                    {
                        return 176;
                    }    // CrouchWalk_Elites				ACT_RUN_CROUCH_ELITES
                    case 'e':
                    {
                        return 158;
                    }    // CrouchWalk_Pistol				ACT_RUN_CROUCH_PISTOL
                    case 'a':
                    {
                        return 170;
                    }    // CrouchWalk_SMG				ACT_RUN_CROUCH_SMG
                }
            }
            else    // is NOT moving while ducked
            {
                switch (sModel[29])
                {
                    case 'b':
                    {
                        return 46;
                    }    // Idle_Crouching_Pistol			ACT_CROUCHIDLE_PISTOL
                    case 'd', 'w':
                    {
                        return 56;
                    }    // Idle_Crouching_Pistol			ACT_CROUCHIDLE_PISTOL
                    case 'c':
                    {
                        return 52;
                    }    // Idle_Crouching_SniperZoomed	ACT_CROUCHIDLE_SNIPER_ZOOMED
                    case 'h':
                    {
                        return 54;
                    }    // Idle_Crouching_SniperZoomed	ACT_CROUCHIDLE_SNIPER_ZOOMED
                    case 'v':
                    {
                        return 43;
                    }    // Idle_Crouching_Pistol			ACT_CROUCHIDLE_PISTOL
                    case 'n':
                    {
                        return 69;
                    }    // Idle_Crouching_SMG			ACT_CROUCHIDLE_SMG
                    case 'e':
                    {
                        return 52;
                    }    // Idle_Crouching_Pistol			ACT_CROUCHIDLE_PISTOL
                    case 'a':
                    {
                        return 49;
                    }    // Idle_Crouching_Pistol			ACT_CROUCHIDLE_PISTOL
                }
            }
        }
        else    // is NOT ducking
        {
            if (isMoving)    // is moving
            {
                if (isLimping)    // is limping
                {
                    if (isWalking)    // is walking
                    {
                        switch (sModel[29])
                        {
                            case 'b':
                            {
                                return 306;
                            }    // LimpWalk_Sniper	ACT_WALK_INJURED_SNIPER
                            case 'd', 'w':
                            {
                                return 142;
                            }    // Walk_Elites		ACT_WALK_ELITES
                            case 'c':
                            {
                                return 120;
                            }    // Walk_Elites		ACT_WALK_ELITES
                            case 'h':
                            {
                                return 127;
                            }    // Walk_Elites		ACT_WALK_ELITES
                            case 'v':
                            {
                                return 122;
                            }    // Walk_Elites		ACT_WALK_ELITES
                            case 'n':
                            {
                                return 161;
                            }    // Walk_SMG			ACT_WALK_SMG
                            case 'e':
                            {
                                return 128;
                            }    // Walk_Pistol		ACT_WALK_PISTOL
                            case 'a':
                            {
                                return 125;
                            }    // Walk_Pistol		ACT_WALK_PISTOL
                        }
                    }
                    else    // is NOT walking
                    {
                        switch (sModel[29])
                        {
                            case 'b':
                            {
                                return 319;
                            }    // LimpRun_SMG		ACT_RUN_INJURED_SMG
                            case 'd', 'w':
                            {
                                return 331;
                            }    // LimpRun_SMG		ACT_RUN_INJURED_SMG
                            case 'c':
                            {
                                return 313;
                            }    // LimpRun_Sniper	ACT_RUN_INJURED_SNIPER
                            case 'h':
                            {
                                return 318;
                            }    // LimpRun_Sniper	ACT_RUN_INJURED_SNIPER
                            case 'v':
                            {
                                return 651;
                            }    // LimpRun_Sniper_Military	ACT_RUN_INJURED_SNIPER_MILITARY
                            case 'n':
                            {
                                return 203;
                            }    // Run_Pistol		ACT_RUN_PISTOL
                            case 'e':
                            {
                                return 266;
                            }    // LimpRun_Rifle		ACT_RUN_INJURED_RIFLE
                            case 'a':
                            {
                                return 264;
                            }    // LimpRun_Rifle		ACT_RUN_INJURED_RIFLE
                        }
                    }
                }
                else    // is NOT limping
                {
                    if (isWalking)    // is walking
                    {
                        switch (sModel[29])
                        {
                            case 'b':
                            {
                                return 130;
                            }    // Walk_Pistol		ACT_WALK_PISTOL
                            case 'd', 'w':
                            {
                                return 142;
                            }    // Walk_Elites		ACT_WALK_ELITES
                            case 'c':
                            {
                                return 120;
                            }    // Walk_Elites		ACT_WALK_ELITES
                            case 'h':
                            {
                                return 160;
                            }    // Walk_Sniper		ACT_WALK_SNIPER
                            case 'v':
                            {
                                return 122;
                            }    // Walk_Elites		ACT_WALK_ELITES
                            case 'n':
                            {
                                return 161;
                            }    // Walk_SMG			ACT_WALK_SMG
                            case 'e':
                            {
                                return 128;
                            }    // Walk_Pistol		ACT_WALK_PISTOL
                            case 'a':
                            {
                                return 128;
                            }    // Walk_Elites		ACT_WALK_ELITES
                        }
                    }
                    else    // is NOT walking
                    {
                        switch (sModel[29])
                        {
                            case 'b':
                            {
                                return 214;
                            }    // Run_Pistol		ACT_RUN_PISTOL
                            case 'd', 'w':
                            {
                                return 229;
                            }    // Run_Elites		ACT_RUN_ELITES
                            case 'c':
                            {
                                return 233;
                            }    // Run_PumpShotgun	ACT_RUN_PUMPSHOTGUN
                            case 'h':
                            {
                                return 208;
                            }    // Run_Elites		ACT_RUN_ELITES
                            case 'v':
                            {
                                return 179;
                            }    // Run_Pistol		ACT_RUN_PISTOL
                            case 'n':
                            {
                                return 203;
                            }    // Run_Pistol		ACT_RUN_PISTOL
                            case 'e':
                            {
                                return 188;
                            }    // Run_Pistol		ACT_RUN_PISTOL
                            case 'a':
                            {
                                return 185;
                            }    // Run_Pistol		ACT_RUN_PISTOL
                        }
                    }
                }
            }
            else    // is NOT moving
            {
                if (isLimping)    // is limping
                {
                    switch (sModel[29])
                    {
                        case 'b':
                        {
                            return 124;
                        }    // Idle_Injured_SniperZoomed	ACT_IDLE_INJURED_SNIPER_ZOOMED
                        case 'd', 'w':
                        {
                            return 132;
                        }    // Idle_Injured_SniperZoomed	ACT_IDLE_INJURED_SNIPER_ZOOMED
                        case 'c':
                        {
                            return 110;
                        }    // Idle_Injured_SniperZoomed	ACT_IDLE_INJURED_SNIPER_ZOOMED
                        case 'h':
                        {
                            return 107;
                        }    // Idle_Injured_PumpShotgun	ACT_IDLE_INJURED_PUMPSHOTGUN
                        case 'v':
                        {
                            return 84;
                        }    // Idle_Injured_Pistol		ACT_IDLE_INJURED_PISTOL
                        case 'n':
                        {
                            return 132;
                        }    // Idle_Injured_SniperZoomed	ACT_IDLE_INJURED_SNIPER_ZOOMED
                        case 'e':
                        {
                            return 99;
                        }    // Idle_Injured_Rifle		ACT_IDLE_INJURED_RIFLE
                        case 'a':
                        {
                            return 93;
                        }    // Idle_Injured_Elites		ACT_IDLE_INJURED_ELITES
                    }
                }
                else    // is NOT limping
                {
                    switch (sModel[29])
                    {
                        case 'b':
                        {
                            switch (iSequence)
                            {
                                case 18,    //	Idle_Standing_Shotgun			ACT_IDLE_SHOTGUN
                                    21:     //	Idle_Standing_PumpShotgun		ACT_IDLE_PUMPSHOTGUN
                                {
                                    return iSequence;
                                }    // Shotgun anims look nice, don't replace
                                default:
                                {
                                    switch (isCalm)
                                    {
                                        case true:    // calm
                                        {
                                            return 7;
                                        }              // Idle_Standing_Pistol			ACT_IDLE_PISTOL
                                        case false:    // not calm
                                        {
                                            return 30;
                                        }    // Idle_Standing_SMG				ACT_IDLE_SMG
                                    }
                                }
                            }
                        }
                        case 'd', 'w':
                        {
                            switch (iSequence)
                            {
                                case 23:    //	Idle_Standing_PumpShotgun		ACT_IDLE_PUMPSHOTGUN
                                {
                                    return 20;
                                }           // Idle_Standing_Shotgun				ACT_IDLE_SHOTGUN
                                case 20:    //	Idle_Standing_Shotgun			ACT_IDLE_SHOTGUN
                                {
                                    return iSequence;
                                }    // Shotgun anims look nice, don't replace
                                default:
                                {
                                    switch (isCalm)
                                    {
                                        case true:    // calm
                                        {
                                            return 7;
                                        }              // Idle_Standing_Elites			ACT_IDLE_ELITES
                                        case false:    // not calm
                                        {
                                            return 32;
                                        }    // Idle_Standing_SMG				ACT_IDLE_SMG
                                    }
                                }
                            }
                        }
                        case 'c':
                        {
                            switch (isCalm)
                            {
                                case true:    // calm
                                {
                                    return 16;
                                }              // Idle_Standing_Shotgun			ACT_IDLE_SHOTGUN
                                case false:    // not calm
                                {
                                    return 24;
                                }    // Idle_Standing_Sniper_MilitaryZoomed	ACT_IDLE_SNIPER_MILITARYZOOMED
                            }
                        }
                        case 'h':
                        {
                            switch (iSequence)
                            {
                                case 39:    //	Idle_Standing_PumpShotgun		ACT_IDLE_PUMPSHOTGUN
                                {
                                    return 15;
                                }           // Idle_Standing_Shotgun				ACT_IDLE_SHOTGUN
                                case 15:    //	Idle_Standing_Shotgun			ACT_IDLE_SHOTGUN
                                {
                                    return iSequence;
                                }    // Shotgun anims look nice, don't replace
                                default:
                                {
                                    switch (isCalm)
                                    {
                                        case true:    // calm
                                        {
                                            return 12;
                                        }              // Idle_Standing_Elites			ACT_IDLE_ELITES
                                        case false:    // not calm
                                        {
                                            return 30;
                                        }    // Idle_Standing_Sniper			ACT_IDLE_SNIPER
                                    }
                                }
                            }
                        }
                        case 'v':
                        {
                            switch (iSequence)
                            {
                                case 21:    //	Idle_Standing_PumpShotgun		ACT_IDLE_PUMPSHOTGUN
                                {
                                    return 18;
                                }           // Idle_Standing_Shotgun				ACT_IDLE_SHOTGUN
                                case 18:    //	Idle_Standing_Shotgun			ACT_IDLE_SHOTGUN
                                {
                                    return iSequence;
                                }    // Shotgun anims look nice, don't replace
                                default:
                                {
                                    switch (isCalm)
                                    {
                                        case true:    // calm
                                        {
                                            return 12;
                                        }              // Idle_Standing_Elites			ACT_IDLE_ELITES
                                        case false:    // not calm
                                        {
                                            return 30;
                                        }    // Idle_Standing_SMG				ACT_IDLE_SMG
                                    }
                                }
                            }
                        }
                        case 'n':
                        {
                            switch (iSequence)
                            {
                                default:
                                {
                                    switch (isCalm)
                                    {
                                        case true:    // calm
                                        {
                                            return 9;
                                        }              // Idle_Standing_Pistol			ACT_IDLE_PISTOL
                                        case false:    // not calm
                                        {
                                            return 30;
                                        }    // Idle_Standing_SMG				ACT_IDLE_SMG
                                    }
                                }
                            }
                        }
                        case 'e':
                        {
                            switch (iSequence)
                            {
                                case 30:    //	Idle_Standing_PumpShotgun		ACT_IDLE_PUMPSHOTGUN
                                {
                                    return 27;
                                }           // Idle_Standing_Shotgun				ACT_IDLE_SHOTGUN
                                case 27:    //	Idle_Standing_Shotgun			ACT_IDLE_SHOTGUN
                                {
                                    return iSequence;
                                }    // Shotgun anims look nice, don't replace
                                default:
                                {
                                    switch (isCalm)
                                    {
                                        case true:    // calm
                                        {
                                            return 22;
                                        }              // Idle_Standing_Elites			ACT_IDLE_ELITES
                                        case false:    // not calm
                                        {
                                            return 19;
                                        }    // Idle_Standing_Pistol			ACT_IDLE_PISTOL
                                    }
                                }
                            }
                        }
                        case 'a':
                        {
                            switch (iSequence)
                            {
                                case 27:    //	Idle_Standing_PumpShotgun		ACT_IDLE_PUMPSHOTGUN
                                {
                                    return 24;
                                }           // Idle_Standing_Shotgun				ACT_IDLE_SHOTGUN
                                case 24:    //	Idle_Standing_Shotgun			ACT_IDLE_SHOTGUN
                                {
                                    return iSequence;
                                }    // Shotgun anims look nice, don't replace
                                case false:
                                {
                                    switch (isCalm)
                                    {
                                        case true:    // calm
                                        {
                                            return 19;
                                        }              // Idle_Standing_Elites			ACT_IDLE_ELITES
                                        case false:    // not calm
                                        {
                                            return 16;
                                        }    // Idle_Standing_Pistol			ACT_IDLE_PISTOL
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    else    // is NOT on ground
    {
        switch (sModel[29])
        {
            case 'b':
            {
                return 593;
            }    // Jump_SMG_01			ACT_JUMP_SMG
            case 'd', 'w':
            {
                return 606;
            }    // Jump_DualPistols_01	ACT_JUMP_DUAL_PISTOL
            case 'c':
            {
                return 576;
            }    // Jump_Shotgun_01		ACT_JUMP_SHOTGUN
            case 'h':
            {
                return 580;
            }    // Jump_Shotgun_01		ACT_JUMP_SHOTGUN
            case 'v':
            {
                return 488;
            }    // Jump_Rifle_01			ACT_JUMP_RIFLE
            case 'n':
            {
                return 494;
            }    // Jump_Shotgun_01		ACT_JUMP_SHOTGUN
            case 'e':
            {
                return 509;
            }    // Jump_DualPistols_01	ACT_JUMP_DUAL_PISTOL
            case 'a':
            {
                return 506;
            }    // Jump_DualPistols_01	ACT_JUMP_DUAL_PISTOL
        }
    }
    return iSequence;
}

// Taken and modified from l4d_stocks.inc
stock float GetClientHealthBuffer(int client)
{
    static ConVar painPillsDecayCvar = null;
    if (painPillsDecayCvar == null)
    {
        painPillsDecayCvar = FindConVar("pain_pills_decay_rate");
        if (painPillsDecayCvar == null)
        {
            return 0.0;
        }
    }

    float tempHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * painPillsDecayCvar.FloatValue);
    return tempHealth < 0.0 ? 0.0 : tempHealth;
}
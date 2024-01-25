/*
 * @Author:             我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2023-06-27 15:49:57
 * @Last Modified time: 2023-07-14 23:12:16
 * @Github:             https://github.com/Paimon-Kawaii
 */

#include <sdktools>
#include <paiutils>
#include <sourcemod>
#include <left4dhooks>

#define VERSION "2023.06.27"
#define MAXSIZE MAXPLAYERS + 1

int
    g_iTankCar[MAXSIZE] = { -1, ... },
    g_iTankRock[MAXSIZE] = { -1, ... },
    g_iThrowTime[MAXSIZE] = { 0, ... };

ConVar
    g_hTCDistance;

public Plugin myinfo =
{
    name = "Throwable Cars",
    author = "我是派蒙啊",
    description = "扔车",
    version = VERSION,
    url = "http://github.com/Paimon-Kawaii/L4D2-Plugins"
}

public void OnPluginStart()
{
    HookEvent("ability_use", Event_AbilityUse);
    g_hTCDistance = CreateConVar("tc_dis", "200", "多少距离内的铁可以举起");
}

Action Event_AbilityUse(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(!IsTank(client)) return Plugin_Continue;
    char abilityName[64];
    event.GetString("ability", abilityName, sizeof(abilityName));
    if(strcmp(abilityName, "ability_throw", false) != 0)
        return Plugin_Continue;

    float eyePos[3];
    GetClientEyePosition(client, eyePos);
    int ent = GetClientAimTarget(client, false);
    if(!IsValidEdict(ent)) return Plugin_Continue;
    char entName[64];
    GetEntityClassname(ent, entName, sizeof(entName));
    if(strcmp(entName, "prop_physics") &&
        strcmp(entName, "prop_dynamic") &&
        strcmp(entName, "prop_car_alarm") &&
        strcmp(entName, "prop_physics_dynamic"))
        return Plugin_Continue;
    float carpos[3], tankpos[3];
    GetClientAbsOrigin(client, tankpos);
    GetEntPropVector(ent, Prop_Send, "m_vecOrigin", carpos);
    if(GetVectorDistance(carpos, tankpos, false) > g_hTCDistance.FloatValue)
    {
        PrintToChat(client, "铁离得有点远哦，再靠近一点试试叭~");
        return Plugin_Continue;
    }
    GetEntityName(ent, entName, sizeof(entName));
    g_iTankCar[client] = EntIndexToEntRef(ent);
    g_iThrowTime[client] = GetGameTickCount();
    PrintToChat(client, "拿到铁啦，看我把它举高高~");
    // PrintToChatAll("%N 的车：%s，tick: %d", client, entName, g_iThrowTime[client]);

    return Plugin_Continue;
}

public void OnEntityCreated(int entity)
{
    char name[64];
    int time = GetGameTickCount();
    GetEntityClassname(entity, name, sizeof(name));

    if(strcmp(name, "tank_rock") != 0) return;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsTank(i)) continue;
        int delta = time - g_iThrowTime[i];
        // PrintToChatAll("%N 的石头时间：%d, 差值：%d", i, time, delta);
        if(delta >= 80 && delta <= 105)
            if(!IsValidEntity(g_iTankRock[i]))
            {
                // PrintToChatAll("%N 的石头: %d, tick: %d", i, entity, time);
                g_iTankRock[i] = EntIndexToEntRef(entity);
                break;
            }
    }
}

public void OnGameFrame()
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsTank(i)) continue;
        int rock = EntRefToEntIndex(g_iTankRock[i]);
        int car = EntRefToEntIndex(g_iTankCar[i]);
        if(IsValidEntity(rock) && IsValidEntity(car))
        {
            char model[PLATFORM_MAX_PATH];
            GetEntPropString(car, Prop_Data, "m_ModelName", model, sizeof(model));
            SetEntityModel(rock, model);

            float pos[3], ang[3], vel[3];
            // SetEntityRenderColor(rock, 0, 0, 0, 0);
            // SetEntityRenderMode(rock, RENDER_TRANSCOLOR);
            // SetEntProp(rock, Prop_Send, "m_nSolidType", 0);
            SetEntProp(rock, Prop_Send, "m_CollisionGroup", 12);
            GetEntPropVector(rock, Prop_Send, "m_vecOrigin", pos);
            GetEntPropVector(rock, Prop_Send, "m_angRotation", ang);
            GetEntPropVector(rock, Prop_Send, "m_vecVelocity", vel);
            TeleportEntity(car, pos, ang, vel);
        }
    }
}

void GetEntityName(int entity, char[] name, int size)
{
    GetEntPropString(entity, Prop_Data, "m_iName", name, size);
}
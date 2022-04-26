/*
 * @Author:             派蒙
 * @Last Modified by:   派蒙
 * @Create Date:        2022-04-26 11:45:56
 * @Last Modified time: 2022-04-26 18:20:16
 * @Github:             http://github.com/PaimonQwQ
 */

#pragma semicolon 1
#pragma newdecls required

#include <colors>
#include <dynamic>
#include <sdktools>
#include <l4d2tools>
#include <sourcemod>
#include <left4dhooks>
#include <angel/training>

#define VERSION "2022.04.26"
#define NEQNULL(%1) Dynamic_IsValid(view_as<int>(%1))

public Plugin myinfo =
{
    name = "AngelTraining",
    author = "我是派蒙啊",
    description = "AngelServer的训练模式",
    version = VERSION,
    url = "http://github.com/PaimonQwQ/L4D2-Plugins/AngelBeats"
};

Training
    g_oAngelTraining;

//插件入口
public void OnPluginStart()
{
    if(!NEQNULL(g_oAngelTraining))
        g_oAngelTraining = Training();

    g_oAngelTraining.TrainConVar = CreateConVar("angel_training", "0", "Angel训练模式");
    g_oAngelTraining.HealthConVar = CreateConVar("angel_reheal", "0", "Angel回血开关");
    g_oAngelTraining.RefillConVar = CreateConVar("angel_autorefill", "0", "开关自动装填");

    HookEvent("player_death", Event_PlayerDead);
    HookEvent("weapon_fire", Event_WeaponFire);

    if(NEQNULL(g_oAngelTraining))
        g_oAngelTraining.Init();
}

//在插件加载完毕后
public void OnAllPluginsLoaded()
{
    for (int i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i))
            SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
}

//玩家加载完毕(检查是否为管理员是在完成载入后)
public void OnClientPostAdminCheck(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

//玩家进入服务器后
public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    g_oAngelTraining.SaveMsgArray.Set(client, false);
    g_oAngelTraining.SelfSaveArray.Set(client,
         g_oAngelTraining.SICountLimit - (GetSurvivorCount() <= 2 ? 1 : 3));
}

//玩家断开连接
public void OnClientDisconnect(int client)
{
    g_oAngelTraining.SaveMsgArray.Set(client, false);
    g_oAngelTraining.SelfSaveArray.Set(client,
         g_oAngelTraining.SICountLimit - (GetSurvivorCount() <= 2 ? 1 : 3));
}

//单人解控
public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
    if (!IsSurvivor(victim) || !IsInfected(attacker) ||
         IsTank(attacker) || GetSurvivorCount() > 3 ||
         !IsSurvivorPinned(victim) || !IsPinningASurvivor(attacker))
        return Plugin_Continue;

    if (GetSurvivorCount() > 1)
    {
        if(!(g_oAngelTraining.SelfSaveArray.Get(victim) > 0 &&
            !g_oAngelTraining.SaveMsgArray.Get(victim)))
            return Plugin_Continue;
        g_oAngelTraining.SaveMsgArray.Set(victim, true);
        PrintHintText(victim, "使用 E(交互)键 解控！");
        CreateTimer(1.0, Timer_ResetSaveMsg, victim, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        return Plugin_Continue;
    }

    if (!g_oAngelTraining.TrainConVar.BoolValue)
        damage = 10.0;
    else
        damage = 2.0;
    int remain = GetClientHealth(attacker);
    SDKHooks_TakeDamage(victim, attacker, attacker, damage);

    ForcePlayerSuicide(attacker);
    CreateTimer(0.1, Timer_CancelGetup, victim, TIMER_FLAG_NO_MAPCHANGE);
    CPrintToChat(victim, "[{olive}SSS团{default}] {red}%N{default} 还有 {olive}%d{default} 血!", attacker, remain);
    return Plugin_Handled;
}

//玩家解控
public Action OnPlayerRunCmd(int client, int &buttons, int &impuls)
{
    //当生还存活并且未倒地，且仍被特感控制时，使用交互键并还有剩余解控次数，生还数量在2-3人时，判断是否可解控
    if (IsSurvivor(client) && IsPlayerAlive(client) && IsSurvivorPinned(client) &&
        !IsPlayerIncap(client) && (buttons & IN_USE) && GetSurvivorCount() < 4 &&
         GetSurvivorCount() > 1 && g_oAngelTraining.SelfSaveArray.Get(client) > 0)
    {
        int attacker = GetSurvivorPinner(client);
        //如果攻击者是特感，并且特感存活且仍在控制生还，若已展示解控提示，则进行解控
        if (IsInfected(attacker) && IsPlayerAlive(attacker) &&
         IsPinningASurvivor(attacker) && g_oAngelTraining.SelfSaveArray.Get(client))
        {
            int remain = GetClientHealth(attacker);
            g_oAngelTraining.SaveMsgArray.Set(client, false);
            g_oAngelTraining.SelfSaveArray.Set(client, g_oAngelTraining.SelfSaveArray.Get(client) - 1);

            SDKHooks_TakeDamage(client, attacker, attacker, 1.0);

            ForcePlayerSuicide(attacker);
            CreateTimer(0.1, Timer_CancelGetup, client, TIMER_FLAG_NO_MAPCHANGE);

            CPrintToChat(client, "[{olive}SSS团{default}] {default}剩余解控次数：{red}%d",
                g_oAngelTraining.SaveMsgArray.Get(client));
            CPrintToChat(client, "[{olive}SSS团{default}] {red}%N{default} 还有 {olive}%d{default} 血!", attacker, remain);
        }
    }

    return Plugin_Continue;
}

//玩家离开安全屋
public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
    CreateTimer(0.2, Timer_ResetStats, 0, TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Continue;
}

//特感死亡事件
public Action Event_PlayerDead(Event event, const char[] name, bool dont_broadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    if (g_oAngelTraining.HealthConVar.BoolValue && IsInfected(victim) &&
        !IsTank(victim) && IsSurvivor(attacker))
    {
        int heal = 0;
        int zclass = GetInfectedClass(victim);
        switch (zclass)
        {
            case 1:
            {
                heal += 3;
            }
            case 3:
            {
                heal += 4;
            }
            case 5:
            {
                heal += 3;
            }
            case 6:
            {
                heal += 6;
            }
        }
        float tmpheal = L4D_GetTempHealth(attacker);
        L4D_SetTempHealth(attacker,  tmpheal + heal > 200 ? tmpheal : tmpheal + heal);
    }

    return Plugin_Continue;
}

//自动装填
public Action Event_WeaponFire(Event event, const char[] name, bool dont_broadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(!IsSurvivor(client) || IsFakeClient(client) ||
        !IsPlayerAlive(client) || !g_oAngelTraining.RefillConVar.BoolValue)
        return Plugin_Continue;
    if(IsSurvivor(client) && !FindConVar("sv_infinite_ammo").BoolValue)
    {
        int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        int clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
        int ammo = g_oAngelTraining.GetOrSetPlayerAmmo(client, weapon);
        if(ammo)
        {
            SetEntProp(weapon, Prop_Send, "m_iClip1", clip + 1);
            g_oAngelTraining.GetOrSetPlayerAmmo(client, weapon, ammo - 1);
        }
    }
    return Plugin_Continue;
}

//取消生还起身延迟
public Action Timer_CancelGetup(Handle timer, any client)
{
    if (IsValidClient(client))
        SetEntPropFloat(client, Prop_Send, "m_flCycle", 1.0);
    return Plugin_Continue;
}

//清除玩家起身标签
public Action Timer_ResetSaveMsg(Handle timer, any client)
{
    if ((IsSurvivor(client) && !IsSurvivorPinned(client)) ||
        !IsSurvivor(client) || !IsPlayerAlive(client))
    {
        g_oAngelTraining.SaveMsgArray.Set(client, false);
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

//重置玩家解控次数
public Action Timer_ResetStats(Handle timer)
{
    for (int i = 1; i < MaxClients; i++)
    {
        g_oAngelTraining.SaveMsgArray.Set(i, false);
        g_oAngelTraining.SelfSaveArray.Set(i, g_oAngelTraining.SICountLimit -
            (GetSurvivorCount() <= 2 ? 1 : 3));
    }
}
